#' Calculate manure management emissions with Tier 1 and Tier 2 options
#'
#' Estimates CH4 and N2O emissions from manure management
#' using IPCC Tier 1 or Tier 2 methodology with IDF-specific factors.
#'
#' @param n_cows Numeric. Number of dairy cows.
#' @param manure_system Character. Type of manure management system.
#'   Options: "pasture", "solid_storage", "liquid_storage", "anaerobic_digester". Default = "pasture".
#' @param tier Numeric. IPCC methodology tier (1 or 2). Default = 1.
#' @param ef_ch4 Numeric. Emission factor for CH4 (kg CH4 per cow per year).
#'   If NULL, uses system-specific defaults. Only used for Tier 1.
#' @param n_excreted Numeric. Nitrogen excreted per cow per year (kg N).
#'   Default = 100. For Tier 2, calculated from diet data if available.
#' @param ef_n2o_direct Numeric. Emission factor for direct N2O-N (kg N2O-N/kg N excreted).
#'   Default = 0.02 (IPCC 2019 refinement).
#' @param include_indirect Logical. Include indirect N2O emissions
#'   from volatilization and leaching? Default = FALSE.
#' @param climate Character. Climate region for Tier 2. Options: "cold", "temperate", "warm". Default = "temperate".
#' @param avg_body_weight Numeric. Average live weight (kg). Default = 600. Required for Tier 2.
#' @param diet_digestibility Numeric. Apparent digestibility of diet (0-1). Default = 0.65. Required for Tier 2.
#' @param protein_intake_kg Numeric. Daily protein intake (kg/day). Used for refined N2O calculation in Tier 2.
#' @param retention_days Numeric. Days manure stays in system. Default varies by system. Used in Tier 2.
#' @param system_temperature Numeric. Average temperature of manure system (°C). Used in Tier 2.
#' @param gwp_ch4 Numeric. Global Warming Potential of CH4. Default = 27.2 (IPCC AR6).
#' @param gwp_n2o Numeric. Global Warming Potential of N2O. Default = 273 (IPCC AR6).
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'
#' @return A list with CH4 (kg), N2O (kg), CO2eq (kg), and detailed metadata.
#' @export
calc_emissions_manure <- function(n_cows,
                                  manure_system = "pasture",
                                  tier = 1,
                                  ef_ch4 = NULL,
                                  n_excreted = 100,
                                  ef_n2o_direct = 0.02,
                                  include_indirect = FALSE,
                                  climate = "temperate",
                                  avg_body_weight = 600,
                                  diet_digestibility = 0.65,
                                  protein_intake_kg = NULL,
                                  retention_days = NULL,
                                  system_temperature = NULL,
                                  gwp_ch4 = 27.2,
                                  gwp_n2o = 273,
                                  boundaries = NULL) {

  # ============================================================================
  # INPUT VALIDATION
  # ============================================================================

  valid_systems <- c("pasture", "solid_storage", "liquid_storage", "anaerobic_digester")
  valid_climates <- c("cold", "temperate", "warm")
  valid_tiers <- c(1, 2)

  if (n_cows < 0) stop("n_cows must be positive")
  if (!manure_system %in% valid_systems) {
    stop("Invalid manure_system. Use: ", paste(valid_systems, collapse = ", "))
  }
  if (!tier %in% valid_tiers) stop("Invalid tier. Use 1 or 2.")
  if (!climate %in% valid_climates) {
    stop("Invalid climate. Use: ", paste(valid_climates, collapse = ", "))
  }
  if (n_excreted < 0) stop("n_excreted must be positive")
  if (ef_n2o_direct < 0) stop("ef_n2o_direct must be positive")
  if (diet_digestibility <= 0 || diet_digestibility > 1) {
    stop("diet_digestibility must be between 0 and 1")
  }

  # Exclude if boundaries do not include "manure"
  if (!is.null(boundaries) && !"manure" %in% boundaries$include) {
    return(list(
      source = "manure",
      system = manure_system,
      tier = tier,
      ch4_kg = 0,
      n2o_direct_kg = 0,
      n2o_indirect_kg = 0,
      n2o_total_kg = 0,
      co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # ============================================================================
  # TIER 1 CALCULATION
  # ============================================================================

  if (tier == 1) {

    # Default CH4 emission factors (kg CH4/cow/year)
    if (is.null(ef_ch4)) {
      ch4_factors <- list(
        pasture = 1.5,              # Mainly grazing, minimal storage
        solid_storage = 20,         # Solid manure storage systems
        liquid_storage = 30,        # Liquid manure storage systems
        anaerobic_digester = 10     # Controlled anaerobic systems
      )
      ef_ch4 <- ch4_factors[[manure_system]]
    } else {
      if (ef_ch4 < 0) stop("ef_ch4 must be positive")
    }

    # CH4 emissions
    ch4 <- n_cows * ef_ch4

    # N2O emissions (same calculation for both tiers)
    n2o_results <- calc_n2o_emissions(
      n_cows = n_cows,
      n_excreted = n_excreted,
      ef_n2o_direct = ef_n2o_direct,
      include_indirect = include_indirect,
      protein_intake_kg = protein_intake_kg
    )

    methodology_note <- "IPCC Tier 1 (default emission factors)"

  } else {

    # ============================================================================
    # TIER 2 CALCULATION
    # ============================================================================

    # CH4 calculation using VS and MCF approach
    ch4_results <- calc_ch4_tier2(
      n_cows = n_cows,
      avg_body_weight = avg_body_weight,
      diet_digestibility = diet_digestibility,
      manure_system = manure_system,
      climate = climate,
      retention_days = retention_days,
      system_temperature = system_temperature
    )

    ch4 <- ch4_results$ch4_kg_total

    # Enhanced N2O calculation for Tier 2
    n2o_results <- calc_n2o_emissions(
      n_cows = n_cows,
      n_excreted = n_excreted,
      ef_n2o_direct = ef_n2o_direct,
      include_indirect = include_indirect,
      protein_intake_kg = protein_intake_kg,
      tier2_enhancement = TRUE
    )

    methodology_note <- "IPCC Tier 2 (VS and MCF-based calculation)"
  }

  # ============================================================================
  # FINAL CALCULATIONS
  # ============================================================================

  # Total N2O
  n2o_total <- n2o_results$n2o_direct + n2o_results$n2o_indirect

  # Convert to CO2eq
  co2eq <- ch4 * gwp_ch4 + n2o_total * gwp_n2o

  # ============================================================================
  # RETURN COMPREHENSIVE RESULTS
  # ============================================================================

  result <- list(
    source = "manure",
    system = manure_system,
    tier = tier,
    climate = climate,

    # Emissions by gas
    ch4_kg = round(ch4, 2),
    n2o_direct_kg = round(n2o_results$n2o_direct, 2),
    n2o_indirect_kg = round(n2o_results$n2o_indirect, 2),
    n2o_total_kg = round(n2o_total, 2),
    co2eq_kg = round(co2eq, 2),

    # Emission factors used
    emission_factors = list(
      ef_ch4 = ifelse(tier == 1, ef_ch4, NA),
      ef_n2o_direct = ef_n2o_direct,
      gwp_ch4 = gwp_ch4,
      gwp_n2o = gwp_n2o
    ),

    # Input parameters
    inputs = list(
      n_cows = n_cows,
      n_excreted = n2o_results$n_excreted_used,
      manure_system = manure_system,
      include_indirect = include_indirect,
      avg_body_weight = ifelse(tier == 2, avg_body_weight, NA),
      diet_digestibility = ifelse(tier == 2, diet_digestibility, NA)
    ),

    # Methodology information
    methodology = methodology_note,
    standards = "IPCC 2019 Refinement, IDF 2022",
    date = Sys.Date(),

    # Per cow metrics
    per_cow = list(
      ch4_kg = round(ch4 / n_cows, 2),
      n2o_kg = round(n2o_total / n_cows, 4),
      co2eq_kg = round(co2eq / n_cows, 2)
    )
  )

  # Add Tier 2 specific details
  if (tier == 2) {
    result$tier2_details <- ch4_results[c("vs_kg_per_day", "b0_used", "mcf_used")]
  }

  return(result)
}

# ============================================================================
# HELPER FUNCTION: TIER 2 CH4 CALCULATION
# ============================================================================

calc_ch4_tier2 <- function(n_cows, avg_body_weight, diet_digestibility,
                           manure_system, climate, retention_days = NULL,
                           system_temperature = NULL) {

  # Step 1: Calculate Volatile Solids (VS) excretion
  # IPCC 2019 Refinement - improved equation
  if (avg_body_weight > 200) {  # Adult cattle
    vs_excretion <- 0.04 * avg_body_weight * (2 - diet_digestibility)  # kg VS/day
  } else {  # Young cattle
    vs_excretion <- 0.05 * avg_body_weight * (2 - diet_digestibility)
  }

  # Step 2: Maximum methane producing capacity (B0)
  # Depends on diet quality
  if (diet_digestibility > 0.70) {
    b0 <- 0.20  # High quality diet (concentrates)
  } else if (diet_digestibility > 0.60) {
    b0 <- 0.18  # Medium quality diet
  } else {
    b0 <- 0.15  # Low quality diet (poor forages)
  }

  # Step 3: Methane Conversion Factor (MCF) by system and climate
  mcf_table <- list(
    pasture = list(
      cold = 1.0,      # <15°C average
      temperate = 1.5, # 15-25°C average
      warm = 2.0       # >25°C average
    ),
    solid_storage = list(
      cold = 2.0,
      temperate = 3.5,
      warm = 5.5
    ),
    liquid_storage = list(
      cold = 17,       # Shallow lagoons/pits
      temperate = 39,  # Moderate conditions
      warm = 65        # Tropical lagoons
    ),
    anaerobic_digester = list(
      cold = 20,       # Unheated digesters
      temperate = 75,  # Heated digesters
      warm = 85        # Optimized digesters
    )
  )

  mcf <- mcf_table[[manure_system]][[climate]] / 100  # Convert % to fraction

  # Adjust MCF based on specific temperature if provided
  if (!is.null(system_temperature)) {
    temp_adjustment <- ifelse(system_temperature < 15, 0.8,
                              ifelse(system_temperature > 25, 1.2, 1.0))
    mcf <- mcf * temp_adjustment
  }

  # Adjust MCF based on retention time if provided
  if (!is.null(retention_days) && manure_system != "pasture") {
    if (retention_days < 30) {
      mcf <- mcf * 0.7  # Short retention reduces conversion
    } else if (retention_days > 120) {
      mcf <- mcf * 1.1  # Long retention increases conversion
    }
  }

  # Step 4: Calculate CH4
  # CH4 = VS × B0 × MCF × 0.67 (CH4 density) × 365 days
  ch4_m3_per_cow_year <- vs_excretion * b0 * mcf * 365
  ch4_kg_per_cow_year <- ch4_m3_per_cow_year * 0.67  # m³ to kg

  total_ch4_kg <- n_cows * ch4_kg_per_cow_year

  return(list(
    ch4_kg_total = total_ch4_kg,
    ch4_kg_per_cow = ch4_kg_per_cow_year,
    vs_kg_per_day = vs_excretion,
    b0_used = b0,
    mcf_used = mcf * 100,  # Report as percentage
    methodology = "IPCC Tier 2"
  ))
}

# ============================================================================
# HELPER FUNCTION: N2O CALCULATION (BOTH TIERS)
# ============================================================================

calc_n2o_emissions <- function(n_cows, n_excreted, ef_n2o_direct,
                               include_indirect, protein_intake_kg = NULL,
                               tier2_enhancement = FALSE) {

  # Enhanced N excretion calculation for Tier 2 or when protein intake is available
  if (!is.null(protein_intake_kg) && (tier2_enhancement || !is.null(protein_intake_kg))) {
    # Calculate N excretion from protein intake
    n_in_protein <- protein_intake_kg / 6.25  # N content in protein
    n_retention_milk <- 0.25  # ~25% retained for milk production
    n_excreted_calculated <- n_in_protein * (1 - n_retention_milk) * 365  # kg N/cow/year
    n_excreted_used <- n_excreted_calculated
  } else {
    n_excreted_used <- n_excreted
  }

  # Direct N2O emissions (N2O-N to N2O conversion factor = 44/28)
  n2o_direct <- n_cows * n_excreted_used * ef_n2o_direct * (44/28)

  # Indirect N2O emissions
  n2o_indirect <- 0
  if (include_indirect) {
    # IPCC 2019 factors for indirect emissions
    frac_vol <- 0.20     # Fraction of N that volatilizes (NH3 + NOx)
    ef_vol <- 0.01       # EF for atmospheric deposition of volatilized N
    frac_leach <- 0.30   # Fraction of N that leaches/runs off
    ef_leach <- 0.0075   # EF for leaching and runoff

    # Enhanced factors for Tier 2
    if (tier2_enhancement) {
      frac_vol <- 0.18     # More conservative volatilization
      frac_leach <- 0.25   # More conservative leaching
    }

    n2o_indirect <- n_cows * n_excreted_used *
      ((frac_vol * ef_vol) + (frac_leach * ef_leach)) * (44/28)
  }

  return(list(
    n2o_direct = n2o_direct,
    n2o_indirect = n2o_indirect,
    n_excreted_used = n_excreted_used
  ))
}

# ============================================================================
# USAGE EXAMPLES
# ============================================================================

# Example 1: Basic Tier 1 calculation
# result1 <- calc_emissions_manure(n_cows = 100, manure_system = "liquid_storage")

# Example 2: Tier 1 with indirect emissions
# result2 <- calc_emissions_manure(n_cows = 100, manure_system = "solid_storage",
#                                  include_indirect = TRUE)

# Example 3: Tier 2 calculation
# result3 <- calc_emissions_manure(n_cows = 100, manure_system = "liquid_storage",
#                                  tier = 2, avg_body_weight = 580,
#                                  diet_digestibility = 0.68, climate = "temperate",
#                                  protein_intake_kg = 3.2, include_indirect = TRUE)

# Example 4: Tier 2 with system-specific parameters
# result4 <- calc_emissions_manure(n_cows = 100, manure_system = "anaerobic_digester",
#                                  tier = 2, avg_body_weight = 600,
#                                  diet_digestibility = 0.72, climate = "temperate",
#                                  retention_days = 45, system_temperature = 35,
#                                  include_indirect = TRUE)
