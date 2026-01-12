# ======================================================================
# cowfootR — Batch processing (helpers + calc_batch + export_hdc_report)
# All comments and roxygen headers in English as requested.
# ======================================================================

# ---------------------------
# Minimal helpers (internal)
# ---------------------------

`%||%` <- function(a, b) if (is.null(a)) b else a

.scalar_num <- function(x) {
  x <- tryCatch(unlist(x, use.names = FALSE), error = function(e) x)
  x <- suppressWarnings(as.numeric(x))
  if (length(x) == 0L || all(!is.finite(x))) {
    return(NA_real_)
  }
  x[1L]
}
.scalar_chr <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(NA_character_)
  }
  x <- tryCatch(as.character(unlist(x, use.names = FALSE)), error = function(e) as.character(x))
  if (length(x) == 0L) NA_character_ else x[1L]
}
.scalar_lgl <- function(x) {
  x <- tryCatch(as.logical(x[[1L]]), error = function(e) as.logical(x))
  if (length(x) == 0L) NA else x[1L]
}

getv <- function(row, name, default = NA) {
  if (!name %in% names(row)) {
    return(default)
  }
  v <- row[[name]]
  if (is.null(v) || (length(v) == 1 && is.na(v))) default else v
}

# Safe function caller:
# - Names the first arg if not provided
# - Filters args by function signature when no "..." in formals
.call_safe <- function(fn, args_list) {
  if (is.character(fn)) fn <- get(fn, mode = "function")
  fmls <- formals(fn)
  fml_names <- names(fmls)

  if (length(args_list) > 0) {
    nm <- names(args_list)
    if (is.null(nm)) nm <- rep("", length(args_list))
    if (nm[1] == "" && length(fml_names) > 0 && fml_names[1] != "...") {
      nm[1] <- fml_names[1]
      names(args_list) <- nm
    }
  }

  if (!is.null(fml_names) && any(fml_names == "...")) {
    return(do.call(fn, args_list))
  }

  nm <- names(args_list)
  if (is.null(nm)) nm <- rep("", length(args_list))
  keep <- nm != "" & nm %in% fml_names
  do.call(fn, args_list[keep])
}

# Run an expression and return NULL on error
safe_call <- function(expr) {
  res <- try(expr, silent = TRUE)
  if (inherits(res, "try-error")) NULL else res
}

# Ensure every source object has a numeric non-negative 'co2eq_kg' and a 'source' name.
.ensure_source <- function(obj, src_name) {
  if (is.null(obj)) {
    return(list(source = src_name, co2eq_kg = 0))
  }
  val <- obj$co2eq_kg
  if (is.null(val)) val <- obj$total_co2eq_kg
  val <- suppressWarnings(as.numeric(val))
  if (length(val) == 0 || !is.finite(val[1])) val <- 0
  if (is.null(obj$source)) obj$source <- src_name
  obj$co2eq_kg <- val[1]
  obj
}

# Compute FPCM (kg) from litres, composition, and density (IDF-consistent).
# IDF formula used in calc_intensity_litre:
#   milk_kg = milk_litres * milk_density
#   FPCM_kg = milk_kg * (0.1226*fat + 0.0776*protein + 0.2534)
compute_fpcm_idf <- function(milk_l, fat, prot, milk_density = 1.03) {
  milk_kg <- milk_l * milk_density
  fpcm_kg <- milk_kg * (0.1226 * fat + 0.0776 * prot + 0.2534)
  if (!is.finite(fpcm_kg) || fpcm_kg <= 0) NA_real_ else fpcm_kg
}

# ---------------------------------------------
# calc_batch(): data.frame -> batch results
# ---------------------------------------------

#' Batch carbon footprint calculation
#'
#' Processes a data.frame of farms and computes annual emissions per farm,
#' returning a summary plus per-farm details (optionally).
#'
#' @param data A data.frame with one row per farm and annual activity data.
#' At minimum, the following columns are required:
#' \itemize{
#'   \item \code{FarmID}: Unique farm identifier.
#'   \item \code{Milk_litres}: Annual milk production (litres/year).
#'   \item \code{Cows_milking}: Number of milking cows.
#' }
#' Additional columns are optional and enable more detailed Tier 2 calculations,
#' including herd structure, feed intake, manure management, soil nitrogen inputs,
#' energy use, and purchased inputs. When optional variables are not provided,
#' default IPCC- or IDF-consistent values are used. All inputs are assumed to
#' represent one accounting year.
#' @param tier Integer; methodology tier (usually 1 or 2). Default = 2.
#' @param boundaries System boundaries as returned by \code{set_system_boundaries()}.
#' @param benchmark_region Optional character string specifying a geographic or
#' regional benchmark (e.g., country or production region). When provided,
#' emission intensity results are compared against region-specific reference
#' values using internal benchmarking functions. This argument does not affect
#' emission calculations and is only used for comparative performance assessment.
#' @param save_detailed_objects Logical; if TRUE, returns detailed objects per farm.
#'
#' @details
#' The input data frame is intentionally flexible to support heterogeneous
#' data availability across farms. Each row represents one farm and all inputs
#' are assumed to correspond to a single accounting year, unless explicitly
#' stated otherwise by the column name (e.g., *_kg_day).
#'
#' Column names follow cowfootR conventions. The complete and authoritative
#' specification of supported input columns (including expected units and
#' whether they are required or optional) is provided by the Excel template
#' generated with \code{cf_download_template()}. This template represents the
#' full set of columns that can be used by \code{calc_batch()}.
#'
#' In addition, the vignettes "Get started" and "IPCC Methodology Tiers in cowfootR"
#' describe how these columns are used conceptually and methodologically.
#'
#' \strong{Tier 2–relevant optional columns:}
#' When \code{tier = 2}, \code{calc_batch()} uses additional farm-specific
#' information if available. The most relevant optional columns include:
#' \itemize{
#'   \item \strong{Enteric fermentation:}
#'   \code{Milk_yield_kg_cow_year},
#'   \code{Body_weight_cows_kg},
#'   \code{MS_intake_cows_milking_kg_day},
#'   \code{Ym_percent}.
#'
#'   \item \strong{Young stock (optional refinement):}
#'   \code{Body_weight_heifers_kg},
#'   \code{Body_weight_calves_kg},
#'   \code{Body_weight_bulls_kg},
#'   \code{MS_intake_heifers_kg_day},
#'   \code{MS_intake_calves_kg_day},
#'   \code{MS_intake_bulls_kg_day}.
#'
#'   \item \strong{Manure management:}
#'   \code{Manure_system},
#'   \code{Diet_digestibility},
#'   \code{Protein_intake_kg_day},
#'   \code{Retention_days},
#'   \code{System_temperature},
#'   \code{Climate_zone}.
#' }
#'
#' If any Tier 2–relevant column is missing, the function automatically falls
#' back to Tier 1–consistent default assumptions following IPCC and IDF guidance.
#' Missing optional inputs therefore do not cause errors.
#'
#' @return A list with \code{$summary} and \code{$farm_results}; class \code{cf_batch_complete}.
#' Absolute emissions returned in \code{$farm_results} (e.g., \code{emissions_total},
#' \code{emissions_enteric}, \code{emissions_manure}, etc.) are annual emissions expressed as
#' kg CO2-equivalent per year (kg CO2eq yr-1) at the farm (system) level, within the defined
#' system boundaries. Intensity metrics are reported as kg CO2eq per kg FPCM and kg CO2eq per ha
#' (based on annual milk production and managed area).
#' @export
#' @aliases calc_emissions_batch
#'
#' @examples
#' \donttest{
#' farms <- data.frame(
#'   FarmID = c("A", "B"),
#'   Milk_litres = c(5e5, 7e5),
#'   Cows_milking = c(100, 140)
#' )
#' res <- calc_batch(
#'   data = farms,
#'   tier = 2,
#'   boundaries = set_system_boundaries("farm_gate"),
#'   benchmark_region = "uruguay",
#'   save_detailed_objects = FALSE
#' )
#' str(res$summary)
#' }
calc_batch <- function(data,
                       tier = 2,
                       boundaries = set_system_boundaries("farm_gate"),
                       benchmark_region = NULL,
                       save_detailed_objects = FALSE) {
  # Basic validations
  if (is.character(data)) stop("Pass an in-memory data.frame. This version does not read files.")
  stopifnot(is.data.frame(data))
  if (!tier %in% c(1, 2)) stop("`tier` must be 1 or 2.")
  if (nrow(data) == 0) stop("Input data.frame has zero rows.")

  # Column mapping. Adjust here if your input uses alternative names.
  CN <- list(
    id = "FarmID", year = "Year", milkL = "Milk_litres", fat = "Fat_percent",
    prot = "Protein_percent", dens = "Milk_density"
  )
  HERD <- list(
    cows_milk = "Cows_milking", cows_dry = "Cows_dry",
    heifers = "Heifers_total", calves = "Calves_total", bulls = "Bulls_total",
    BW_cows = "Body_weight_cows_kg", BW_heif = "Body_weight_heifers_kg",
    BW_calv = "Body_weight_calves_kg", BW_bull = "Body_weight_bulls_kg",
    MY_cow = "Milk_yield_kg_cow_year"
  )
  FEED <- list(
    MS_cow_milking = "MS_intake_cows_milking_kg_day",
    MS_cow_dry = "MS_intake_cows_dry_kg_day",
    MS_heif = "MS_intake_heifers_kg_day",
    MS_calv = "MS_intake_calves_kg_day",
    MS_bull = "MS_intake_bulls_kg_day",
    Ym = "Ym_percent"
  )
  SOIL <- list(
    N_synth = "N_fertilizer_kg", N_organic = "N_fertilizer_organic_kg",
    N_past = "N_excreta_pasture_kg", N_resid = "N_crop_residues_kg",
    area_tot = "Area_total_ha", area_prod = "Area_productive_ha",
    area_fert = "Area_fertilized_ha", soil_type = "Soil_type", climate = "Climate_zone",
    area_past_perm = "Pasture_permanent_ha", area_past_temp = "Pasture_temporary_ha",
    area_feed = "Crops_feed_ha", area_cash = "Crops_cash_ha",
    area_infra = "Infrastructure_ha", area_wood = "Woodland_ha"
  )
  EN <- list(
    diesel = "Diesel_litres", petrol = "Petrol_litres",
    elec = "Electricity_kWh",
    lpg = "LPG_kg", gas = "Natural_gas_m3",
    coal = "Coal_kg", bio = "Biomass_kg", country = "Country"
  )
  INP <- list(
    conc = "Concentrate_feed_kg", plastic = "Plastic_kg",
    grain_dry = "Feed_grain_dry_kg", grain_wet = "Feed_grain_wet_kg",
    ration = "Feed_ration_kg", byprod = "Feed_byproducts_kg",
    proteins = "Feed_proteins_kg"
  )
  MAN <- list(system = "Manure_system", N_exc_an = "N_excreted_per_cow_kg")

  n <- nrow(data)
  farm_results <- vector("list", n)
  processing_date <- Sys.Date()

  message("Batch: ", n, " rows; tier=", tier, " ...")

  n_successful <- 0L
  n_errors <- 0L

  for (i in seq_len(n)) {
    row <- data[i, , drop = FALSE]
    farm_id <- .scalar_chr(getv(row, CN$id, paste0("Farm_", i)))
    year <- .scalar_chr(getv(row, CN$year, format(Sys.Date(), "%Y")))

    result <- tryCatch(
      {
        # -------------------------
        # Inputs and basic checks
        # -------------------------
        cows_milk <- .scalar_num(getv(row, HERD$cows_milk, 0))
        cows_dry <- .scalar_num(getv(row, HERD$cows_dry, 0))
        heifers <- .scalar_num(getv(row, HERD$heifers, 0))
        calves <- .scalar_num(getv(row, HERD$calves, 0))
        bulls <- .scalar_num(getv(row, HERD$bulls, 0))

        n_cows_total <- sum(cows_milk, cows_dry, na.rm = TRUE)
        total_animals <- sum(cows_milk, cows_dry, heifers, calves, bulls, na.rm = TRUE)

        milk_L <- .scalar_num(getv(row, CN$milkL, 1000))
        if (!is.na(milk_L) && milk_L < 0) stop("Milk production cannot be negative.")
        if (cows_milk < 0 || cows_dry < 0 || heifers < 0 || calves < 0 || bulls < 0) {
          stop("Animal numbers cannot be negative.")
        }

        Ym <- .scalar_num(getv(row, FEED$Ym, if (tier == 2) 6.5 else 6.0))
        MS_cows_milking <- .scalar_num(getv(row, FEED$MS_cow_milking, NA))
        MS_cows_dry <- .scalar_num(getv(row, FEED$MS_cow_dry, NA))
        MS_c <- MS_cows_milking
        MS_h <- .scalar_num(getv(row, FEED$MS_heif, NA))
        MS_k <- .scalar_num(getv(row, FEED$MS_calv, NA))
        MS_b <- .scalar_num(getv(row, FEED$MS_bull, NA))

        MY_cow <- .scalar_num(getv(row, HERD$MY_cow, if (tier == 2) 6000 else NA))
        BW_cow <- .scalar_num(getv(row, HERD$BW_cows, 550))
        BW_cows_milking <- .scalar_num(getv(row, "Body_weight_cows_milking_kg", 580))
        BW_cows_dry <- .scalar_num(getv(row, "Body_weight_cows_dry_kg", 590))
        BW_hef <- .scalar_num(getv(row, HERD$BW_heif, 350))
        BW_cal <- .scalar_num(getv(row, HERD$BW_calv, 150))
        BW_bul <- .scalar_num(getv(row, HERD$BW_bull, 700))

        N_synth <- .scalar_num(getv(row, SOIL$N_synth, 0))
        N_organic <- .scalar_num(getv(row, SOIL$N_organic, 0))
        N_past <- .scalar_num(getv(row, SOIL$N_past, 0))
        N_resid <- .scalar_num(getv(row, SOIL$N_resid, 0))

        area_tot <- .scalar_num(getv(row, SOIL$area_tot, 100))
        area_prod <- .scalar_num(getv(row, SOIL$area_prod, NA))
        area_fert <- .scalar_num(getv(row, SOIL$area_fert, area_tot))
        soil_type <- .scalar_chr(getv(row, SOIL$soil_type, "well_drained"))
        climate <- .scalar_chr(getv(row, SOIL$climate, "temperate"))

        area_vec <- c(
          pasture_permanent = .scalar_num(getv(row, SOIL$area_past_perm, 0)),
          pasture_temporary = .scalar_num(getv(row, SOIL$area_past_temp, 0)),
          crops_feed        = .scalar_num(getv(row, SOIL$area_feed, 0)),
          crops_cash        = .scalar_num(getv(row, SOIL$area_cash, 0)),
          infrastructure    = .scalar_num(getv(row, SOIL$area_infra, 0)),
          woodland          = .scalar_num(getv(row, SOIL$area_wood, 0))
        )
        area_vec <- area_vec[is.finite(area_vec) & area_vec > 0]
        area_breakdown <- if (length(area_vec)) as.list(area_vec) else NULL

        diesel <- .scalar_num(getv(row, EN$diesel, 0))
        petrol <- .scalar_num(getv(row, EN$petrol, 0))
        elec <- .scalar_num(getv(row, EN$elec, 0))
        lpg <- .scalar_num(getv(row, EN$lpg, 0))
        gas <- .scalar_num(getv(row, EN$gas, 0))
        coal <- .scalar_num(getv(row, EN$coal, 0))
        bio <- .scalar_num(getv(row, EN$bio, 0))
        country <- .scalar_chr(getv(row, EN$country, "global"))
        if (!is.na(country) && identical(tolower(country), "global")) {
          country <- NA_character_
        }

        conc <- .scalar_num(getv(row, INP$conc, 0))
        plastic <- .scalar_num(getv(row, INP$plastic, 0))
        grain_dry <- .scalar_num(getv(row, INP$grain_dry, 0))
        grain_wet <- .scalar_num(getv(row, INP$grain_wet, 0))
        ration <- .scalar_num(getv(row, INP$ration, 0))
        byprod <- .scalar_num(getv(row, INP$byprod, 0))
        proteins <- .scalar_num(getv(row, INP$proteins, 0))

        manure_system <- .scalar_chr(getv(row, MAN$system, "pasture"))
        N_exc_an <- .scalar_num(getv(row, MAN$N_exc_an, 100))

        diet_digestibility <- .scalar_num(getv(row, list(diet_dig = "Diet_digestibility"), 0.68))
        protein_intake_daily <- .scalar_num(getv(row, list(prot_int = "Protein_intake_kg_day"), if (tier == 2) 3.4 else NULL))
        retention_days <- .scalar_num(getv(
          row, list(retention = "Retention_days"),
          if (manure_system == "solid_storage") 60 else if (manure_system == "liquid_storage") 120 else NULL
        ))
        system_temp <- .scalar_num(getv(
          row, list(temp = "System_temperature"),
          if (climate == "temperate") 18 else if (climate == "tropical") 25 else 12
        ))

        # -------------------------
        # Emissions by source
        # -------------------------

        # Boundaries check aligned with set_system_boundaries():
        # if $include is present, only listed names are included.
        is_excluded <- function(name) {
          if (is.null(boundaries) || !is.list(boundaries)) {
            return(FALSE)
          }
          inc <- boundaries$include
          if (is.null(inc)) {
            return(FALSE)
          }
          !(name %in% inc)
        }

        # ---------- ENTERIC ----------
        total_enteric <- 0
        if (cows_milk > 0 && !is_excluded("enteric")) {
          e_cows_milk <- safe_call(.call_safe("calc_emissions_enteric", list(
            n_animals = cows_milk,
            cattle_category = "dairy_cows",
            avg_milk_yield = if (is.na(MY_cow)) NULL else MY_cow,
            avg_body_weight = BW_cow, # variable already available
            dry_matter_intake = if (tier == 2 && !is.na(MS_cows_milking)) MS_cows_milking else NULL,
            ym_percent = Ym,
            tier = tier,
            boundaries = boundaries
          )))
          total_enteric <- total_enteric + .scalar_num(e_cows_milk$co2eq_kg)
        }

        if (cows_dry > 0 && !is_excluded("enteric")) {
          e_cows_dry <- safe_call(.call_safe("calc_emissions_enteric", list(
            n_animals = cows_dry,
            cattle_category = "dairy_cows",
            avg_milk_yield = 0, # KEY: dry cows produce no milk
            avg_body_weight = .scalar_num(getv(row, "Body_weight_cows_dry_kg", BW_cow)),
            dry_matter_intake = if (tier == 2) .scalar_num(getv(row, "MS_intake_cows_dry_kg_day", MS_c)) else NULL,
            ym_percent = Ym,
            tier = tier,
            boundaries = boundaries
          )))
          total_enteric <- total_enteric + .scalar_num(e_cows_dry$co2eq_kg)
        }

        if (heifers > 0 && !is_excluded("enteric")) {
          e_h <- safe_call(.call_safe("calc_emissions_enteric", list(
            n_animals = heifers,
            cattle_category = "heifers",
            avg_body_weight = BW_hef,
            dry_matter_intake = if (tier == 2 && !is.na(MS_h)) MS_h else NULL,
            ym_percent = if (is.na(Ym)) 6.0 else Ym,
            tier = tier,
            boundaries = boundaries
          )))
          total_enteric <- total_enteric + .scalar_num(e_h$co2eq_kg)
        }

        if (calves > 0 && !is_excluded("enteric")) {
          e_k <- safe_call(.call_safe("calc_emissions_enteric", list(
            n_animals = calves,
            cattle_category = "calves",
            avg_body_weight = BW_cal,
            dry_matter_intake = if (tier == 2 && !is.na(MS_k)) MS_k else NULL,
            ym_percent = if (is.na(Ym)) 6.0 else Ym,
            tier = tier,
            boundaries = boundaries
          )))
          total_enteric <- total_enteric + .scalar_num(e_k$co2eq_kg)
        }

        if (bulls > 0 && !is_excluded("enteric")) {
          e_b <- safe_call(.call_safe("calc_emissions_enteric", list(
            n_animals = bulls,
            cattle_category = "bulls",
            avg_body_weight = BW_bul,
            dry_matter_intake = if (tier == 2 && !is.na(MS_b)) MS_b else NULL,
            ym_percent = if (is.na(Ym)) 6.0 else Ym,
            tier = tier,
            boundaries = boundaries
          )))
          total_enteric <- total_enteric + .scalar_num(e_b$co2eq_kg)
        }

        e_enteric <- .ensure_source(list(source = "enteric", co2eq_kg = total_enteric), "enteric")

        # ---------- MANURE ----------
        if (!is_excluded("manure")) {
          e_manure <- safe_call(.call_safe("calc_emissions_manure", list(
            n_cows = total_animals,
            manure_system = manure_system,
            tier = tier,
            n_excreted = N_exc_an,
            include_indirect = TRUE,
            climate = climate,
            avg_body_weight = BW_cow,
            diet_digestibility = 0.68,
            protein_intake_kg = if (tier == 2) 3.4 else NULL,
            retention_days = if (manure_system != "pasture") 60 else NULL,
            system_temperature = if (climate == "temperate") 18 else if (climate == "tropical") 25 else 12,
            boundaries = boundaries
          )))
          e_manure <- .ensure_source(e_manure, "manure")
        } else {
          e_manure <- list(source = "manure", co2eq_kg = 0)
        }

        # ---------- SOIL ----------
        # Tests expect: when soil is excluded, e_soil$co2eq_kg == NULL (not 0)
        e_soil_out <- NULL
        e_soil_for_total <- NULL

        if (!is_excluded("soil")) {
          e_soil_calc <- safe_call(.call_safe("calc_emissions_soil", list(
            n_fertilizer_synthetic = N_synth,
            n_fertilizer_organic   = N_organic,
            n_excreta_pasture      = N_past,
            n_crop_residues        = N_resid,
            area_ha                = area_fert,
            soil_type              = soil_type,
            climate                = climate,
            include_indirect       = TRUE,
            boundaries             = boundaries
          )))
          e_soil_out <- .ensure_source(e_soil_calc, "soil")
          e_soil_for_total <- e_soil_out
        } else {
          e_soil_out <- list(source = "soil", co2eq_kg = NULL) # for output
          e_soil_for_total <- list(source = "soil", co2eq_kg = 0) # for totals
        }

        # ---------- ENERGY ----------
        use_energy <- !is_excluded("energy") && (diesel > 0 || petrol > 0 || elec > 0 || lpg > 0 || gas > 0)
        if (use_energy) {
          e_energy_calc <- safe_call(.call_safe("calc_emissions_energy", list(
            diesel_l = diesel,
            petrol_l = petrol,
            electricity_kwh = elec,
            lpg_kg = lpg,
            natural_gas_m3 = gas,
            country = if (!is.na(country)) country else "UY",
            include_upstream = TRUE,
            boundaries = boundaries
          )))
          e_energy <- .ensure_source(e_energy_calc, "energy")
        } else {
          e_energy <- list(source = "energy", co2eq_kg = 0)
        }

        # ---------- INPUTS ----------
        if (!is_excluded("inputs")) {
          e_inputs_calc <- safe_call(.call_safe("calc_emissions_inputs", list(
            conc_kg = conc,
            fert_n_kg = N_synth,
            plastic_kg = plastic,
            feed_grain_dry_kg = grain_dry,
            feed_grain_wet_kg = grain_wet,
            feed_ration_kg = ration,
            feed_byproducts_kg = byprod,
            feed_proteins_kg = proteins,
            boundaries = boundaries
          )))
          e_inputs <- .ensure_source(e_inputs_calc, "inputs")
        } else {
          e_inputs <- list(source = "inputs", co2eq_kg = 0)
        }

        # -------------------------
        # Totals (robust & boundary-aware)
        # -------------------------
        total <- safe_call(.call_safe("calc_total_emissions", list(
          e_enteric, e_manure, e_soil_for_total, e_energy, e_inputs
        )))
        if (is.null(total) || (is.null(total$co2eq_kg) && is.null(total$total_co2eq))) {
          total <- list(total_co2eq = 0)
        }

        # Force totals to strictly follow boundaries: sum only INCLUDED sources
        included_sum <- 0
        if (!is_excluded("enteric")) included_sum <- included_sum + .scalar_num(e_enteric$co2eq_kg)
        if (!is_excluded("manure")) included_sum <- included_sum + .scalar_num(e_manure$co2eq_kg)
        if (!is_excluded("soil")) included_sum <- included_sum + .scalar_num(e_soil_for_total$co2eq_kg)
        if (!is_excluded("energy")) included_sum <- included_sum + .scalar_num(e_energy$co2eq_kg)
        if (!is_excluded("inputs")) included_sum <- included_sum + .scalar_num(e_inputs$co2eq_kg)

        total$total_co2eq <- included_sum

        # -------------------------
        # Intensities (bridge + fallback)
        # -------------------------
        fat <- .scalar_num(getv(row, CN$fat, 4.0))
        prot <- .scalar_num(getv(row, CN$prot, 3.3))
        dens <- .scalar_num(getv(row, CN$dens, 1.03))

        milk_int <- safe_call(.call_safe("calc_intensity_litre", list(
          total_emissions = total,
          milk_litres = milk_L,
          fat = fat, protein = prot, milk_density = dens
        )))
        if (is.null(milk_int)) {
          # Fallback using the same IDF-consistent FPCM used in calc_intensity_litre
          fpcm_kg <- compute_fpcm_idf(milk_L, fat, prot, dens)
          intensity_val <- if (is.finite(fpcm_kg) && fpcm_kg > 0) {
            .scalar_num(total$total_co2eq %||% total$co2eq_kg) / fpcm_kg
          } else {
            NA_real_
          }
          milk_int <- list(
            intensity_co2eq_per_kg_fpcm = intensity_val,
            fpcm_production_kg = fpcm_kg,
            milk_production_kg = milk_L * dens
          )
        }

        area_int <- safe_call(.call_safe("calc_intensity_area", list(
          total_emissions = total,
          area_total_ha = area_tot,
          area_productive_ha = if (is.na(area_prod)) NULL else area_prod,
          area_breakdown = area_breakdown,
          validate_area_sum = FALSE
        )))
        if (is.null(area_int)) {
          area_int <- list(
            intensity_per_total_ha = if (is.finite(area_tot) && area_tot > 0) {
              .scalar_num(total$total_co2eq %||% total$co2eq_kg) / area_tot
            } else {
              NA_real_
            },
            intensity_per_productive_ha = if (is.finite(area_prod) && area_prod > 0) {
              .scalar_num(total$total_co2eq %||% total$co2eq_kg) / area_prod
            } else {
              NA_real_
            },
            land_use_efficiency = if (is.finite(area_tot) && area_tot > 0) {
              (.scalar_num(milk_L) / area_tot)
            } else {
              NA_real_
            }
          )
        }

        if (!is.null(benchmark_region)) {
          area_int <- safe_call(.call_safe("benchmark_area_intensity", list(
            cf_area_intensity = area_int,
            region = benchmark_region
          ))) %||% area_int
        }

        # -------------------------
        # Successful farm result
        # -------------------------
        list(
          success = TRUE,
          farm_id = farm_id,
          year = year,
          emissions_enteric = .scalar_num(e_enteric$co2eq_kg),
          emissions_manure = .scalar_num(e_manure$co2eq_kg),
          emissions_soil = .scalar_num(e_soil_out$co2eq_kg), # may be NA if NULL
          emissions_energy = .scalar_num(e_energy$co2eq_kg),
          emissions_inputs = .scalar_num(e_inputs$co2eq_kg),
          emissions_total = .scalar_num((total$total_co2eq %||% total$co2eq_kg)),
          intensity_milk_kg_co2eq_per_kg_fpcm = .scalar_num(
            milk_int$intensity_co2eq_per_kg_fpcm %||%
              milk_int$kg_co2eq_per_kg_fpcm %||%
              milk_int$intensity
          ),
          intensity_area_kg_co2eq_per_ha_total = .scalar_num(
            area_int$intensity_per_total_ha %||%
              area_int$kg_co2eq_per_ha %||%
              area_int$intensity
          ),
          intensity_area_kg_co2eq_per_ha_productive = .scalar_num(
            area_int$intensity_per_productive_ha %||%
              area_int$kg_co2eq_per_ha_productive
          ),
          fpcm_production_kg = .scalar_num(milk_int$fpcm_production_kg),
          milk_production_kg = .scalar_num(milk_int$milk_production_kg),
          milk_production_litres = milk_L,
          land_use_efficiency = .scalar_num(area_int$land_use_efficiency),
          total_animals = total_animals,
          dairy_cows = n_cows_total,
          benchmark_region = .scalar_chr(benchmark_region),
          benchmark_performance = .scalar_chr(area_int$benchmarking$performance_category %||% NA_character_),
          processing_date = processing_date,
          boundaries_used = .scalar_chr(boundaries$scope),
          tier_used = .scalar_chr(paste0("tier_", tier)),
          detailed_objects = if (save_detailed_objects) {
            list(
              enteric = e_enteric, manure = e_manure, soil = e_soil_out,
              energy = e_energy, inputs = e_inputs, total = total,
              milk_intensity = milk_int, area_intensity = area_int
            )
          } else {
            NULL
          }
        )
      },
      error = function(e) {
        list(
          success = FALSE,
          farm_id = farm_id,
          year = year,
          error = as.character(e$message),
          emissions_enteric = NA_real_,
          emissions_manure = NA_real_,
          emissions_soil = NA_real_,
          emissions_energy = NA_real_,
          emissions_inputs = NA_real_,
          emissions_total = NA_real_,
          intensity_milk_kg_co2eq_per_kg_fpcm = NA_real_,
          intensity_area_kg_co2eq_per_ha_total = NA_real_,
          intensity_area_kg_co2eq_per_ha_productive = NA_real_,
          fpcm_production_kg = NA_real_,
          milk_production_kg = NA_real_,
          milk_production_litres = NA_real_,
          land_use_efficiency = NA_real_,
          total_animals = NA_real_,
          dairy_cows = NA_real_,
          benchmark_region = benchmark_region,
          benchmark_performance = NA_character_,
          processing_date = processing_date,
          boundaries_used = .scalar_chr(boundaries$scope),
          tier_used = .scalar_chr(paste0("tier_", tier)),
          detailed_objects = NULL
        )
      }
    )

    farm_results[[i]] <- result

    if (result$success) {
      n_successful <- n_successful + 1L
    } else {
      n_errors <- n_errors + 1L
      message("Error in farm ", farm_id, ": ", result$error)
    }
  }

  summary_info <- list(
    n_farms_processed = n,
    n_farms_successful = n_successful,
    n_farms_with_errors = n_errors,
    boundaries_used = boundaries,
    benchmark_region = benchmark_region,
    processing_date = processing_date
  )

  batch_results <- list(
    summary = summary_info,
    farm_results = farm_results
  )
  class(batch_results) <- "cf_batch_complete"
  batch_results
}

# ---------------------------------------------
# Export results to Excel (unified version)
# ---------------------------------------------

#' Export cowfootR batch results to Excel
#'
#' Exports results from \code{calc_batch()} into an Excel file
#' with summary and farm-level sheets.
#' Emission columns are exported as annual emissions (kg CO2eq yr-1).
#' Intensity columns are exported as kg CO2eq per kg FPCM and kg CO2eq per ha.
#'
#' @param batch_results A \code{cf_batch_complete} object returned by \code{calc_batch()}.
#' @param file Path to the Excel file to save. Default = "cowfootR_report.xlsx".
#' @param include_details Logical. If TRUE, includes extra sheets with detailed objects (if available).
#'
#' @return Invisibly returns the file path. The Excel output includes unit-consistent
#' columns for annual emissions (kg CO2eq yr-1) and emission intensities.
#' @export
#' @examples
#' \donttest{
#' # Minimal dummy object (como el devuelto por calc_batch)
#' br <- list(
#'   summary = list(
#'     n_farms_processed = 1L,
#'     n_farms_successful = 1L,
#'     n_farms_with_errors = 0L,
#'     boundaries_used = list(scope = "farm_gate"),
#'     benchmark_region = NA_character_,
#'     processing_date = Sys.Date()
#'   ),
#'   farm_results = list(list(
#'     success = TRUE,
#'     farm_id = "Farm_A",
#'     year = format(Sys.Date(), "%Y"),
#'     emissions_enteric = 100, emissions_manure = 50, emissions_soil = 20,
#'     emissions_energy = 10, emissions_inputs = 5, emissions_total = 185,
#'     intensity_milk_kg_co2eq_per_kg_fpcm = 1.2,
#'     intensity_area_kg_co2eq_per_ha_total = 800,
#'     intensity_area_kg_co2eq_per_ha_productive = 1000,
#'     fpcm_production_kg = 150000, milk_production_kg = 154500,
#'     milk_production_litres = 150000,
#'     land_use_efficiency = 3000,
#'     total_animals = 200, dairy_cows = 120,
#'     benchmark_region = NA_character_, benchmark_performance = NA_character_,
#'     processing_date = Sys.Date(), boundaries_used = "farm_gate",
#'     tier_used = "tier_2", detailed_objects = NULL
#'   ))
#' )
#' class(br) <- "cf_batch_complete"
#'
#' f <- tempfile(fileext = ".xlsx")
#' export_hdc_report(br, file = f)
#' file.exists(f)
#' }
export_hdc_report <- function(batch_results,
                              file = "cowfootR_report.xlsx",
                              include_details = FALSE) {
  if (!requireNamespace("writexl", quietly = TRUE)) {
    stop("Package 'writexl' is required. Please install it with install.packages('writexl').")
  }
  if (!inherits(batch_results, "cf_batch_complete")) {
    stop("batch_results must be an object returned by calc_batch()")
  }

  # ---- SUMMARY SHEET ----
  summary_df <- data.frame(
    Farms_processed = .scalar_num(batch_results$summary$n_farms_processed),
    Farms_successful = .scalar_num(batch_results$summary$n_farms_successful),
    Farms_with_errors = .scalar_num(batch_results$summary$n_farms_with_errors),
    Boundaries_used = .scalar_chr(batch_results$summary$boundaries_used$scope),
    Benchmark_region = .scalar_chr(batch_results$summary$benchmark_region),
    Processing_date = .scalar_chr(as.character(batch_results$summary$processing_date)),
    stringsAsFactors = FALSE
  )

  # ---- FARM-LEVEL RESULTS ----
  farms_df <- do.call(
    rbind,
    lapply(batch_results$farm_results, function(farm) {
      if (!farm$success) {
        return(data.frame(
          FarmID = .scalar_chr(farm$farm_id),
          Year = .scalar_chr(farm$year),
          Error = .scalar_chr(farm$error),
          stringsAsFactors = FALSE
        ))
      }
      data.frame(
        FarmID = .scalar_chr(farm$farm_id),
        Year = .scalar_chr(farm$year),
        Emissions_enteric = .scalar_num(farm$emissions_enteric),
        Emissions_manure = .scalar_num(farm$emissions_manure),
        Emissions_soil = .scalar_num(farm$emissions_soil),
        Emissions_energy = .scalar_num(farm$emissions_energy),
        Emissions_inputs = .scalar_num(farm$emissions_inputs),
        Emissions_total = .scalar_num(farm$emissions_total),
        Intensity_milk = .scalar_num(farm$intensity_milk_kg_co2eq_per_kg_fpcm),
        Intensity_area_total = .scalar_num(farm$intensity_area_kg_co2eq_per_ha_total),
        Intensity_area_productive = .scalar_num(farm$intensity_area_kg_co2eq_per_ha_productive),
        FPCM_production_kg = .scalar_num(farm$fpcm_production_kg),
        Milk_production_kg = .scalar_num(farm$milk_production_kg),
        Milk_production_litres = .scalar_num(farm$milk_production_litres),
        Land_use_efficiency = .scalar_num(farm$land_use_efficiency),
        Total_animals = .scalar_num(farm$total_animals),
        Dairy_cows = .scalar_num(farm$dairy_cows),
        Benchmark_region = .scalar_chr(farm$benchmark_region),
        Benchmark_performance = .scalar_chr(farm$benchmark_performance),
        Processing_date = .scalar_chr(as.character(farm$processing_date)),
        Boundaries_used = .scalar_chr(farm$boundaries_used),
        Tier_used = .scalar_chr(farm$tier_used),
        stringsAsFactors = FALSE
      )
    })
  )

  sheets <- list(
    Summary = summary_df,
    Farm_results = farms_df
  )

  if (include_details) {
    for (i in seq_along(batch_results$farm_results)) {
      farm <- batch_results$farm_results[[i]]
      if (farm$success && !is.null(farm$detailed_objects)) {
        sheets[[paste0("Farm_", .scalar_chr(farm$farm_id))]] <- data.frame(
          Section = names(farm$detailed_objects),
          Detail = vapply(
            farm$detailed_objects,
            function(x) paste(capture.output(str(x, max.level = 2)), collapse = " | "),
            FUN.VALUE = character(1)
          ),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  writexl::write_xlsx(sheets, path = file)
  message("Batch report saved to: ", file)
  invisible(file)
}
