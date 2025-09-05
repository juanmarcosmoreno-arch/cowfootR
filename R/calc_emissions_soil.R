#' Calculate soil N2O emissions
#'
#' Estimates direct and indirect N2O emissions from soils due to
#' fertilization, excreta deposition, and crop residues using IPCC methodology.
#'
#' IMPORTANT: When system boundaries exclude soil, this function must return
#'   a list with `source = "soil"` and `co2eq_kg = 0` (numeric zero) to match
#'   the partial-boundaries integration tests.
#'
#' @param n_fertilizer_synthetic Numeric. Synthetic nitrogen fertilizer applied (kg N/year).
#'   Default = 0.
#' @param n_fertilizer_organic Numeric. Organic nitrogen fertilizer applied (kg N/year).
#'   Default = 0.
#' @param n_excreta_pasture Numeric. Nitrogen excreted directly on pasture (kg N/year).
#'   Default = 0.
#' @param n_crop_residues Numeric. Nitrogen in crop residues returned to soil (kg N/year).
#'   Default = 0.
#' @param area_ha Numeric. Total farm area (hectares). Used for per-hectare metrics. Optional.
#' @param soil_type Character. Soil drainage: "well_drained" or "poorly_drained".
#'   Default = "well_drained".
#' @param climate Character. Climate: "temperate" or "tropical". Default = "temperate".
#' @param ef_direct Numeric. Direct EF for N2O-N (kg N2O-N per kg N input).
#'   If NULL, uses IPCC 2019 values based on soil type and climate.
#' @param include_indirect Logical. Include indirect N2O from volatilization and leaching?
#'   Default = TRUE.
#' @param gwp_n2o Numeric. GWP of N2O. Default = 273 (IPCC AR6).
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'   If soil is excluded, returns \code{co2eq_kg = 0}.
#'
#' @return A list with at least \code{source="soil"} and \code{co2eq_kg} (numeric),
#'   plus detailed breakdown metadata when included by boundaries.
#' @export
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

  # --------------------------
  # Validation & boundary gate
  # --------------------------
  valid_soils <- c("well_drained", "poorly_drained")
  valid_climates <- c("temperate", "tropical")

  if (!soil_type %in% valid_soils) {
    stop("Invalid soil_type. Use: ", paste(valid_soils, collapse = ", "))
  }
  if (!climate %in% valid_climates) {
    stop("Invalid climate. Use: ", paste(valid_climates, collapse = ", "))
  }
  if (any(c(n_fertilizer_synthetic, n_fertilizer_organic,
            n_excreta_pasture, n_crop_residues) < 0)) {
    stop("All nitrogen inputs must be non-negative.")
  }

  # Boundary exclusion: soil is excluded when 'include' is present and does not contain "soil".
  soil_excluded <- is.list(boundaries) &&
    !is.null(boundaries$include) &&
    !"soil" %in% boundaries$include

  if (soil_excluded) {
    # Test expects numeric 0 (not NULL) when soil is excluded.
    return(list(
      source        = "soil",
      co2eq_kg      = 0,
      methodology   = "excluded_by_boundaries",
      emissions_breakdown = NULL,
      nitrogen_inputs     = NULL,
      date = Sys.Date()
    ))
  }

  # Keep original arg to label factor provenance later
  ef_direct_arg <- ef_direct

  # ------------------------------------
  # Emission factors (IPCC defaults T1)
  # ------------------------------------
  if (is.null(ef_direct)) {
    # IPCC 2019 direct EF for N2O-N (kg N2O-N per kg N input)
    direct_factors <- list(
      temperate = list(
        well_drained   = 0.01,
        poorly_drained = 0.015
      ),
      tropical = list(
        well_drained   = 0.012,
        poorly_drained = 0.018
      )
    )
    ef_direct <- direct_factors[[climate]][[soil_type]]
  } else {
    if (!is.numeric(ef_direct) || length(ef_direct) != 1L) {
      stop("ef_direct must be a single numeric value.")
    }
    if (ef_direct < 0 || ef_direct > 0.05) {
      warning("ef_direct seems unusual (typical range is ~0.005 to 0.02).")
    }
  }

  # -------------------------
  # Activity data & pathways
  # -------------------------
  total_n_input <- n_fertilizer_synthetic + n_fertilizer_organic +
    n_excreta_pasture + n_crop_residues

  # Direct N2O (convert N2O-N to N2O using 44/28)
  n2o_direct <- total_n_input * ef_direct * (44/28)

  # Predefine indirect terms to avoid undefined variables if include_indirect = FALSE
  n2o_volatilization <- 0
  n2o_leaching <- 0
  n2o_indirect <- 0
  ef_vol <- NA_real_
  ef_leach <- NA_real_

  if (isTRUE(include_indirect)) {
    # IPCC 2019 typical Tier 1 fractions/Efs for indirect pathways
    # Volatilization (NH3 + NOx)
    frac_vol_synthetic <- 0.10
    frac_vol_organic   <- 0.20
    frac_vol_excreta   <- 0.20
    ef_vol             <- 0.01

    n_vol <- (n_fertilizer_synthetic * frac_vol_synthetic) +
      (n_fertilizer_organic   * frac_vol_organic)   +
      (n_excreta_pasture      * frac_vol_excreta)
    n2o_volatilization <- n_vol * ef_vol * (44/28)

    # Leaching/runoff (NO3-)
    frac_leach <- 0.30
    ef_leach   <- 0.0075

    n_leach <- total_n_input * frac_leach
    n2o_leaching <- n_leach * ef_leach * (44/28)

    n2o_indirect <- n2o_volatilization + n2o_leaching
  }

  # Totals
  n2o_total   <- n2o_direct + n2o_indirect
  co2eq_total <- n2o_total * gwp_n2o

  # -------------------------
  # Build result object
  # -------------------------
  result <- list(
    source = "soil",

    soil_conditions = list(
      soil_type = soil_type,
      climate   = climate
    ),

    nitrogen_inputs = list(
      synthetic_fertilizer_kg_n = n_fertilizer_synthetic,
      organic_fertilizer_kg_n   = n_fertilizer_organic,
      excreta_pasture_kg_n      = n_excreta_pasture,
      crop_residues_kg_n        = n_crop_residues,
      total_kg_n                = total_n_input
    ),

    emissions_breakdown = list(
      direct_n2o_kg                  = round(n2o_direct, 3),
      indirect_volatilization_n2o_kg = if (isTRUE(include_indirect)) round(n2o_volatilization, 3) else 0,
      indirect_leaching_n2o_kg       = if (isTRUE(include_indirect)) round(n2o_leaching, 3) else 0,
      total_indirect_n2o_kg          = round(n2o_indirect, 3),
      total_n2o_kg                   = round(n2o_total, 3)
    ),

    # Primary field used by tests
    co2eq_kg = round(co2eq_total, 2),

    emission_factors = list(
      ef_direct         = ef_direct,
      ef_volatilization = ef_vol,
      ef_leaching       = ef_leach,
      gwp_n2o           = gwp_n2o,
      factors_source    = if (is.null(ef_direct_arg))
        paste0("IPCC 2019 (", climate, ", ", soil_type, ")") else "User-provided"
    ),

    methodology = if (isTRUE(include_indirect))
      "IPCC 2019 Tier 1 (direct + indirect)"
    else
      "IPCC 2019 Tier 1 (direct only)",

    standards = "IPCC 2019 Refinement, IDF 2022",
    date = Sys.Date()
  )

  # Per-hectare metrics (optional)
  if (!is.null(area_ha) && is.finite(as.numeric(area_ha)) && as.numeric(area_ha) > 0) {
    area_ha <- as.numeric(area_ha)
    result$per_hectare_metrics <- list(
      n_input_kg_per_ha                    = round(total_n_input / area_ha, 1),
      n2o_kg_per_ha                        = round(n2o_total / area_ha, 3),
      co2eq_kg_per_ha                      = round(co2eq_total / area_ha, 2),
      emission_intensity_kg_co2eq_per_kg_n = if (total_n_input > 0)
        round(co2eq_total / total_n_input, 2) else NA_real_
    )
  }

  # Contribution breakdown (only if there is N input)
  if (total_n_input > 0) {
    result$source_contributions <- list(
      synthetic_fertilizer_pct = round(n_fertilizer_synthetic / total_n_input * 100, 1),
      organic_fertilizer_pct   = round(n_fertilizer_organic   / total_n_input * 100, 1),
      excreta_pasture_pct      = round(n_excreta_pasture      / total_n_input * 100, 1),
      crop_residues_pct        = round(n_crop_residues        / total_n_input * 100, 1),
      direct_emissions_pct     = round(ifelse(n2o_total > 0, n2o_direct   / n2o_total * 100, 0), 1),
      indirect_emissions_pct   = round(ifelse(n2o_total > 0, n2o_indirect / n2o_total * 100, 0), 1)
    )
  }

  return(result)
}
