#' Calculate energy-related emissions
#'
#' Estimates CO2 emissions from fossil fuel use and electricity consumption.
#'
#' @param diesel_l Numeric. Diesel consumption (liters/year).
#'   Default = 0.
#' @param petrol_l Numeric. Petrol/gasoline consumption (liters/year).
#'   Default = 0.
#' @param electricity_kwh Numeric. Electricity consumption (kWh/year).
#'   Default = 0.
#' @param ef_diesel Numeric. Emission factor for diesel (kg CO2/liter).
#'   Default = 2.68 (IPCC).
#' @param ef_petrol Numeric. Emission factor for petrol (kg CO2/liter).
#'   Default = 2.31 (IPCC).
#' @param ef_elec Numeric. Emission factor for electricity (kg CO2/kWh).
#'   Default = 0.05 (Uruguay average, adjust for context).
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'   If "energy" is not included, returns 0.
#'
#' @return A list with emissions (kg CO2eq) by source and total.
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' calc_emissions_energy(diesel_l = 2000, electricity_kwh = 5000, boundaries = b)
calc_emissions_energy <- function(diesel_l = 0,
                                  petrol_l = 0,
                                  electricity_kwh = 0,
                                  ef_diesel = 2.68,
                                  ef_petrol = 2.31,
                                  ef_elec = 0.05,
                                  boundaries = NULL) {

  # Exclude if boundaries do not include "energy"
  if (!is.null(boundaries) && !"energy" %in% boundaries$include) {
    return(list(
      source = "energy",
      diesel_co2 = 0,
      petrol_co2 = 0,
      elec_co2 = 0,
      co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # Calculate emissions
  diesel_co2 <- diesel_l * ef_diesel
  petrol_co2 <- petrol_l * ef_petrol
  elec_co2   <- electricity_kwh * ef_elec

  total <- diesel_co2 + petrol_co2 + elec_co2

  list(
    source = "energy",
    diesel_co2 = diesel_co2,
    petrol_co2 = petrol_co2,
    elec_co2 = elec_co2,
    co2eq_kg = total,
    ef_diesel_used = ef_diesel,
    ef_petrol_used = ef_petrol,
    ef_elec_used = ef_elec,
    date = Sys.Date()
  )
}
