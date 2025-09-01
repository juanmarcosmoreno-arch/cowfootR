#' Calculate soil emissions (N2O)
#'
#' Estimates direct N2O emissions from soils due to
#' fertilization and excreta deposition, using IPCC Tier 1 methodology.
#'
#' @param n_fert Numeric. Nitrogen applied as fertilizer (kg N/year).
#' @param n_excreta Numeric. Nitrogen excreted on pasture (kg N/year).
#'   Default = 5000 (rough estimate for dairy herds).
#' @param ef_n2o Numeric. Emission factor for N2O-N (kg N2O-N/kg N input).
#'   Default = 0.01 (IPCC Tier 1).
#' @param gwp_n2o Numeric. Global Warming Potential of N2O.
#'   Default = 265 (100-year horizon).
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'   If "soil" is not included, returns 0.
#'
#' @return A list with N2O emissions (kg), CO2eq (kg), and metadata.
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' calc_emissions_soil(1500, 5000, boundaries = b)
calc_emissions_soil <- function(n_fert,
                                n_excreta = 5000,
                                ef_n2o = 0.01,
                                gwp_n2o = 265,
                                boundaries = NULL) {

  # Exclude if boundaries do not include "soil"
  if (!is.null(boundaries) && !"soil" %in% boundaries$include) {
    return(list(
      source = "soil",
      n2o_kg = 0,
      co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # N2O (kg) = (N_fert + N_excreta) * EF * 44/28
  n2o <- (n_fert + n_excreta) * ef_n2o * (44/28)

  # Convert to CO2eq
  co2eq <- n2o * gwp_n2o

  list(
    source = "soil",
    n2o_kg = n2o,
    co2eq_kg = co2eq,
    ef_n2o_used = ef_n2o,
    gwp_n2o_used = gwp_n2o,
    date = Sys.Date()
  )
}
