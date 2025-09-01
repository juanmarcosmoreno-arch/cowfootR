#' Calculate indirect emissions from purchased inputs
#'
#' Estimates CO2eq emissions from purchased inputs such as
#' concentrates, fertilizers, and plastics.
#'
#' @param conc_kg Numeric. Purchased concentrate feed (kg/year).
#'   Default = 0.
#' @param fert_n_kg Numeric. Purchased nitrogen fertilizer (kg N/year).
#'   Default = 0.
#' @param plastic_kg Numeric. Agricultural plastics used (kg/year).
#'   Default = 0.
#' @param ef_conc Numeric. Emission factor for concentrate feed (kg CO2eq/kg).
#'   Default = 0.7.
#' @param ef_fert Numeric. Emission factor for nitrogen fertilizer production (kg CO2eq/kg N).
#'   Default = 6.6.
#' @param ef_plastic Numeric. Emission factor for plastic (kg CO2eq/kg).
#'   Default = 2.5.
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'   If "inputs" is not included, returns 0.
#'
#' @return A list with emissions (kg CO2eq) by input and total.
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' calc_emissions_inputs(conc_kg = 1000, fert_n_kg = 500, boundaries = b)
calc_emissions_inputs <- function(conc_kg = 0,
                                  fert_n_kg = 0,
                                  plastic_kg = 0,
                                  ef_conc = 0.7,
                                  ef_fert = 6.6,
                                  ef_plastic = 2.5,
                                  boundaries = NULL) {

  # Exclude if boundaries do not include "inputs"
  if (!is.null(boundaries) && !"inputs" %in% boundaries$include) {
    return(list(
      source = "inputs",
      conc_co2 = 0,
      fert_co2 = 0,
      plastic_co2 = 0,
      co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # Calculate emissions
  conc_co2 <- conc_kg * ef_conc
  fert_co2 <- fert_n_kg * ef_fert
  plastic_co2 <- plastic_kg * ef_plastic

  total <- conc_co2 + fert_co2 + plastic_co2

  list(
    source = "inputs",
    conc_co2 = conc_co2,
    fert_co2 = fert_co2,
    plastic_co2 = plastic_co2,
    co2eq_kg = total,
    ef_conc_used = ef_conc,
    ef_fert_used = ef_fert,
    ef_plastic_used = ef_plastic,
    date = Sys.Date()
  )
}
