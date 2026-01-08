#' Calculate manure management emissions (Tier 1 & Tier 2)
#'
#' Estimates CH4 and N2O emissions from manure management using IPCC Tier 1
#' or Tier 2 methodology with practical settings for dairy systems.
#'
#' @param n_cows Numeric scalar > 0. Number of dairy cows.
#' @param manure_system Character. One of "pasture", "solid_storage",
#'   "liquid_storage", "anaerobic_digester". Default = "pasture".
#' @param tier Integer. IPCC tier (1 or 2). Default = 1.
#' @param ef_ch4 Numeric. CH4 EF (kg CH4/cow/year). If `NULL`, system-specific
#'   defaults are used (Tier 1 only).
#' @param n_excreted Numeric. N excreted per cow per year (kg N). Default = 100.
#'   In Tier 2 it may be recalculated if protein intake is provided.
#' @param ef_n2o_direct Numeric. Direct N2O-N EF (kg N2O-N per kg N). Default = 0.02.
#' @param include_indirect Logical. Include indirect N2O (volatilization + leaching)?
#'   Default = FALSE.
#' @param climate Character. One of "cold", "temperate", "warm". Default = "temperate" (Tier 2).
#' @param avg_body_weight Numeric. Average live weight (kg). Default = 600 (Tier 2).
#' @param diet_digestibility Numeric in (0, 1]. Apparent digestibility. Default = 0.65 (Tier 2).
#' @param protein_intake_kg Numeric. Daily protein intake (kg/day). If provided,
#'   Tier 2 can refine N excretion.
#' @param retention_days Numeric. Days manure remains in system (Tier 2 adjustment).
#' @param system_temperature Numeric. Average system temperature (Tier 2 adjustment).
#' @param gwp_ch4 Numeric. GWP for CH4 (AR6). Default = 27.2.
#' @param gwp_n2o Numeric. GWP for N2O (AR6). Default = 273.
#' @param boundaries Optional list from \code{set_system_boundaries()}.
#'
#' @return A list with CH4 (kg), N2O (kg), CO2eq (kg), metadata, and per-cow metrics.
#'   The returned object includes a \code{co2eq_kg} field compatible with
#'   \code{calc_total_emissions()}.
#' @export
#'
#' @examples
#' \donttest{
#' # Tier 1, liquid storage
#' calc_emissions_manure(n_cows = 120, manure_system = "liquid_storage")
#'
#' # Tier 1 with indirect N2O
#' calc_emissions_manure(n_cows = 120, manure_system = "solid_storage", include_indirect = TRUE)
#'
#' # Tier 2 (VS_B0_MCF approach) with refinements
#' calc_emissions_manure(
#'   n_cows = 100, manure_system = "liquid_storage", tier = 2,
#'   avg_body_weight = 580, diet_digestibility = 0.68, climate = "temperate",
#'   protein_intake_kg = 3.2, include_indirect = TRUE
#' )
#' }
calc_emissions_manure <- function(n_cows,
                                  manure_system = "pasture",
                                  tier = 1L,
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
  # ----------------------------- Validation ----------------------------------
  valid_systems <- c("pasture", "solid_storage", "liquid_storage", "anaerobic_digester")
  valid_climates <- c("cold", "temperate", "warm")
  valid_tiers <- c(1L, 2L)

  if (!is.finite(n_cows) || length(n_cows) != 1L || n_cows <= 0) {
    stop("n_cows must be a single positive number")
  }
  if (!is.character(manure_system) || !(manure_system %in% valid_systems)) {
    stop("Invalid manure_system. Use: ", paste(valid_systems, collapse = ", "))
  }
  if (!is.numeric(tier) || !(as.integer(tier) %in% valid_tiers)) {
    stop("Invalid tier. Use 1 or 2.")
  }
  tier <- as.integer(tier)
  if (!is.character(climate) || !(climate %in% valid_climates)) {
    stop("Invalid climate. Use: ", paste(valid_climates, collapse = ", "))
  }
  if (!is.finite(n_excreted) || n_excreted < 0) {
    stop("n_excreted must be non-negative")
  }
  if (!is.finite(ef_n2o_direct) || ef_n2o_direct < 0) {
    stop("ef_n2o_direct must be non-negative")
  }
  if (!is.finite(diet_digestibility) || diet_digestibility <= 0 || diet_digestibility > 1) {
    stop("diet_digestibility must be in (0, 1]")
  }

  # Boundary-based exclusion (clean signal for calc_total_emissions())
  if (is.list(boundaries) && !is.null(boundaries$include) &&
    !("manure" %in% boundaries$include)) {
    return(list(
      source = "manure",
      system = manure_system,
      tier = tier,
      co2eq_kg = 0, # explicit exclusion
      methodology = "excluded_by_boundaries",
      excluded = TRUE
    ))
  }

  # ----------------------------- Tier 1 --------------------------------------
  if (tier == 1L) {
    # Default CH4 EFs (kg CH4/cow/year) if not provided
    if (is.null(ef_ch4)) {
      ch4_factors <- list(
        pasture            = 1.5, # grazing/minimal storage
        solid_storage      = 20, # typical solid storage
        liquid_storage     = 30, # liquid lagoons/pits
        anaerobic_digester = 10 # controlled anaerobic
      )
      ef_ch4 <- ch4_factors[[manure_system]]
    } else {
      if (!is.finite(ef_ch4) || ef_ch4 < 0) stop("ef_ch4 must be non-negative")
    }

    # CH4 emissions
    ch4 <- n_cows * ef_ch4

    # N2O emissions (common helper for both tiers)
    n2o_results <- calc_n2o_emissions(
      n_cows = n_cows,
      n_excreted = n_excreted,
      ef_n2o_direct = ef_n2o_direct,
      include_indirect = include_indirect,
      protein_intake_kg = protein_intake_kg
    )

    methodology_note <- "IPCC Tier 1 (default emission factors)"
  } else {
    # --------------------------- Tier 2 --------------------------------------
    # CH4 via VS_B0_MCF approach with temperature/retention adjustments
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

    # N2O with optional Tier 2 enhancements (refined N excretion)
    n2o_results <- calc_n2o_emissions(
      n_cows = n_cows,
      n_excreted = n_excreted,
      ef_n2o_direct = ef_n2o_direct,
      include_indirect = include_indirect,
      protein_intake_kg = protein_intake_kg,
      tier2_enhancement = TRUE
    )

    methodology_note <- "IPCC Tier 2 (VS_B0_MCF calculation)"
  }

  # --------------------------- Aggregation -----------------------------------
  n2o_total <- n2o_results$n2o_direct + n2o_results$n2o_indirect
  co2eq <- ch4 * gwp_ch4 + n2o_total * gwp_n2o

  # --------------------------- Result object ---------------------------------
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
      ef_ch4 = if (tier == 1L) ef_ch4 else NA_real_,
      ef_n2o_direct = ef_n2o_direct,
      gwp_ch4 = gwp_ch4,
      gwp_n2o = gwp_n2o
    ),

    # Inputs (record for reproducibility)
    inputs = list(
      n_cows = n_cows,
      n_excreted = n2o_results$n_excreted_used,
      manure_system = manure_system,
      include_indirect = include_indirect,
      avg_body_weight = if (tier == 2L) avg_body_weight else NA_real_,
      diet_digestibility = if (tier == 2L) diet_digestibility else NA_real_
    ),

    # Methodology meta
    methodology = methodology_note,
    standards = "IPCC 2019 Refinement, IDF 2022",
    date = Sys.Date(),

    # Per-cow metrics
    per_cow = list(
      ch4_kg = round(ch4 / n_cows, 4),
      n2o_kg = round(n2o_total / n_cows, 6),
      co2eq_kg = round(co2eq / n_cows, 4)
    )
  )

  # Add Tier 2 details for transparency
  if (tier == 2L) {
    result$tier2_details <- ch4_results[c("vs_kg_per_day", "b0_used", "mcf_used")]
  }

  return(result)
}

# --------------------------- Helper: Tier 2 CH4 ------------------------------

# Computes CH4 using VS_B0_MCF, with optional adjustments for system temperature
# and retention time.
calc_ch4_tier2 <- function(n_cows, avg_body_weight, diet_digestibility,
                           manure_system, climate, retention_days = NULL,
                           system_temperature = NULL) {
  # Step 1: Volatile Solids (VS) excretion (simple IPCC-style approximation)
  # Adults vs. young cattle differentiation
  if (avg_body_weight > 200) {
    vs_excretion <- 0.04 * avg_body_weight * (2 - diet_digestibility) # kg VS/day
  } else {
    vs_excretion <- 0.05 * avg_body_weight * (2 - diet_digestibility)
  }

  # Step 2: Maximum methane producing capacity (B0), fraction of VS to CH4
  if (diet_digestibility > 0.70) {
    b0 <- 0.20
  } else if (diet_digestibility > 0.60) {
    b0 <- 0.18
  } else {
    b0 <- 0.15
  }

  # Step 3: Methane Conversion Factor (MCF) by system & climate (in % fraction)
  mcf_table <- list(
    pasture = list(cold = 1.0, temperate = 1.5, warm = 2.0),
    solid_storage = list(cold = 2.0, temperate = 3.5, warm = 5.5),
    liquid_storage = list(cold = 17, temperate = 39, warm = 65),
    anaerobic_digester = list(cold = 20, temperate = 75, warm = 85)
  )
  mcf <- mcf_table[[manure_system]][[climate]] / 100

  # Temperature adjustment (simple elasticities)
  if (!is.null(system_temperature)) {
    temp_adj <- ifelse(system_temperature < 15, 0.8,
      ifelse(system_temperature > 25, 1.2, 1.0)
    )
    mcf <- mcf * temp_adj
  }

  # Retention time adjustment (simple thresholds, not for pasture)
  if (!is.null(retention_days) && manure_system != "pasture") {
    if (retention_days < 30) {
      mcf <- mcf * 0.7
    } else if (retention_days > 120) {
      mcf <- mcf * 1.1
    }
  }

  # Step 4: CH4 (convert cow-level daily to annual total)
  ch4_kg_per_cow_year <- vs_excretion * b0 * mcf * 365 * 0.67 # 0.67 ~ kg CH4 per m^3 proxy

  total_ch4_kg <- n_cows * ch4_kg_per_cow_year

  list(
    ch4_kg_total = total_ch4_kg,
    ch4_kg_per_cow = ch4_kg_per_cow_year,
    vs_kg_per_day = vs_excretion,
    b0_used = b0,
    mcf_used = mcf * 100, # report as %
    methodology = "IPCC Tier 2"
  )
}

# --------------------------- Helper: N2O (both tiers) ------------------------

# Computes direct and indirect N2O. If Tier 2 enhancement is requested and
# protein intake is available, N excretion may be refined from protein intake.
calc_n2o_emissions <- function(n_cows, n_excreted, ef_n2o_direct,
                               include_indirect, protein_intake_kg = NULL,
                               tier2_enhancement = FALSE) {
  # Optional Tier 2 refinement of N excretion from protein intake
  if (!is.null(protein_intake_kg) && (tier2_enhancement || !is.null(protein_intake_kg))) {
    n_in_protein <- protein_intake_kg / 6.25 # crude protein N
    n_retention_milk <- 0.25 # assumed retained fraction for milk
    n_excreted_used <- n_in_protein * (1 - n_retention_milk) * 365
  } else {
    n_excreted_used <- n_excreted
  }

  # Direct N2O (convert N2O-N to N2O with 44/28)
  n2o_direct <- n_cows * n_excreted_used * ef_n2o_direct * (44 / 28)

  # Indirect N2O via volatilization and leaching (very simple IPCC-style factors)
  n2o_indirect <- 0
  if (isTRUE(include_indirect)) {
    frac_vol <- 0.20 # volatilized fraction of N
    ef_vol <- 0.01 # EF for deposition of volatilized N
    frac_leach <- 0.30
    ef_leach <- 0.0075

    # Slightly more conservative in Tier 2 mode
    if (isTRUE(tier2_enhancement)) {
      frac_vol <- 0.18
      frac_leach <- 0.25
    }

    n2o_indirect <- n_cows * n_excreted_used * ((frac_vol * ef_vol) + (frac_leach * ef_leach)) * (44 / 28)
  }

  list(
    n2o_direct = n2o_direct,
    n2o_indirect = n2o_indirect,
    n_excreted_used = n_excreted_used
  )
}
