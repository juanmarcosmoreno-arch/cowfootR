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

  # Non-negative quantities check
  qty <- c(
    conc_kg, fert_n_kg, plastic_kg, feed_grain_dry_kg, feed_grain_wet_kg,
    feed_ration_kg, feed_byproducts_kg, feed_proteins_kg,
    feed_corn_kg, feed_soy_kg, feed_wheat_kg
  )
  if (any(qty < 0, na.rm = TRUE)) stop("All input quantities must be non-negative.")

  # Boundary exclusion: return numeric zero when "inputs" not included
  if (!is.null(boundaries) && !("inputs" %in% boundaries$include)) {
    return(list(
      source = "inputs",
      co2eq_kg = 0,
      total_co2eq_kg = 0,
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
    if (is.null(x) || length(y) == 0L || !is.finite(y)) {
      return(0)
    }
    y
  }
  transport_km <- to_num_safe(transport_km)

  transport_adjustment <- 0
  if (transport_km > 0) {
    # Default LCA truck factor (kg CO2e per kg·km); keep conservative order of magnitude
    ef_truck <- 1e-4
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
      concentrate = list(value = ef_conc, unit = "kg CO2e/kg"),
      fertilizer = list(value = ef_fert, type = fert_type, unit = "kg CO2e/kg N"),
      plastic = list(value = ef_plastic, type = plastic_type, unit = "kg CO2e/kg"),
      feeds = lapply(feed_factors, function(x) list(value = x$mean, unit = "kg CO2e/kg")),
      region_source = region,
      transport_km = transport_km
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

# -------------------------------
# Helper: regional emission factors
# -------------------------------
get_regional_emission_factors <- function() {
  # Representative factors (means and plausible ranges) by region.
  # Replace/extend with your curated database as needed.
  list(
    global = list(
      fertilizer = list(
        mixed = list(mean = 6.6, range = c(5.5, 7.8)),
        urea = list(mean = 7.2, range = c(6.1, 8.5)),
        ammonium_nitrate = list(mean = 6.1, range = c(5.2, 7.2)),
        organic = list(mean = 0.8, range = c(0.5, 1.2))
      ),
      feeds = list(
        concentrate = list(mean = 0.70, range = c(0.50, 1.20)),
        grain_dry   = list(mean = 0.40, range = c(0.30, 0.60)),
        grain_wet   = list(mean = 0.30, range = c(0.25, 0.45)),
        ration      = list(mean = 0.60, range = c(0.40, 0.80)),
        byproducts  = list(mean = 0.15, range = c(0.10, 0.25)),
        proteins    = list(mean = 1.80, range = c(1.20, 2.50)),
        corn        = list(mean = 0.45, range = c(0.35, 0.65)),
        soy         = list(mean = 2.10, range = c(1.50, 2.80)),
        wheat       = list(mean = 0.52, range = c(0.40, 0.70))
      ),
      plastic = list(
        mixed = list(mean = 2.5, range = c(1.8, 3.5)),
        LDPE  = list(mean = 2.8, range = c(2.2, 3.6)),
        HDPE  = list(mean = 2.3, range = c(1.9, 2.9)),
        PP    = list(mean = 2.1, range = c(1.6, 2.8))
      )
    ),
    EU = list(
      fertilizer = list(
        mixed = list(mean = 6.8, range = c(5.8, 7.9)),
        urea = list(mean = 7.5, range = c(6.5, 8.7)),
        ammonium_nitrate = list(mean = 6.3, range = c(5.5, 7.3)),
        organic = list(mean = 0.9, range = c(0.6, 1.3))
      ),
      feeds = list(
        concentrate = list(mean = 0.75, range = c(0.55, 1.10)),
        grain_dry   = list(mean = 0.42, range = c(0.32, 0.58)),
        grain_wet   = list(mean = 0.32, range = c(0.26, 0.42)),
        ration      = list(mean = 0.65, range = c(0.45, 0.85)),
        byproducts  = list(mean = 0.18, range = c(0.12, 0.28)),
        proteins    = list(mean = 2.20, range = c(1.60, 2.90)),
        corn        = list(mean = 0.48, range = c(0.38, 0.65)),
        soy         = list(mean = 2.60, range = c(2.10, 3.20)),
        wheat       = list(mean = 0.51, range = c(0.42, 0.68))
      ),
      plastic = list(
        mixed = list(mean = 2.3, range = c(1.9, 3.1)),
        LDPE  = list(mean = 2.6, range = c(2.1, 3.3)),
        HDPE  = list(mean = 2.1, range = c(1.8, 2.7)),
        PP    = list(mean = 1.9, range = c(1.5, 2.5))
      )
    ),
    US = list(
      fertilizer = list(
        mixed = list(mean = 6.4, range = c(5.3, 7.6)),
        urea = list(mean = 6.9, range = c(5.8, 8.1)),
        ammonium_nitrate = list(mean = 5.9, range = c(5.0, 6.9)),
        organic = list(mean = 0.7, range = c(0.4, 1.0))
      ),
      feeds = list(
        concentrate = list(mean = 0.65, range = c(0.48, 0.95)),
        grain_dry   = list(mean = 0.35, range = c(0.28, 0.48)),
        grain_wet   = list(mean = 0.28, range = c(0.22, 0.38)),
        ration      = list(mean = 0.55, range = c(0.38, 0.75)),
        byproducts  = list(mean = 0.12, range = c(0.08, 0.18)),
        proteins    = list(mean = 1.50, range = c(1.10, 2.10)),
        corn        = list(mean = 0.38, range = c(0.31, 0.52)),
        soy         = list(mean = 1.60, range = c(1.20, 2.20)),
        wheat       = list(mean = 0.45, range = c(0.35, 0.61))
      ),
      plastic = list(
        mixed = list(mean = 2.4, range = c(1.7, 3.4)),
        LDPE  = list(mean = 2.7, range = c(2.0, 3.5)),
        HDPE  = list(mean = 2.2, range = c(1.7, 2.8)),
        PP    = list(mean = 2.0, range = c(1.5, 2.7))
      )
    ),
    Brazil = list(
      fertilizer = list(
        mixed = list(mean = 7.1, range = c(6.0, 8.3)),
        urea = list(mean = 7.8, range = c(6.6, 9.2)),
        ammonium_nitrate = list(mean = 6.5, range = c(5.5, 7.6)),
        organic = list(mean = 0.6, range = c(0.3, 0.9))
      ),
      feeds = list(
        concentrate = list(mean = 0.68, range = c(0.51, 0.98)),
        grain_dry   = list(mean = 0.36, range = c(0.29, 0.49)),
        grain_wet   = list(mean = 0.29, range = c(0.23, 0.39)),
        ration      = list(mean = 0.58, range = c(0.41, 0.78)),
        byproducts  = list(mean = 0.13, range = c(0.09, 0.19)),
        proteins    = list(mean = 1.40, range = c(1.00, 1.90)),
        corn        = list(mean = 0.32, range = c(0.26, 0.44)),
        soy         = list(mean = 1.20, range = c(0.90, 1.60)),
        wheat       = list(mean = 0.58, range = c(0.45, 0.78))
      ),
      plastic = list(
        mixed = list(mean = 2.7, range = c(2.1, 3.6)),
        LDPE  = list(mean = 3.0, range = c(2.4, 3.8)),
        HDPE  = list(mean = 2.5, range = c(2.0, 3.2)),
        PP    = list(mean = 2.3, range = c(1.8, 3.0))
      )
    ),
    Argentina = list(
      fertilizer = list(
        mixed = list(mean = 6.9, range = c(5.8, 8.1)),
        urea = list(mean = 7.6, range = c(6.4, 8.9)),
        ammonium_nitrate = list(mean = 6.3, range = c(5.3, 7.4)),
        organic = list(mean = 0.5, range = c(0.3, 0.8))
      ),
      feeds = list(
        concentrate = list(mean = 0.62, range = c(0.46, 0.89)),
        grain_dry   = list(mean = 0.34, range = c(0.27, 0.46)),
        grain_wet   = list(mean = 0.27, range = c(0.21, 0.37)),
        ration      = list(mean = 0.56, range = c(0.39, 0.76)),
        byproducts  = list(mean = 0.11, range = c(0.07, 0.17)),
        proteins    = list(mean = 1.30, range = c(0.90, 1.80)),
        corn        = list(mean = 0.31, range = c(0.25, 0.42)),
        soy         = list(mean = 1.10, range = c(0.80, 1.50)),
        wheat       = list(mean = 0.41, range = c(0.32, 0.56))
      ),
      plastic = list(
        mixed = list(mean = 2.8, range = c(2.2, 3.7)),
        LDPE  = list(mean = 3.1, range = c(2.5, 3.9)),
        HDPE  = list(mean = 2.6, range = c(2.1, 3.3)),
        PP    = list(mean = 2.4, range = c(1.9, 3.1))
      )
    ),
    Australia = list(
      fertilizer = list(
        mixed = list(mean = 6.5, range = c(5.4, 7.7)),
        urea = list(mean = 7.0, range = c(5.9, 8.2)),
        ammonium_nitrate = list(mean = 6.0, range = c(5.1, 7.0)),
        organic = list(mean = 0.8, range = c(0.5, 1.1))
      ),
      feeds = list(
        concentrate = list(mean = 0.72, range = c(0.53, 1.05)),
        grain_dry   = list(mean = 0.41, range = c(0.33, 0.56)),
        grain_wet   = list(mean = 0.31, range = c(0.25, 0.41)),
        ration      = list(mean = 0.63, range = c(0.44, 0.84)),
        byproducts  = list(mean = 0.16, range = c(0.11, 0.24)),
        proteins    = list(mean = 1.90, range = c(1.40, 2.60)),
        corn        = list(mean = 0.46, range = c(0.37, 0.62)),
        soy         = list(mean = 2.30, range = c(1.80, 3.00)),
        wheat       = list(mean = 0.44, range = c(0.35, 0.59))
      ),
      plastic = list(
        mixed = list(mean = 2.6, range = c(2.0, 3.5)),
        LDPE  = list(mean = 2.9, range = c(2.3, 3.7)),
        HDPE  = list(mean = 2.4, range = c(1.9, 3.1)),
        PP    = list(mean = 2.2, range = c(1.7, 2.9))
      )
    )
  )
}

# -------------------------------
# Helper: uncertainty propagation
# -------------------------------
calculate_input_uncertainties <- function(quantities, factors) {
  # Simple Monte Carlo on uniform ranges
  n <- 1000L

  sample_factor <- function(info) {
    if (is.null(info$range)) {
      return(rep(info$mean, n))
    }
    stats::runif(n, min = info$range[1], max = info$range[2])
  }

  conc_s <- sample_factor(factors$conc)
  fert_s <- sample_factor(factors$fert)
  plast_s <- sample_factor(factors$plastic)
  feed_s <- lapply(factors$feeds, sample_factor)

  total <- numeric(n)
  total <- total + quantities$conc_kg * conc_s
  total <- total + quantities$fert_n_kg * fert_s
  total <- total + quantities$plastic_kg * plast_s

  for (nm in names(quantities$feeds)) {
    q <- quantities$feeds[[nm]]
    if (is.numeric(q) && q > 0) total <- total + q * feed_s[[nm]]
  }

  list(
    mean = round(mean(total), 2),
    median = round(stats::median(total), 2),
    sd = round(stats::sd(total), 2),
    cv_percent = round(stats::sd(total) / mean(total) * 100, 1),
    percentiles = list(
      p5  = round(stats::quantile(total, 0.05), 2),
      p25 = round(stats::quantile(total, 0.25), 2),
      p75 = round(stats::quantile(total, 0.75), 2),
      p95 = round(stats::quantile(total, 0.95), 2)
    ),
    confidence_interval_95 = list(
      lower = round(stats::quantile(total, 0.025), 2),
      upper = round(stats::quantile(total, 0.975), 2)
    )
  )
}
