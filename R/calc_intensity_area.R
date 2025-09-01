#' Calculate carbon footprint intensity per hectare
#'
#' Computes emissions intensity as kg CO2eq per hectare of utilized land.
#'
#' @param total_emissions Numeric. Total emissions in kg CO2eq (from \code{calc_total_emissions()}).
#' @param area_ha Numeric. Total land area in hectares used by the dairy farm.
#'
#' @return Numeric. Emissions intensity (kg CO2eq/ha).
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' e1 <- calc_emissions_entero(100, boundaries = b)
#' e2 <- calc_emissions_manure(100, boundaries = b)
#' tot <- calc_total_emissions(e1, e2)
#' calc_intensity_area(tot$total_co2eq, area_ha = 120)
calc_intensity_area <- function(total_emissions,
                                area_ha) {

  if (area_ha <= 0) {
    stop("Area (ha) must be > 0")
  }

  # Intensity (kg CO2eq per hectare)
  intensity <- total_emissions / area_ha

  return(intensity)
}
