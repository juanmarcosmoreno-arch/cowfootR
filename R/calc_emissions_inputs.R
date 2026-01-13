#' Calculate indirect emissions from purchased inputs
#'
#' Estimates CO2e emissions from purchased inputs such as feeds, fertilizers,
#' and plastics using regional factors, with optional uncertainty analysis.
#'
#' Notes:
#' * When system boundaries exclude "inputs", this function MUST return a list
#'   with `source = "inputs"` and a numeric `co2eq_kg = 0` to satisfy
#'   partial-boundaries integration.
#' * The primary total field is `co2eq_kg` (for compatibility with
#'   `calc_total_emissions()`); `total_co2eq_kg` is included as a duplicate for
#'   convenience.
#'
#' @param conc_kg Numeric. Purchased concentrate feed (kg/year). Default = 0.
#' @param fert_n_kg Numeric. Purchased nitrogen fertilizer (kg N/year). Default = 0.
#' @param plastic_kg Numeric. Agricultural plastics used (kg/year). Default = 0.
#' @param feed_grain_dry_kg Numeric. Grain dry (kg/year, DM). Default = 0.
#' @param feed_grain_wet_kg Numeric. Grain wet (kg/year, DM). Default = 0.
#' @param feed_ration_kg Numeric. Ration (total mixed ration) (kg/year, DM). Default = 0.
#' @param feed_byproducts_kg Numeric. Byproducts (kg/year, DM). Default = 0.
#' @param feed_proteins_kg Numeric. Protein feeds (kg/year, DM). Default = 0.
#' @param feed_corn_kg Numeric. Corn (kg/year, DM). Default = 0.
#' @param feed_soy_kg Numeric. Soybean meal (kg/year, DM). Default = 0.
#' @param feed_wheat_kg Numeric. Wheat (kg/year, DM). Default = 0.
#' @param region Character. "EU","US","Brazil","Argentina","Australia","global". Default "global".
#' @param fert_type Character. "urea","ammonium_nitrate","mixed","organic". Default "mixed".
#' @param plastic_type Character. "LDPE","HDPE","PP","mixed". Default "mixed".
#' @param include_uncertainty Logical. Include uncertainty ranges? Default FALSE.
#' @param transport_km Numeric. Average feed transport distance (km). Optional.
#' @param ef_conc,ef_fert,ef_plastic Numeric overrides for emission factors (kg CO2e per unit).
#' @param boundaries Optional. Object from \code{set_system_boundaries()}.
#'
#' @return A list with fields:
#'   - source = "inputs"
#'   - emissions_breakdown (named values per input)
#'   - co2eq_kg (numeric total)
#'   - total_co2eq_kg (duplicate of co2eq_kg)
#'   - emission_factors_used, inputs_summary, contribution_analysis, uncertainty (if requested)
#'   - metadata (methodology, standards, date)
#' @export
#'
#' @examples
#' # Quick example (runs fast)
#' calc_emissions_inputs(conc_kg = 1000, fert_n_kg = 200, region = "EU")
#'
#' # With uncertainty analysis
#' calc_emissions_inputs(feed_corn_kg = 2000, region = "US", include_uncertainty = TRUE)
calc_emissions_inputs <- function(conc_kg = 0,
                                  fert_n_kg = 0,
                                  plastic_kg = 0,
                                  feed_grain_dry_kg = 0,
                                  feed_grain_wet_kg = 0,
                                  feed_ration_kg = 0,
                                  feed_byproducts_kg = 0,
                                  feed_proteins_kg = 0,
                                  feed_corn_kg = 0,
                                  feed_soy_kg = 0,
                                  feed_wheat_kg = 0,
                                  region = "global",
                                  fert_type = "mixed",
                                  plastic_type = "mixed",
                                  include_uncertainty = FALSE,
                                  transport_km = NULL,
                                  ef_conc = NULL,
                                  ef_fert = NULL,
                                  ef_plastic = NULL,
                                  boundaries = NULL) {

  # ---- Units (annual) -------------------------------------------------------
  units <- list(
    co2eq_kg = "kg CO2eq yr-1",
    conc_kg = "kg yr-1",
    fert_n_kg = "kg N yr-1",
    plastic_kg = "kg yr-1",
    feed_kg = "kg DM yr-1",
    transport_km = "km",
    ef_conc = "kg CO2e per kg",
    ef_fert = "kg CO2e per kg N",
    ef_plastic = "kg CO2e per kg",
    ef_feed = "kg CO2e per kg DM",
    ef_truck = "kg CO2e per (kg*km)"
  )

  # -------------------------------
  # Input validation and boundaries
  # -------------------------------
  valid_regions <- c("EU", "US", "Brazil", "Argentina", "Australia", "global")
  valid_fert_types <- c("urea", "ammonium_nitrate", "mixed", "organic")
  valid_plastic_types <- c("LDPE", "HDPE", "PP", "mixed")

  if (!region %in% valid_regions) {
    stop("Invalid `region`. Use one of: ", paste(valid_regions, collapse = ", "))
  }
  if (!fert_type %in% valid_fert_types) {
    stop("Invalid `fert_type`. Use one of: ", paste(valid_fert_types, collapse = ", "))
  }

  # Normalize plastic type case-safely
  if (tolower(plastic_type) == "mixed") {
    plastic_type <- "mixed"
  } else {
    plastic_type <- toupper(plastic_type)
    if (!plastic_type %in% c("LDPE", "HDPE", "PP")) {
      stop("Invalid `plastic_type`. Use one of: ", paste(valid_plastic_types, collapse = ", "))
    }
  }

  # Non-negative & finite quantities check
  qty <- c(
    conc_kg, fert_n_kg, plastic_kg, feed_grain_dry_kg, feed_grain_wet_kg,
    feed_ration_kg, feed_byproducts_kg, feed_proteins_kg,
    feed_corn_kg, feed_soy_kg, feed_wheat_kg
  )
  if (any(!is.finite(qty))) stop("All input quantities must be finite numeric scalars.")
  if (any(qty < 0, na.rm = TRUE)) stop("All input quantities must be non-negative.")

  # Boundary exclusion: return numeric zero when "inputs" not included
  if (is.list(boundaries) && !is.null(boundaries$include) &&
      !("inputs" %in% boundaries$include)) {
    return(list(
      source = "inputs",
      co2eq_kg = 0,
      total_co2eq_kg = 0,
      units = units,
      methodology = "excluded_by_boundaries",
      emissions_breakdown = NULL,
      inputs_summary = NULL,
      date = Sys.Date()
    ))
  }

  # -------------------------------
  # Regional emission factor lookup
  # -------------------------------
  regional_factors <- get_regional_emission_factors()
  region_ef <- regional_factors[[region]]

  # Fertilizer EF
  if (is.null(ef_fert)) {
    fert_info <- region_ef$fertilizer[[fert_type]]
    ef_fert <- fert_info$mean
    ef_fert_range <- if (include_uncertainty) fert_info$range else NULL
  } else {
    ef_fert_range <- NULL
  }

  # Concentrate EF
  if (is.null(ef_conc)) {
    conc_info <- region_ef$feeds$concentrate
    ef_conc <- conc_info$mean
    ef_conc_range <- if (include_uncertainty) conc_info$range else NULL
  } else {
    ef_conc_range <- NULL
  }

  # Feed factors (means and optional ranges)
  feed_factors <- list(
    grain_dry = region_ef$feeds$grain_dry,
    grain_wet = region_ef$feeds$grain_wet,
    ration = region_ef$feeds$ration,
    byproducts = region_ef$feeds$byproducts,
    proteins = region_ef$feeds$proteins,
    corn = region_ef$feeds$corn,
    soy = region_ef$feeds$soy,
    wheat = region_ef$feeds$wheat
  )

  # Plastic EF
  if (is.null(ef_plastic)) {
    plast_info <- region_ef$plastic[[plastic_type]]
    ef_plastic <- plast_info$mean
    ef_plastic_range <- if (include_uncertainty) plast_info$range else NULL
  } else {
    ef_plastic_range <- NULL
  }

  # -------------------------------
  # Transport adjustment (optional)
  # -------------------------------
  to_num_safe <- function(x) {
    y <- suppressWarnings(as.numeric(x))
    if (is.null(x) || length(y) == 0L || !is.finite(y)) return(0)
    y
  }
  transport_km <- to_num_safe(transport_km)

  transport_adjustment <- 0
  ef_truck <- 1e-4  # kg CO2e per (kg*km)
  if (transport_km > 0) {
    total_feed_kg <- sum(
      c(
        conc_kg, feed_grain_dry_kg, feed_grain_wet_kg, feed_ration_kg,
        feed_byproducts_kg, feed_proteins_kg,
        feed_corn_kg, feed_soy_kg, feed_wheat_kg
      ),
      na.rm = TRUE
    )
    transport_adjustment <- total_feed_kg * transport_km * ef_truck
  }

  # -------------------------------
  # Emission calculations
  # -------------------------------
  conc_co2 <- conc_kg * ef_conc
  fert_co2 <- fert_n_kg * ef_fert
  plastic_co2 <- plastic_kg * ef_plastic

  feed_emissions <- c(
    grain_dry = feed_grain_dry_kg * feed_factors$grain_dry$mean,
    grain_wet = feed_grain_wet_kg * feed_factors$grain_wet$mean,
    ration = feed_ration_kg * feed_factors$ration$mean,
    byproducts = feed_byproducts_kg * feed_factors$byproducts$mean,
    proteins = feed_proteins_kg * feed_factors$proteins$mean,
    corn = feed_corn_kg * feed_factors$corn$mean,
    soy = feed_soy_kg * feed_factors$soy$mean,
    wheat = feed_wheat_kg * feed_factors$wheat$mean
  )
  total_feed_co2 <- sum(feed_emissions, na.rm = TRUE)

  total_co2 <- conc_co2 + fert_co2 + plastic_co2 + total_feed_co2 + transport_adjustment

  # -------------------------------
  # Uncertainty analysis (optional)
  # -------------------------------
  uncertainty <- NULL
  if (isTRUE(include_uncertainty)) {
    uncertainty <- calculate_input_uncertainties(
      quantities = list(
        conc_kg = conc_kg,
        fert_n_kg = fert_n_kg,
        plastic_kg = plastic_kg,
        feeds = list(
          grain_dry = feed_grain_dry_kg,
          grain_wet = feed_grain_wet_kg,
          ration = feed_ration_kg,
          byproducts = feed_byproducts_kg,
          proteins = feed_proteins_kg,
          corn = feed_corn_kg,
          soy = feed_soy_kg,
          wheat = feed_wheat_kg
        )
      ),
      factors = list(
        conc    = list(mean = ef_conc, range = ef_conc_range),
        fert    = list(mean = ef_fert, range = ef_fert_range),
        plastic = list(mean = ef_plastic, range = ef_plastic_range),
        feeds   = feed_factors
      )
    )
  }

  # -------------------------------
  # Return structured result
  # -------------------------------
  result <- list(
    source = "inputs",
    units = units,

    emissions_breakdown = list(
      concentrate_co2eq_kg          = round(conc_co2, 2),
      fertilizer_co2eq_kg           = round(fert_co2, 2),
      plastic_co2eq_kg              = round(plastic_co2, 2),
      feeds_co2eq_kg                = round(feed_emissions, 2), # named numeric vector
      total_feeds_co2eq_kg          = round(total_feed_co2, 2),
      transport_adjustment_co2eq_kg = round(transport_adjustment, 2)
    ),

    # Primary total used by calc_total_emissions()
    co2eq_kg = round(total_co2, 2),
    # Duplicate field for convenience
    total_co2eq_kg = round(total_co2, 2),

    region = region,

    emission_factors_used = list(
      concentrate = list(value = ef_conc, unit = units$ef_conc),
      fertilizer = list(value = ef_fert, type = fert_type, unit = units$ef_fert),
      plastic = list(value = ef_plastic, type = plastic_type, unit = units$ef_plastic),
      feeds = lapply(feed_factors, function(x) list(value = x$mean, unit = units$ef_feed)),
      transport = list(ef_truck = ef_truck, unit = units$ef_truck, transport_km = transport_km),
      region_source = region
    ),

    inputs_summary = list(
      concentrate_kg = conc_kg,
      fertilizer_n_kg = fert_n_kg,
      plastic_kg = plastic_kg,
      total_feeds_kg = sum(c(
        feed_grain_dry_kg, feed_grain_wet_kg, feed_ration_kg,
        feed_byproducts_kg, feed_proteins_kg,
        feed_corn_kg, feed_soy_kg, feed_wheat_kg
      ), na.rm = TRUE),
      feed_breakdown_kg = list(
        grain_dry  = feed_grain_dry_kg,
        grain_wet  = feed_grain_wet_kg,
        ration     = feed_ration_kg,
        byproducts = feed_byproducts_kg,
        proteins   = feed_proteins_kg,
        corn       = feed_corn_kg,
        soy        = feed_soy_kg,
        wheat      = feed_wheat_kg
      )
    ),

    contribution_analysis = if (total_co2 > 0) {
      list(
        concentrate_pct = round(conc_co2 / total_co2 * 100, 1),
        fertilizer_pct  = round(fert_co2 / total_co2 * 100, 1),
        plastic_pct     = round(plastic_co2 / total_co2 * 100, 1),
        feeds_pct       = round(total_feed_co2 / total_co2 * 100, 1),
        transport_pct   = round(transport_adjustment / total_co2 * 100, 1)
      )
    } else {
      NULL
    },

    uncertainty = uncertainty,
    methodology = "Regional emission factors with optional uncertainty analysis",
    standards = "IDF 2022; generic LCI sources",
    date = Sys.Date()
  )

  result
}
