#' Calculate soil N2O emissions
#'
#' Estimates direct and indirect N2O emissions from soils due to
#' fertilization, excreta deposition, and crop residues using IPCC methodology.
#'
#' @param n_fertilizer_synthetic Numeric. Synthetic nitrogen fertilizer applied (kg N/year).
#'   Default = 0.
#' @param n_fertilizer_organic Numeric. Organic nitrogen fertilizer applied (kg N/year).
#'   Default = 0.
#' @param n_excreta_pasture Numeric. Nitrogen excreted directly on pasture (kg N/year).
#'   Default = 0.
#' @param n_crop_residues Numeric. Nitrogen in crop residues returned to soil (kg N/year).
#'   Default = 0.
#' @param area_ha Numeric. Total farm area (hectares). Used for calculating per-hectare metrics.
#' @param soil_type Character. Soil drainage characteristics. Options: "well_drained",
#'   "poorly_drained". Default = "well_drained". Affects emission factors.
#' @param climate Character. Climate classification. Options: "temperate", "tropical".
#'   Default = "temperate". Affects emission factors.
#' @param ef_direct Numeric. Direct emission factor for N2O-N (kg N2O-N/kg N input).
#'   If NULL, uses IPCC 2019 values adjusted by soil type and climate.
#' @param include_indirect Logical. Include indirect N2O emissions from volatilization
#'   and leaching? Default = TRUE.
#' @param gwp_n2o Numeric. Global Warming Potential of N2O. Default = 273 (IPCC AR6).
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'   If "soil" is not included, returns 0.
#'
#' @return A list with detailed N2O emissions by source, direct/indirect components,
#'   and metadata following IDF methodology.
#' @export
#'
#' @examples
#' # Basic calculation with synthetic fertilizer
#' calc_emissions_soil(n_fertilizer_synthetic = 1500, area_ha = 100)
#'
#' # Mixed system with fertilizer and grazing
#' calc_emissions_soil(
#'   n_fertilizer_synthetic = 800,
#'   n_fertilizer_organic = 200,
#'   n_excreta_pasture = 3000,
#'   area_ha = 150
#' )
#'
#' # Tropical poorly-drained conditions
#' calc_emissions_soil(
#'   n_fertilizer_synthetic = 1200,
#'   soil_type = "poorly_drained",
#'   climate = "tropical",
#'   area_ha = 80
#' )
#'
#' # Without indirect emissions
#' calc_emissions_soil(
#'   n_fertilizer_synthetic = 1000,
#'   include_indirect = FALSE,
#'   area_ha = 120
#' )
#'
#' # With system boundaries
#' b <- set_system_boundaries("farm_gate")
#' calc_emissions_soil(n_fertilizer_synthetic = 1500, boundaries = b, area_ha = 100)
calc_emissions_soil <- function(n_fertilizer_synthetic = 0,
                                n_fertilizer_organic = 0,
                                n_excreta_pasture = 0,
                                n_crop_residues = 0,
                                area_ha = NULL,
                                soil_type = "well_drained",
                                climate = "temperate",
                                ef_direct = NULL,
                                include_indirect = TRUE,
                                gwp_n2o = 273,
                                boundaries = NULL) {

  # Input validation
  valid_soils <- c("well_drained", "poorly_drained")
  valid_climates <- c("temperate", "tropical")

  if (!soil_type %in% valid_soils) {
    stop("Invalid soil_type. Use: ", paste(valid_soils, collapse = ", "))
  }
  if (!climate %in% valid_climates) {
    stop("Invalid climate. Use: ", paste(valid_climates, collapse = ", "))
  }
  if (any(c(n_fertilizer_synthetic, n_fertilizer_organic, n_excreta_pasture, n_crop_residues) < 0)) {
    stop("All nitrogen inputs must be non-negative")
  }

  # Exclude if boundaries do not include "soil"
  if (!is.null(boundaries) && !"soil" %in% boundaries$include) {
    return(list(
      source = "soil",
      direct_n2o_kg = 0,
      indirect_n2o_kg = 0,
      total_n2o_kg = 0,
      total_co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # IPCC 2019 direct emission factors (kg N2O-N/kg N input)
  if (is.null(ef_direct)) {
    # Base emission factors by soil and climate
    direct_factors <- list(
      temperate = list(
        well_drained = 0.01,      # Standard IPCC factor
        poorly_drained = 0.015    # Higher for poorly drained soils
      ),
      tropical = list(
        well_drained = 0.012,     # Slightly higher in tropics
        poorly_drained = 0.018    # Much higher for tropical poorly drained
      )
    )
    ef_direct <- direct_factors[[climate]][[soil_type]]
  } else {
    # Validate user-provided factor
    if (ef_direct < 0 || ef_direct > 0.05) {
      warning("ef_direct seems unusual (should be 0.005-0.02 typically)")
    }
  }

  # Calculate total N inputs
  total_n_input <- n_fertilizer_synthetic + n_fertilizer_organic +
    n_excreta_pasture + n_crop_residues

  # DIRECT N2O emissions (N2O-N -> N2O conversion factor = 44/28)
  n2o_direct <- total_n_input * ef_direct * (44/28)

  # INDIRECT N2O emissions (if requested)
  n2o_indirect <- 0
  if (include_indirect) {
    # IPCC 2019 factors for indirect pathways

    # 1. Volatilization pathway (NH3 + NOx -> atmospheric deposition)
    frac_vol_synthetic <- 0.10    # 10% of synthetic N volatilizes
    frac_vol_organic <- 0.20      # 20% of organic N volatilizes
    frac_vol_excreta <- 0.20      # 20% of excreta N volatilizes
    ef_vol <- 0.01                # EF for redeposition of volatilized N

    n_vol <- (n_fertilizer_synthetic * frac_vol_synthetic +
                n_fertilizer_organic * frac_vol_organic +
                n_excreta_pasture * frac_vol_excreta)
    n2o_volatilization <- n_vol * ef_vol * (44/28)

    # 2. Leaching pathway (NO3- leaching and runoff)
    frac_leach <- 0.30            # 30% of applied N can leach
    ef_leach <- 0.0075            # EF for leached N

    n_leach <- total_n_input * frac_leach
    n2o_leaching <- n_leach * ef_leach * (44/28)

    # Total indirect
    n2o_indirect <- n2o_volatilization + n2o_leaching
  }

  # Total N2O emissions
  n2o_total <- n2o_direct + n2o_indirect

  # Convert to CO2 equivalent
  co2eq_total <- n2o_total * gwp_n2o

  # Prepare detailed results
  result <- list(
    source = "soil",
    soil_conditions = list(
      soil_type = soil_type,
      climate = climate
    ),

    # N inputs breakdown
    nitrogen_inputs = list(
      synthetic_fertilizer_kg_n = n_fertilizer_synthetic,
      organic_fertilizer_kg_n = n_fertilizer_organic,
      excreta_pasture_kg_n = n_excreta_pasture,
      crop_residues_kg_n = n_crop_residues,
      total_kg_n = total_n_input
    ),

    # N2O emissions breakdown
    emissions_breakdown = list(
      direct_n2o_kg = round(n2o_direct, 3),
      indirect_volatilization_n2o_kg = ifelse(include_indirect,
                                              round(n2o_volatilization, 3), 0),
      indirect_leaching_n2o_kg = ifelse(include_indirect,
                                        round(n2o_leaching, 3), 0),
      total_indirect_n2o_kg = round(n2o_indirect, 3),
      total_n2o_kg = round(n2o_total, 3)
    ),

    # Total emissions
    co2eq_kg = round(co2eq_total, 2),
    emission_factors = list(
      ef_direct = ef_direct,
      ef_volatilization = ifelse(include_indirect, ef_vol, NA),
      ef_leaching = ifelse(include_indirect, ef_leach, NA),
      gwp_n2o = gwp_n2o,
      factors_source = ifelse(is.null(ef_direct),
                              paste0("IPCC 2019 (", climate, ", ", soil_type, ")"),
                              "User-provided")
    ),
    methodology = ifelse(include_indirect,
                         "IPCC 2019 Tier 1 (direct + indirect)",
                         "IPCC 2019 Tier 1 (direct only)"),
    standards = "IPCC 2019 Refinement, IDF 2022",
    date = Sys.Date()
  )

  # Add per-hectare metrics if area provided
  if (!is.null(area_ha) && area_ha > 0) {
    result$per_hectare_metrics <- list(
      n_input_kg_per_ha = round(total_n_input / area_ha, 1),
      n2o_kg_per_ha = round(n2o_total / area_ha, 3),
      co2eq_kg_per_ha = round(co2eq_total / area_ha, 2),
      emission_intensity_kg_co2eq_per_kg_n = ifelse(total_n_input > 0,
                                                    round(co2eq_total / total_n_input, 2),
                                                    NA)
    )
  }

  # Add contribution analysis
  if (total_n_input > 0) {
    result$source_contributions <- list(
      synthetic_fertilizer_pct = round(n_fertilizer_synthetic / total_n_input * 100, 1),
      organic_fertilizer_pct = round(n_fertilizer_organic / total_n_input * 100, 1),
      excreta_pasture_pct = round(n_excreta_pasture / total_n_input * 100, 1),
      crop_residues_pct = round(n_crop_residues / total_n_input * 100, 1),
      direct_emissions_pct = round(n2o_direct / n2o_total * 100, 1),
      indirect_emissions_pct = round(n2o_indirect / n2o_total * 100, 1)
    )
  }

  return(result)
}


