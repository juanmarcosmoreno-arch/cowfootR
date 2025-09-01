#' Calculate carbon footprint intensity per litre of milk
#'
#' Computes emissions intensity as kg CO2eq per kg of fat- and protein-corrected milk (FPCM/LCGP).
#'
#' @param total_emissions Numeric. Total emissions in kg CO2eq (from \code{calc_total_emissions()}).
#' @param milk_litres Numeric. Milk produced in litres per year.
#' @param fat Numeric. Average fat percentage of milk. Default = 4.
#' @param protein Numeric. Average protein percentage of milk. Default = 3.3.
#'
#' @details The correction to FPCM (fat- and protein-corrected milk) follows the IDF formula:
#'   \deqn{FPCM = milk_litres * (0.1226 * fat + 0.0776 * protein + 0.2534)}
#'
#' @return Numeric. Emissions intensity (kg CO2eq/kg FPCM).
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' e1 <- calc_emissions_entero(100, boundaries = b)
#' e2 <- calc_emissions_manure(100, boundaries = b)
#' tot <- calc_total_emissions(e1, e2)
#' calc_intensity_litre(tot$total_co2eq, milk_litres = 750000)
calc_intensity_litre <- function(total_emissions,
                                 milk_litres,
                                 fat = 4,
                                 protein = 3.3) {

  # Convert milk to fat- and protein-corrected milk (FPCM)
  fpcm <- milk_litres * (0.1226 * fat + 0.0776 * protein + 0.2534)

  if (fpcm <= 0) {
    stop("Milk production (FPCM) must be > 0")
  }

  # Intensity (kg CO2eq per kg FPCM)
  intensity <- total_emissions / fpcm

  return(intensity)
}
