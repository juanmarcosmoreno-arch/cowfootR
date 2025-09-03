#' Calculate indirect emissions from purchased inputs
#'
#' Estimates CO2eq emissions from purchased inputs such as feeds, concentrates,
#' fertilizers, and plastics with regional factors and uncertainty analysis.
#'
#' @param conc_kg Numeric. Purchased concentrate feed (kg/year). Default = 0.
#' @param fert_n_kg Numeric. Purchased nitrogen fertilizer (kg N/year). Default = 0.
#' @param plastic_kg Numeric. Agricultural plastics used (kg/year). Default = 0.
#' @param feed_grain_dry_kg Numeric. Grain dry (kg/year, DM). Default = 0.
#' @param feed_grain_wet_kg Numeric. Grain wet (kg/year, DM). Default = 0.
#' @param feed_ration_kg Numeric. Ration + lex (kg/year, DM). Default = 0.
#' @param feed_byproducts_kg Numeric. Byproducts (kg/year, DM). Default = 0.
#' @param feed_proteins_kg Numeric. Proteins (kg/year, DM). Default = 0.
#' @param feed_corn_kg Numeric. Corn grain specific (kg/year, DM). Default = 0.
#' @param feed_soy_kg Numeric. Soybean meal specific (kg/year, DM). Default = 0.
#' @param feed_wheat_kg Numeric. Wheat grain specific (kg/year, DM). Default = 0.
#' @param region Character. Geographic region for emission factors.
#'   Options: "EU", "US", "Brazil", "Argentina", "Australia", "global". Default = "global".
#' @param fert_type Character. Fertilizer type. Options: "urea", "ammonium_nitrate",
#'   "mixed", "organic". Default = "mixed".
#' @param plastic_type Character. Plastic type. Options: "LDPE", "HDPE", "PP", "mixed".
#'   Default = "mixed".
#' @param include_uncertainty Logical. Include uncertainty ranges in output? Default = FALSE.
#' @param transport_km Numeric. Average transport distance for feeds (km). Default = NULL.
#' @param ef_conc Numeric. Override EF for concentrate feed (kg CO2eq/kg). Default = NULL.
#' @param ef_fert Numeric. Override EF for N fertilizer (kg CO2eq/kg N). Default = NULL.
#' @param ef_plastic Numeric. Override EF for plastic (kg CO2eq/kg). Default = NULL.
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'
#' @return A list with emissions (kg CO2eq) by input, uncertainties, and metadata.
#' @export
#'
#' @examples
#' # Basic usage with regional factors
#' calc_emissions_inputs(
#'   conc_kg = 1000,
#'   feed_soy_kg = 500,
#'   fert_n_kg = 200,
#'   region = "EU"
#' )
#'
#' # With uncertainty analysis
#' calc_emissions_inputs(
#'   conc_kg = 1000,
#'   feed_corn_kg = 2000,
#'   region = "US",
#'   include_uncertainty = TRUE
#' )
#'
#' # Specific fertilizer and plastic types
#' calc_emissions_inputs(
#'   fert_n_kg = 300,
#'   plastic_kg = 50,
#'   fert_type = "urea",
#'   plastic_type = "LDPE",
#'   region = "Brazil"
#' )
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

  # ============================================================================
  # INPUT VALIDATION
  # ============================================================================

  valid_regions <- c("EU", "US", "Brazil", "Argentina", "Australia", "global")
  valid_fert_types <- c("urea", "ammonium_nitrate", "mixed", "organic")
  valid_plastic_types <- c("LDPE", "HDPE", "PP", "mixed")

  if (!region %in% valid_regions) {
    stop("Invalid region. Use: ", paste(valid_regions, collapse = ", "))
  }
  if (!fert_type %in% valid_fert_types) {
    stop("Invalid fert_type. Use: ", paste(valid_fert_types, collapse = ", "))
  }

  # Normalize plastic_type to avoid case misalignment
  plastic_type_in <- toupper(plastic_type)
  if (plastic_type_in %in% c("LDPE", "HDPE", "PP")) {
    plastic_type <- plastic_type_in
  } else if (tolower(plastic_type) == "mixed") {
    plastic_type <- "mixed"
  } else {
    stop("Invalid plastic_type. Use: ", paste(valid_plastic_types, collapse = ", "))
  }

  # Check non-negative inputs
  inputs_vec <- c(conc_kg, fert_n_kg, plastic_kg, feed_grain_dry_kg, feed_grain_wet_kg,
                  feed_ration_kg, feed_byproducts_kg, feed_proteins_kg,
                  feed_corn_kg, feed_soy_kg, feed_wheat_kg)
  if (any(inputs_vec < 0, na.rm = TRUE)) {
    stop("All input quantities must be non-negative")
  }

  # Exclude if boundaries does not include "inputs" (fixed the "!" logic)
  if (!is.null(boundaries) && !("inputs" %in% boundaries$include)) {
    return(list(
      source = "inputs",
      total_co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # ============================================================================
  # REGIONAL EMISSION FACTORS
  # ============================================================================

  regional_factors <- get_regional_emission_factors()
  region_ef <- regional_factors[[region]]

  # ============================================================================
  # FERTILIZER EMISSION FACTORS
  # ============================================================================

  if (is.null(ef_fert)) {
    fertilizer_factors <- region_ef$fertilizer[[fert_type]]
    ef_fert <- fertilizer_factors$mean
    ef_fert_uncertainty <- if (include_uncertainty) fertilizer_factors$range else NULL
  } else {
    ef_fert_uncertainty <- NULL
  }

  # ============================================================================
  # FEED EMISSION FACTORS
  # ============================================================================

  if (is.null(ef_conc)) {
    ef_conc <- region_ef$feeds$concentrate$mean
    ef_conc_uncertainty <- if (include_uncertainty) region_ef$feeds$concentrate$range else NULL
  } else {
    ef_conc_uncertainty <- NULL
  }

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

  # ============================================================================
  # PLASTIC EMISSION FACTORS
  # ============================================================================

  if (is.null(ef_plastic)) {
    plastic_factors <- region_ef$plastic[[plastic_type]]
    ef_plastic <- plastic_factors$mean
    ef_plastic_uncertainty <- if (include_uncertainty) plastic_factors$range else NULL
  } else {
    ef_plastic_uncertainty <- NULL
  }

  # ============================================================================
  # TRANSPORT ADJUSTMENT (robust to NULL/length 0/NA/Inf)
  # ============================================================================

  safe_num <- function(x) {
    y <- suppressWarnings(as.numeric(x))
    if (is.null(x) || length(y) == 0 || !is.finite(y)) return(0)
    y
  }

  transport_km <- safe_num(transport_km)

  transport_adjustment <- 0
  if (transport_km > 0) {
    # kg CO2e per kg·km (typical truck)
    transport_ef <- 1e-4
    total_feed_kg <- sum(c(conc_kg, feed_grain_dry_kg, feed_grain_wet_kg,
                           feed_ration_kg, feed_byproducts_kg, feed_proteins_kg,
                           feed_corn_kg, feed_soy_kg, feed_wheat_kg), na.rm = TRUE)
    transport_adjustment <- total_feed_kg * transport_km * transport_ef
  }

  # ============================================================================
  # EMISSION CALCULATIONS
  # ============================================================================

  conc_co2   <- conc_kg     * ef_conc
  fert_co2   <- fert_n_kg   * ef_fert
  plastic_co2<- plastic_kg  * ef_plastic

  feed_emissions <- list(
    grain_dry = feed_grain_dry_kg  * feed_factors$grain_dry$mean,
    grain_wet = feed_grain_wet_kg  * feed_factors$grain_wet$mean,
    ration    = feed_ration_kg     * feed_factors$ration$mean,
    byproducts= feed_byproducts_kg * feed_factors$byproducts$mean,
    proteins  = feed_proteins_kg   * feed_factors$proteins$mean,
    corn      = feed_corn_kg       * feed_factors$corn$mean,
    soy       = feed_soy_kg        * feed_factors$soy$mean,
    wheat     = feed_wheat_kg      * feed_factors$wheat$mean
  )

  # Named numeric vector (avoids round() error on lists)
  feeds_co2_vec <- unlist(feed_emissions, use.names = TRUE)
  total_feed_co2 <- sum(feeds_co2_vec, na.rm = TRUE)

  total_co2eq <- conc_co2 + fert_co2 + plastic_co2 + total_feed_co2 + transport_adjustment

  # ============================================================================
  # UNCERTAINTY ANALYSIS
  # ============================================================================

  uncertainty_results <- NULL
  if (include_uncertainty) {
    uncertainty_results <- calculate_input_uncertainties(
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
        conc = list(mean = ef_conc, range = ef_conc_uncertainty),
        fert = list(mean = ef_fert, range = ef_fert_uncertainty),
        plastic = list(mean = ef_plastic, range = ef_plastic_uncertainty),
        feeds = feed_factors
      )
    )
  }

  # ============================================================================
  # RETURN COMPREHENSIVE RESULTS
  # ============================================================================

  result <- list(
    source = "inputs",
    region = region,

    emissions_breakdown = list(
      concentrate_co2eq_kg           = round(conc_co2, 2),
      fertilizer_co2eq_kg            = round(fert_co2, 2),
      plastic_co2eq_kg               = round(plastic_co2, 2),
      feeds_co2eq_kg                 = round(feeds_co2_vec, 2),     # <- main FIX
      transport_adjustment_co2eq_kg  = round(transport_adjustment, 2),
      total_feeds_co2eq_kg           = round(total_feed_co2, 2)
    ),

    total_co2eq_kg = round(total_co2eq, 2),

    emission_factors_used = list(
      concentrate = list(value = ef_conc, unit = "kg CO2eq/kg"),
      fertilizer  = list(value = ef_fert, type = fert_type, unit = "kg CO2eq/kg N"),
      plastic     = list(value = ef_plastic, type = plastic_type, unit = "kg CO2eq/kg"),
      feeds       = lapply(feed_factors, function(x) list(value = x$mean, unit = "kg CO2eq/kg")),
      region_source = region,
      transport_km  = transport_km
    ),

    inputs_summary = list(
      concentrate_kg  = conc_kg,
      fertilizer_n_kg = fert_n_kg,
      plastic_kg      = plastic_kg,
      total_feeds_kg  = sum(c(feed_grain_dry_kg, feed_grain_wet_kg, feed_ration_kg,
                              feed_byproducts_kg, feed_proteins_kg, feed_corn_kg,
                              feed_soy_kg, feed_wheat_kg), na.rm = TRUE),
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

    contribution_analysis = if (total_co2eq > 0) {
      list(
        concentrate_pct = round(conc_co2 / total_co2eq * 100, 1),
        fertilizer_pct  = round(fert_co2 / total_co2eq * 100, 1),
        plastic_pct     = round(plastic_co2 / total_co2eq * 100, 1),
        feeds_pct       = round(total_feed_co2 / total_co2eq * 100, 1),
        transport_pct   = round(transport_adjustment / total_co2eq * 100, 1)
      )
    } else NULL,

    uncertainty = uncertainty_results,

    methodology = "Enhanced regional emission factors with uncertainty analysis",
    standards = "IDF 2022, Ecoinvent 3.8, Regional databases",
    date = Sys.Date()
  )

  return(result)
}

# ============================================================================
# HELPER FUNCTION: REGIONAL EMISSION FACTORS DATABASE
# ============================================================================

get_regional_emission_factors <- function() {

  # Comprehensive regional emission factors database
  # Based on Ecoinvent, USDA LCA, EU databases, and regional studies

  list(
    global = list(
      fertilizer = list(
        mixed = list(mean = 6.6, range = c(5.5, 7.8)),
        urea = list(mean = 7.2, range = c(6.1, 8.5)),
        ammonium_nitrate = list(mean = 6.1, range = c(5.2, 7.2)),
        organic = list(mean = 0.8, range = c(0.5, 1.2))
      ),
      feeds = list(
        concentrate = list(mean = 0.7, range = c(0.5, 1.2)),
        grain_dry = list(mean = 0.4, range = c(0.3, 0.6)),
        grain_wet = list(mean = 0.3, range = c(0.25, 0.45)),
        ration = list(mean = 0.6, range = c(0.4, 0.8)),
        byproducts = list(mean = 0.15, range = c(0.1, 0.25)),
        proteins = list(mean = 1.8, range = c(1.2, 2.5)),
        corn = list(mean = 0.45, range = c(0.35, 0.65)),
        soy = list(mean = 2.1, range = c(1.5, 2.8)),
        wheat = list(mean = 0.52, range = c(0.4, 0.7))
      ),
      plastic = list(
        mixed = list(mean = 2.5, range = c(1.8, 3.5)),
        LDPE = list(mean = 2.8, range = c(2.2, 3.6)),
        HDPE = list(mean = 2.3, range = c(1.9, 2.9)),
        PP = list(mean = 2.1, range = c(1.6, 2.8))
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
        concentrate = list(mean = 0.75, range = c(0.55, 1.1)),
        grain_dry = list(mean = 0.42, range = c(0.32, 0.58)),
        grain_wet = list(mean = 0.32, range = c(0.26, 0.42)),
        ration = list(mean = 0.65, range = c(0.45, 0.85)),
        byproducts = list(mean = 0.18, range = c(0.12, 0.28)),
        proteins = list(mean = 2.2, range = c(1.6, 2.9)),
        corn = list(mean = 0.48, range = c(0.38, 0.65)),
        soy = list(mean = 2.6, range = c(2.1, 3.2)),  # Higher due to transport from Brazil
        wheat = list(mean = 0.51, range = c(0.42, 0.68))
      ),
      plastic = list(
        mixed = list(mean = 2.3, range = c(1.9, 3.1)),
        LDPE = list(mean = 2.6, range = c(2.1, 3.3)),
        HDPE = list(mean = 2.1, range = c(1.8, 2.7)),
        PP = list(mean = 1.9, range = c(1.5, 2.5))
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
        grain_dry = list(mean = 0.35, range = c(0.28, 0.48)),
        grain_wet = list(mean = 0.28, range = c(0.22, 0.38)),
        ration = list(mean = 0.55, range = c(0.38, 0.75)),
        byproducts = list(mean = 0.12, range = c(0.08, 0.18)),
        proteins = list(mean = 1.5, range = c(1.1, 2.1)),
        corn = list(mean = 0.38, range = c(0.31, 0.52)),  # Lower - domestic production
        soy = list(mean = 1.6, range = c(1.2, 2.2)),      # Lower - domestic production
        wheat = list(mean = 0.45, range = c(0.35, 0.61))
      ),
      plastic = list(
        mixed = list(mean = 2.4, range = c(1.7, 3.4)),
        LDPE = list(mean = 2.7, range = c(2.0, 3.5)),
        HDPE = list(mean = 2.2, range = c(1.7, 2.8)),
        PP = list(mean = 2.0, range = c(1.5, 2.7))
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
        grain_dry = list(mean = 0.36, range = c(0.29, 0.49)),
        grain_wet = list(mean = 0.29, range = c(0.23, 0.39)),
        ration = list(mean = 0.58, range = c(0.41, 0.78)),
        byproducts = list(mean = 0.13, range = c(0.09, 0.19)),
        proteins = list(mean = 1.4, range = c(1.0, 1.9)),
        corn = list(mean = 0.32, range = c(0.26, 0.44)),
        soy = list(mean = 1.2, range = c(0.9, 1.6)),      # Lower - domestic production
        wheat = list(mean = 0.58, range = c(0.45, 0.78))
      ),
      plastic = list(
        mixed = list(mean = 2.7, range = c(2.1, 3.6)),
        LDPE = list(mean = 3.0, range = c(2.4, 3.8)),
        HDPE = list(mean = 2.5, range = c(2.0, 3.2)),
        PP = list(mean = 2.3, range = c(1.8, 3.0))
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
        grain_dry = list(mean = 0.34, range = c(0.27, 0.46)),
        grain_wet = list(mean = 0.27, range = c(0.21, 0.37)),
        ration = list(mean = 0.56, range = c(0.39, 0.76)),
        byproducts = list(mean = 0.11, range = c(0.07, 0.17)),
        proteins = list(mean = 1.3, range = c(0.9, 1.8)),
        corn = list(mean = 0.31, range = c(0.25, 0.42)),
        soy = list(mean = 1.1, range = c(0.8, 1.5)),      # Lower - domestic production
        wheat = list(mean = 0.41, range = c(0.32, 0.56))
      ),
      plastic = list(
        mixed = list(mean = 2.8, range = c(2.2, 3.7)),
        LDPE = list(mean = 3.1, range = c(2.5, 3.9)),
        HDPE = list(mean = 2.6, range = c(2.1, 3.3)),
        PP = list(mean = 2.4, range = c(1.9, 3.1))
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
        grain_dry = list(mean = 0.41, range = c(0.33, 0.56)),
        grain_wet = list(mean = 0.31, range = c(0.25, 0.41)),
        ration = list(mean = 0.63, range = c(0.44, 0.84)),
        byproducts = list(mean = 0.16, range = c(0.11, 0.24)),
        proteins = list(mean = 1.9, range = c(1.4, 2.6)),
        corn = list(mean = 0.46, range = c(0.37, 0.62)),
        soy = list(mean = 2.3, range = c(1.8, 3.0)),      # Higher due to import
        wheat = list(mean = 0.44, range = c(0.35, 0.59))
      ),
      plastic = list(
        mixed = list(mean = 2.6, range = c(2.0, 3.5)),
        LDPE = list(mean = 2.9, range = c(2.3, 3.7)),
        HDPE = list(mean = 2.4, range = c(1.9, 3.1)),
        PP = list(mean = 2.2, range = c(1.7, 2.9))
      )
    )
  )
}

# ============================================================================
# HELPER FUNCTION: UNCERTAINTY CALCULATIONS
# ============================================================================

calculate_input_uncertainties <- function(quantities, factors) {

  # Monte Carlo simulation for uncertainty propagation
  n_simulations <- 1000

  # Generate random samples for each factor
  simulate_factor <- function(factor_info) {
    if (is.null(factor_info$range)) return(rep(factor_info$mean, n_simulations))
    runif(n_simulations, factor_info$range[1], factor_info$range[2])
  }

  # Simulate emission factors
  conc_samples <- simulate_factor(factors$conc)
  fert_samples <- simulate_factor(factors$fert)
  plastic_samples <- simulate_factor(factors$plastic)

  feed_samples <- lapply(factors$feeds, simulate_factor)

  # Calculate total emissions for each simulation
  total_samples <- rep(0, n_simulations)

  # Add concentrate emissions
  total_samples <- total_samples + quantities$conc_kg * conc_samples

  # Add fertilizer emissions
  total_samples <- total_samples + quantities$fert_n_kg * fert_samples

  # Add plastic emissions
  total_samples <- total_samples + quantities$plastic_kg * plastic_samples

  # Add feed emissions
  feed_names <- names(quantities$feeds)
  for (feed in feed_names) {
    if (quantities$feeds[[feed]] > 0) {
      total_samples <- total_samples + quantities$feeds[[feed]] * feed_samples[[feed]]
    }
  }

  # Calculate uncertainty statistics
  list(
    mean = round(mean(total_samples), 2),
    median = round(median(total_samples), 2),
    sd = round(sd(total_samples), 2),
    cv_percent = round(sd(total_samples) / mean(total_samples) * 100, 1),
    percentiles = list(
      p5 = round(quantile(total_samples, 0.05), 2),
      p25 = round(quantile(total_samples, 0.25), 2),
      p75 = round(quantile(total_samples, 0.75), 2),
      p95 = round(quantile(total_samples, 0.95), 2)
    ),
    confidence_interval_95 = list(
      lower = round(quantile(total_samples, 0.025), 2),
      upper = round(quantile(total_samples, 0.975), 2)
    )
  )
}

# ============================================================================
# USAGE EXAMPLES
# ============================================================================

# Example 1: Basic regional usage
# result1 <- calc_emissions_inputs(
#   conc_kg = 1500,
#   feed_soy_kg = 800,
#   feed_corn_kg = 1200,
#   fert_n_kg = 250,
#   region = "US"
# )

# Example 2: European system with uncertainty
# result2 <- calc_emissions_inputs(
#   conc_kg = 1200,
#   feed_soy_kg = 600,
#   feed_wheat_kg = 800,
#   fert_n_kg = 300,
#   fert_type = "urea",
#   plastic_kg = 75,
#   plastic_type = "LDPE",
#   region = "EU",
#   include_uncertainty = TRUE
# )

# Example 3: South American intensive system
# result3 <- calc_emissions_inputs(
#   conc_kg = 2000,
#   feed_soy_kg = 1000,
#   feed_corn_kg = 1500,
#   feed_byproducts_kg = 500,
#   fert_n_kg = 400,
#   plastic_kg = 100,
#   transport_km = 150,
#   region = "Brazil",
#   include_uncertainty = TRUE
# )
