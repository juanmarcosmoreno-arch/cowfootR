#' Calculate enteric methane emissions
#'
#' Estimates enteric methane (CH4) emissions from dairy cattle
#' using the IPCC Tier 1 methodology.
#'
#' @param n_cows Numeric. Number of dairy cows.
#' @param ef_ch4 Numeric. Emission factor (kg CH4 per cow per year).
#'   Default = 118 (IPCC Tier 1, dairy cattle in Latin America).
#' @param gwp Numeric. Global Warming Potential of CH4.
#'   Default = 28 (100-year horizon, IPCC AR5).
#' @param boundaries Optional. An object returned by \code{set_system_boundaries()}.
#'   If "entero" is not included in the system boundaries, the function returns 0.
#'
#' @return A list with:
#'   \item{source}{Emission source ("entero").}
#'   \item{ch4_kg}{CH4 emissions in kg/year.}
#'   \item{co2eq_kg}{Emissions in CO2 equivalent (kg/year).}
#'   \item{ef_used}{Emission factor used.}
#'   \item{gwp_used}{Global Warming Potential used.}
#'   \item{date}{Date of calculation.}
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' calc_emissions_entero(100, boundaries = b)
calc_emissions_entero <- function(n_cows,
                                  ef_ch4 = 118,
                                  gwp = 28,
                                  boundaries = NULL) {

  # Exclude if boundaries do not include "entero"
  if (!is.null(boundaries) && !"entero" %in% boundaries$include) {
    return(list(
      source = "entero",
      ch4_kg = 0,
      co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # Calculate emissions
  ch4 <- n_cows * ef_ch4
  co2eq <- ch4 * gwp

  # Return result as list
  list(
    source = "entero",
    ch4_kg = ch4,
    co2eq_kg = co2eq,
    ef_used = ef_ch4,
    gwp_used = gwp,
    date = Sys.Date()
  )
}
