# ---------------------------------------------
# Minimal helpers
# ---------------------------------------------
`%||%` <- function(a, b) if (is.null(a)) b else a

.scalar_num <- function(x) {
  x <- tryCatch(unlist(x, use.names = FALSE), error = function(e) x)
  x <- suppressWarnings(as.numeric(x))
  if (length(x) == 0L || all(!is.finite(x))) return(NA_real_)
  x[1L]
}
.scalar_chr <- function(x) {
  if (is.null(x) || length(x) == 0L) return(NA_character_)
  x <- tryCatch(as.character(unlist(x, use.names = FALSE)), error = function(e) as.character(x))
  if (length(x) == 0L) NA_character_ else x[1L]
}
.scalar_lgl <- function(x) {
  x <- tryCatch(as.logical(x[[1L]]), error = function(e) as.logical(x))
  if (length(x) == 0L) NA else x[1L]
}

getv <- function(row, name, default = NA) {
  if (!name %in% names(row)) return(default)
  v <- row[[name]]
  if (is.null(v) || (length(v)==1 && is.na(v))) default else v
}

# Safe caller: supports ... and names the 1st arg if it comes unnamed
.call_safe <- function(fn, args_list) {
  if (is.character(fn)) fn <- get(fn, mode = "function")
  fmls <- formals(fn); fml_names <- names(fmls)

  # If the first argument comes unnamed, name it with the first formal (if not "...")
  if (length(args_list) > 0) {
    nm <- names(args_list)
    if (is.null(nm)) nm <- rep("", length(args_list))
    if (nm[1] == "" && length(fml_names) > 0 && fml_names[1] != "...") {
      nm[1] <- fml_names[1]
      names(args_list) <- nm
    }
  }

  # If it accepts ..., pass everything
  if (!is.null(fml_names) && any(fml_names == "...")) {
    return(do.call(fn, args_list))
  }

  # If not, filter by signature
  nm <- names(args_list); if (is.null(nm)) nm <- rep("", length(args_list))
  keep <- nm != "" & nm %in% fml_names
  do.call(fn, args_list[keep])
}

# Ensures each source has source and numeric co2eq_kg (>=0)
.ensure_source <- function(obj, src_name) {
  if (is.null(obj)) return(list(source = src_name, co2eq_kg = 0))
  val <- obj$co2eq_kg
  if (is.null(val)) val <- obj$total_co2eq_kg
  val <- suppressWarnings(as.numeric(val))
  if (length(val) == 0 || !is.finite(val[1])) val <- 0
  if (is.null(obj$source)) obj$source <- src_name
  obj$co2eq_kg <- val[1]
  obj
}

# ---------------------------------------------
# Unified batch: processes data.frame -> results
# ---------------------------------------------
#' Carbon Footprint Batch by rows (tier 1/2)
#'
#' @param data data.frame with the template columns.
#' @param tier 1 or 2.
#' @param boundaries object from \code{set_system_boundaries()}.
#' @param benchmark_region e.g., "uruguay" (optional).
#' @param save_detailed_objects TRUE to save detailed objects.
#' @return list with $summary, $farm_results and class "cf_batch_complete".
#' @export
calc_batch <- function(data,
                       tier = 2,
                       boundaries = set_system_boundaries("farm_gate"),
                       benchmark_region = NULL,
                       save_detailed_objects = FALSE) {

  # Initial validations
  if (is.character(data)) stop("Pasa un data.frame ya leido. Esta version no lee archivos.")
  stopifnot(is.data.frame(data))
  if (!tier %in% c(1,2)) stop("tier debe ser 1 o 2")
  if (nrow(data) == 0) stop("El data.frame esta vacio")

  # Column mapping (change here if your file uses other names)
  CN <- list(id="FarmID", year="Year", milkL="Milk_litres", fat="Fat_percent",
             prot="Protein_percent", dens="Milk_density")
  HERD <- list(cows_milk="Cows_milking", cows_dry="Cows_dry",
               heifers="Heifers_total", calves="Calves_total", bulls="Bulls_total",
               BW_cows="Body_weight_cows_kg", BW_heif="Body_weight_heifers_kg",
               BW_calv="Body_weight_calves_kg", BW_bull="Body_weight_bulls_kg",
               MY_cow="Milk_yield_kg_cow_year")
  FEED <- list(MS_cow="MS_intake_cows_kg_day", MS_heif="MS_intake_heifers_kg_day",
               MS_calv="MS_intake_calves_kg_day", MS_bull="MS_intake_bulls_kg_day",
               Ym="Ym_percent")
  SOIL <- list(N_synth="N_fertilizer_kg", N_organic="N_fertilizer_organic_kg",
               N_past="N_excreta_pasture_kg", N_resid="N_crop_residues_kg",
               area_tot="Area_total_ha", area_prod="Area_productive_ha",
               area_fert="Area_fertilized_ha", soil_type="Soil_type", climate="Climate_zone",
               area_past_perm="Pasture_permanent_ha", area_past_temp="Pasture_temporary_ha",
               area_feed="Crops_feed_ha", area_cash="Crops_cash_ha",
               area_infra="Infrastructure_ha", area_wood="Woodland_ha")
  EN <- list(diesel="Diesel_litres", petrol="Petrol_litres",
             elec="Electricity_KWh",  # adjust here if your column is Electricity_kWh
             lpg="LPG_kg", gas="Natural_gas_m3",
             coal="Coal_kg", bio="Biomass_kg", country="Country")
  INP <- list(conc="Concentrate_feed_kg", plastic="Plastic_kg",
              grain_dry="Feed_grain_dry_kg", grain_wet="Feed_grain_wet_kg",
              ration="Feed_ration_kg", byprod="Feed_byproducts_kg",
              proteins="Feed_proteins_kg")
  MAN <- list(system="Manure_system", N_exc_an="N_excreted_per_cow_kg")

  n <- nrow(data)
  farm_results <- vector("list", n)
  processing_date <- Sys.Date()

  message("Batch: ", n, " filas; tier=", tier, " ...")

  n_successful <- 0
  n_errors <- 0

  for (i in seq_len(n)) {
    row <- data[i, , drop = FALSE]
    farm_id <- .scalar_chr(getv(row, CN$id, paste0("Farm_", i)))
    year <- .scalar_chr(getv(row, CN$year, format(Sys.Date(), "%Y")))

    # Wrap in tryCatch to capture errors
    result <- tryCatch({

      # ---- Inputs ----
      cows_milk <- .scalar_num(getv(row, HERD$cows_milk, 0))
      cows_dry  <- .scalar_num(getv(row, HERD$cows_dry, 0))
      heifers   <- .scalar_num(getv(row, HERD$heifers, 0))
      calves    <- .scalar_num(getv(row, HERD$calves, 0))
      bulls     <- .scalar_num(getv(row, HERD$bulls, 0))
      n_cows_total  <- sum(cows_milk, cows_dry, na.rm = TRUE)
      total_animals <- sum(cows_milk, cows_dry, heifers, calves, bulls, na.rm = TRUE)

      Ym   <- .scalar_num(getv(row, FEED$Ym, if (tier==2) 6.5 else 6.0))
      MS_c <- .scalar_num(getv(row, FEED$MS_cow,  NA))
      MS_h <- .scalar_num(getv(row, FEED$MS_heif, NA))
      MS_k <- .scalar_num(getv(row, FEED$MS_calv, NA))
      MS_b <- .scalar_num(getv(row, FEED$MS_bull, NA))

      MY_cow <- .scalar_num(getv(row, HERD$MY_cow, if (tier==2) 6000 else NA))
      BW_cow <- .scalar_num(getv(row, HERD$BW_cows, 550))
      BW_hef <- .scalar_num(getv(row, HERD$BW_heif, 350))
      BW_cal <- .scalar_num(getv(row, HERD$BW_calv, 150))
      BW_bul <- .scalar_num(getv(row, HERD$BW_bull, 700))

      N_synth   <- .scalar_num(getv(row, SOIL$N_synth, 0))
      N_organic <- .scalar_num(getv(row, SOIL$N_organic, 0))
      N_past    <- .scalar_num(getv(row, SOIL$N_past, 0))
      N_resid   <- .scalar_num(getv(row, SOIL$N_resid, 0))

      area_tot  <- .scalar_num(getv(row, SOIL$area_tot, 100))
      area_prod <- .scalar_num(getv(row, SOIL$area_prod, NA))
      area_fert <- .scalar_num(getv(row, SOIL$area_fert, area_tot))
      soil_type <- .scalar_chr(getv(row, SOIL$soil_type, "well_drained"))
      climate   <- .scalar_chr(getv(row, SOIL$climate, "temperate"))

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
      elec   <- .scalar_num(getv(row, EN$elec,   0))
      lpg    <- .scalar_num(getv(row, EN$lpg,    0))
      gas    <- .scalar_num(getv(row, EN$gas,    0))
      coal   <- .scalar_num(getv(row, EN$coal,   0))
      bio    <- .scalar_num(getv(row, EN$bio,    0))
      country<- .scalar_chr(getv(row, EN$country, "global"))

      conc      <- .scalar_num(getv(row, INP$conc, 0))
      plastic   <- .scalar_num(getv(row, INP$plastic, 0))
      grain_dry <- .scalar_num(getv(row, INP$grain_dry, 0))
      grain_wet <- .scalar_num(getv(row, INP$grain_wet, 0))
      ration    <- .scalar_num(getv(row, INP$ration, 0))
      byprod    <- .scalar_num(getv(row, INP$byprod, 0))
      proteins  <- .scalar_num(getv(row, INP$proteins, 0))

      manure_system <- .scalar_chr(getv(row, MAN$system, "pasture"))
      N_exc_an      <- .scalar_num(getv(row, MAN$N_exc_an, 100))

      # ---- Calculations by source ----
      total_enteric <- 0
      if (n_cows_total > 0) {
        e_cows <- .call_safe("calc_emissions_enteric", list(
          n_cows=n_cows_total, cattle_category="dairy_cows",
          avg_milk_yield=if (is.na(MY_cow)) NULL else MY_cow,
          avg_body_weight=BW_cow,
          ms_intake=if (tier==2) MS_c else NULL,
          ym_percent=Ym, tier=tier, boundaries=boundaries
        )); total_enteric <- total_enteric + .scalar_num(e_cows$co2eq_kg)
      }
      if (heifers > 0) {
        e_h <- .call_safe("calc_emissions_enteric", list(
          n_cows=heifers, cattle_category="heifers",
          avg_body_weight=BW_hef, ms_intake=if (tier==2) MS_h else NULL,
          ym_percent=if (is.na(Ym)) 6.0 else Ym, tier=tier, boundaries=boundaries
        )); total_enteric <- total_enteric + .scalar_num(e_h$co2eq_kg)
      }
      if (calves > 0) {
        e_k <- .call_safe("calc_emissions_enteric", list(
          n_cows=calves, cattle_category="calves",
          avg_body_weight=BW_cal, ms_intake=if (tier==2) MS_k else NULL,
          ym_percent=if (is.na(Ym)) 6.0 else Ym, tier=tier, boundaries=boundaries
        )); total_enteric <- total_enteric + .scalar_num(e_k$co2eq_kg)
      }
      if (bulls > 0) {
        e_b <- .call_safe("calc_emissions_enteric", list(
          n_cows=bulls, cattle_category="bulls",
          avg_body_weight=BW_bul, ms_intake=if (tier==2) MS_b else NULL,
          ym_percent=if (is.na(Ym)) 6.0 else Ym, tier=tier, boundaries=boundaries
        )); total_enteric <- total_enteric + .scalar_num(e_b$co2eq_kg)
      }
      e_enteric <- .ensure_source(list(source="enteric", co2eq_kg = total_enteric), "enteric")

      e_manure <- .call_safe("calc_emissions_manure", list(
        n_cows=total_animals, manure_system=manure_system,
        n_excreted=N_exc_an, include_indirect=TRUE, boundaries=boundaries
      ))
      e_manure <- .ensure_source(e_manure, "manure")

      e_soil <- .call_safe("calc_emissions_soil", list(
        n_fertilizer_synthetic=N_synth, n_fertilizer_organic=N_organic,
        n_excreta_pasture=N_past, n_crop_residues=N_resid,
        area_ha=area_fert, soil_type=soil_type, climate=climate,
        include_indirect=TRUE, boundaries=boundaries
      ))
      e_soil <- .ensure_source(e_soil, "soil")

      e_energy <- .call_safe("calc_emissions_energy", list(
        diesel_l=diesel, petrol_l=petrol, electricity_kwh=elec,
        lpg_kg=lpg, natural_gas_m3=gas,
        coal_kg=coal, biomass_kg=bio,
        country=country, boundaries=boundaries
      ))
      e_energy <- .ensure_source(e_energy, "energy")

      e_inputs <- .call_safe("calc_emissions_inputs", list(
        conc_kg=conc, fert_n_kg=N_synth, plastic_kg=plastic,
        feed_grain_dry_kg=grain_dry, feed_grain_wet_kg=grain_wet,
        feed_ration_kg=ration, feed_byproducts_kg=byprod, feed_proteins_kg=proteins,
        boundaries=boundaries
      ))
      inputs_val <- .scalar_num(e_inputs$co2eq_kg %||% e_inputs$total_co2eq_kg)
      e_inputs <- .ensure_source(list(source="inputs", co2eq_kg = inputs_val), "inputs")

      # Total (always receives 5 sources)
      total <- .call_safe("calc_total_emissions", list(
        e_enteric, e_manure, e_soil, e_energy, e_inputs
      ))

      # Intensities
      milk_L <- .scalar_num(getv(row, CN$milkL, 1000))
      fat    <- .scalar_num(getv(row, CN$fat, 4.0))
      prot   <- .scalar_num(getv(row, CN$prot, 3.3))
      dens   <- .scalar_num(getv(row, CN$dens, 1.03))

      milk_int <- .call_safe("calc_intensity_litre", list(
        total_emissions=total, milk_litres=milk_L,
        fat=fat, protein=prot, milk_density=dens
      ))

      area_int <- .call_safe("calc_intensity_area", list(
        total_emissions=total, area_total_ha=area_tot,
        area_productive_ha=if (is.na(area_prod)) NULL else area_prod,
        area_breakdown=area_breakdown, validate_area_sum=FALSE
      ))
      if (!is.null(benchmark_region)) {
        area_int <- .call_safe("benchmark_area_intensity", list(
          cf_area_intensity = area_int, region = benchmark_region
        ))
      }

      # Successful result structure (compatible with original export_hdc_report)
      list(
        success = TRUE,
        farm_id = farm_id,
        year = year,
        emissions_enteric = .scalar_num(e_enteric$co2eq_kg),
        emissions_manure = .scalar_num(e_manure$co2eq_kg),
        emissions_soil = .scalar_num(e_soil$co2eq_kg),
        emissions_energy = .scalar_num(e_energy$co2eq_kg),
        emissions_inputs = .scalar_num(e_inputs$co2eq_kg),
        emissions_total = .scalar_num(total$total_co2eq),
        intensity_milk_kg_co2eq_per_kg_fpcm = .scalar_num(milk_int$intensity_co2eq_per_kg_fpcm),
        intensity_area_kg_co2eq_per_ha_total = .scalar_num(area_int$intensity_per_total_ha),
        intensity_area_kg_co2eq_per_ha_productive = .scalar_num(area_int$intensity_per_productive_ha),
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
        detailed_objects = if (save_detailed_objects) list(
          enteric=e_enteric, manure=e_manure, soil=e_soil,
          energy=e_energy, inputs=e_inputs, total=total,
          milk_intensity=milk_int, area_intensity=area_int
        ) else NULL
      )

    }, error = function(e) {
      list(
        success = FALSE,
        farm_id = farm_id,
        year = year,
        error = as.character(e$message)
      )
    })

    # Store result
    farm_results[[i]] <- result

    if (result$success) {
      n_successful <- n_successful + 1
    } else {
      n_errors <- n_errors + 1
      message("Error en Farm ", farm_id, ": ", result$error)
    }
  }

  # ---- CREATE SUMMARY ----
  summary_info <- list(
    n_farms_processed = n,
    n_farms_successful = n_successful,
    n_farms_with_errors = n_errors,
    boundaries_used = boundaries,
    benchmark_region = benchmark_region,
    processing_date = processing_date
  )

  # ---- FINAL STRUCTURE (compatible with export_hdc_report) ----
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
#'
#' @param batch_results A cf_batch_complete object returned by \code{calc_batch()}.
#' @param file Path to the Excel file to save. Default = "cowfootR_report.xlsx".
#' @param include_details Logical. If TRUE, includes extra sheets with detailed objects (if available).
#'
#' @return Invisibly returns the file path.
#' @export
export_hdc_report <- function(batch_results,
                              file = "cowfootR_report.xlsx",
                              include_details = FALSE) {

  if (!requireNamespace("writexl", quietly = TRUE)) {
    stop("Package 'writexl' is required. Please install it with install.packages('writexl').")
  }
  if (!inherits(batch_results, "cf_batch_complete")) {
    stop("batch_results must be an object returned by calc_batch()")
  }

  # -------- helpers to coerce scalar values --------
  .scalar_num <- function(x) {
    x <- tryCatch(unlist(x, use.names = FALSE), error = function(e) x)
    x <- suppressWarnings(as.numeric(x))
    if (length(x) == 0L || all(!is.finite(x))) return(NA_real_)
    x[1L]
  }
  .scalar_chr <- function(x) {
    if (is.null(x) || length(x) == 0L) return(NA_character_)
    x <- tryCatch(as.character(x[[1L]]), error = function(e) as.character(x))
    if (length(x) == 0L) NA_character_ else x[1L]
  }
  .scalar_lgl <- function(x) {
    x <- tryCatch(as.logical(x[[1L]]), error = function(e) as.logical(x))
    if (length(x) == 0L) NA else x[1L]
  }

  # ---- SUMMARY SHEET ----
  summary_df <- data.frame(
    Farms_processed   = .scalar_num(batch_results$summary$n_farms_processed),
    Farms_successful  = .scalar_num(batch_results$summary$n_farms_successful),
    Farms_with_errors = .scalar_num(batch_results$summary$n_farms_with_errors),
    Boundaries_used   = .scalar_chr(batch_results$summary$boundaries_used$scope),
    Benchmark_region  = .scalar_chr(batch_results$summary$benchmark_region),
    Processing_date   = .scalar_chr(as.character(batch_results$summary$processing_date)),
    stringsAsFactors = FALSE
  )

  # ---- FARM-LEVEL RESULTS ----
  farms_df <- do.call(
    rbind,
    lapply(batch_results$farm_results, function(farm) {
      # Row for farms with error
      if (!farm$success) {
        return(data.frame(
          FarmID = .scalar_chr(farm$farm_id),
          Year   = .scalar_chr(farm$year),
          Error  = .scalar_chr(farm$error),
          stringsAsFactors = FALSE
        ))
      }
      # Row for OK farms (forcing scalars)
      data.frame(
        FarmID = .scalar_chr(farm$farm_id),
        Year   = .scalar_chr(farm$year),

        Emissions_enteric = .scalar_num(farm$emissions_enteric),
        Emissions_manure  = .scalar_num(farm$emissions_manure),
        Emissions_soil    = .scalar_num(farm$emissions_soil),
        Emissions_energy  = .scalar_num(farm$emissions_energy),
        Emissions_inputs  = .scalar_num(farm$emissions_inputs),
        Emissions_total   = .scalar_num(farm$emissions_total),

        Intensity_milk           = .scalar_num(farm$intensity_milk_kg_co2eq_per_kg_fpcm),
        Intensity_area_total     = .scalar_num(farm$intensity_area_kg_co2eq_per_ha_total),
        Intensity_area_productive= .scalar_num(farm$intensity_area_kg_co2eq_per_ha_productive),

        FPCM_production_kg      = .scalar_num(farm$fpcm_production_kg),
        Milk_production_kg      = .scalar_num(farm$milk_production_kg),
        Milk_production_litres  = .scalar_num(farm$milk_production_litres),
        Land_use_efficiency     = .scalar_num(farm$land_use_efficiency),

        Total_animals = .scalar_num(farm$total_animals),
        Dairy_cows    = .scalar_num(farm$dairy_cows),

        Benchmark_region      = .scalar_chr(farm$benchmark_region),
        Benchmark_performance = .scalar_chr(farm$benchmark_performance),

        Processing_date = .scalar_chr(as.character(farm$processing_date)),
        Boundaries_used = .scalar_chr(farm$boundaries_used),
        Tier_used       = .scalar_chr(farm$tier_used),

        stringsAsFactors = FALSE
      )
    })
  )

  # ---- CREATE LIST OF SHEETS ----
  sheets <- list(
    Summary = summary_df,
    Farm_results = farms_df
  )

  # ---- OPTIONAL DETAILED SHEETS ----
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

  # ---- WRITE EXCEL ----
  writexl::write_xlsx(sheets, path = file)
  message("Batch report saved to: ", file)
  invisible(file)
}
