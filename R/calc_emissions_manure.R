#' Calculate manure management emissions
#'
#' Estimates CH4 and N2O emissions from manure management
#' using IPCC Tier 1 methodology.
#'
#' @param n_cows Numeric. Number of dairy cows.
#' @param ef_ch4 Numeric. Emission factor for CH4 (kg CH4 per cow per year).
#'   Default = 2 (IPCC Tier 1, dairy cattle in pasture-based systems).
#' @param n_excreted Numeric. Nitrogen excreted per cow per year (kg N).
#'   Default = 100 (approximate, can be refined by diet).
#' @param ef_n2o Numeric. Emission factor for N2O-N (kg N2O-N/kg N excreted).
#'   Default = 0.01 (IPCC Tier 1).
#' @param gwp_ch4 Numeric. Global Warming Potential of CH4. Default = 28.
#' @param gwp_n2o Numeric. Global Warming Potential of N2O. Default = 265.
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'   If "manure" is not included, returns 0.
#'
#' @return A list with CH4 (kg), N2O (kg), CO2eq (kg), and metadata.
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' calc_emissions_manure(100, boundaries = b)
calc_emissions_manure <- function(n_cows,
                                  ef_ch4 = 2,
                                  n_excreted = 100,
                                  ef_n2o = 0.01,
                                  gwp_ch4 = 28,
                                  gwp_n2o = 265,
                                  boundaries = NULL) {

  # Exclude if boundaries do not include "manure"
  if (!is.null(boundaries) && !"manure" %in% boundaries$include) {
    return(list(
      source = "manure",
      ch4_kg = 0,
      n2o_kg = 0,
      co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # CH4 from manure
  ch4 <- n_cows * ef_ch4

  # N2O from manure (N2O-N -> N2O conversion factor = 44/28)
  n2o <- n_cows * n_excreted * ef_n2o * (44/28)

  # Convert to CO2eq
  co2eq <- ch4 * gwp_ch4 + n2o * gwp_n2o

  list(
    source = "manure",
    ch4_kg = ch4,
    n2o_kg = n2o,
    co2eq_kg = co2eq,
    ef_ch4_used = ef_ch4,
    ef_n2o_used = ef_n2o,
    gwp_ch4_used = gwp_ch4,
    gwp_n2o_used = gwp_n2o,
    date = Sys.Date()
  )
}
