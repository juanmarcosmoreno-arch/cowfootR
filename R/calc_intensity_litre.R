#' Calculate carbon footprint intensity per kg of milk
#'
#' Computes emissions intensity as kg CO2eq per kg of fat- and protein-corrected milk (FPCM).
#'
#' @param total_emissions Numeric or cf_total object. Total emissions in kg CO2eq
#'   (from \code{calc_total_emissions()}) or the object itself.
#' @param milk_litres Numeric. Annual milk production in litres.
#' @param fat Numeric. Average fat percentage of milk (0-100). Default = 4.
#' @param protein Numeric. Average protein percentage of milk (0-100). Default = 3.3.
#' @param milk_density Numeric. Milk density in kg/L. Default = 1.03.
#'
#' @details The correction to FPCM (fat- and protein-corrected milk) follows the IDF formula:
#'   \deqn{FPCM = milk_kg * (0.1226 * fat_pct + 0.0776 * protein_pct + 0.2534)}
#'
#'   Where milk_kg = milk_litres * milk_density
#'
#' @return A list of class "cf_intensity" with intensity (kg CO2eq/kg FPCM),
#'   FPCM production, and calculation details.
#' @export
#'
#' @examples
#' \donttest{
#' # Using numeric total emissions directly
#' calc_intensity_litre(total_emissions = 85000, milk_litres = 750000)
#'
#' # If you have a cf_total object 'tot' (e.g., from calc_total_emissions):
#' # calc_intensity_litre(tot, milk_litres = 750000)
#' }
calc_intensity_litre <- function(total_emissions,
                                 milk_litres,
                                 fat = 4,
                                 protein = 3.3,
                                 milk_density = 1.03) {
  # Extract emissions value if cf_total object is passed
  if (inherits(total_emissions, "cf_total")) {
    emissions_value <- total_emissions$total_co2eq
  } else if (is.numeric(total_emissions)) {
    emissions_value <- total_emissions
  } else {
    stop("total_emissions must be numeric or a cf_total object")
  }

  # Validate inputs
  if (length(emissions_value) != 1 || is.na(emissions_value) || emissions_value < 0) {
    stop("total_emissions must be a single non-negative number")
  }
  if (length(milk_litres) != 1 || is.na(milk_litres) || milk_litres <= 0) {
    stop("milk_litres must be a single positive number")
  }
  if (!is.finite(fat) || fat < 0 || fat > 100) {
    stop("fat percentage must be between 0 and 100")
  }
  if (!is.finite(protein) || protein < 0 || protein > 100) {
    stop("protein percentage must be between 0 and 100")
  }
  if (!is.finite(milk_density) || milk_density <= 0) {
    stop("milk_density must be positive")
  }

  # Convert litres to kg
  milk_kg <- milk_litres * milk_density

  # Convert milk to fat- and protein-corrected milk (FPCM)
  fpcm_kg <- milk_kg * (0.1226 * fat + 0.0776 * protein + 0.2534)
  if (!is.finite(fpcm_kg) || fpcm_kg <= 0) {
    stop("Computed FPCM is not positive; check fat/protein/density inputs.")
  }

  # Intensity (kg CO2eq per kg FPCM)
  intensity <- emissions_value / fpcm_kg

  structure(
    list(
      intensity_co2eq_per_kg_fpcm = intensity,
      total_emissions_co2eq = emissions_value,
      milk_production_litres = milk_litres,
      milk_production_kg = milk_kg,
      fpcm_production_kg = fpcm_kg,
      fat_percent = fat,
      protein_percent = protein,
      milk_density_kg_per_l = milk_density,
      date = Sys.Date()
    ),
    class = "cf_intensity"
  )
}

#' Print method for cf_intensity objects
#'
#' @param x A cf_intensity object
#' @param ... Additional arguments (ignored)
#' @return No return value, called for side effects. Prints formatted carbon footprint
#'   intensity information to the console and invisibly returns the input object.
#' @return The input object `x`, invisibly.
#' @export
#' @examples
#' \donttest{
#' x <- list(
#'   intensity_co2eq_per_kg_fpcm = 0.9,
#'   total_emissions_co2eq = 85000,
#'   milk_production_litres = 750000,
#'   milk_production_kg = 750000 * 1.03,
#'   fpcm_production_kg = 750000 * 1.03 * (0.1226 * 4 + 0.0776 * 3.3 + 0.2534),
#'   fat_percent = 4, protein_percent = 3.3, milk_density_kg_per_l = 1.03,
#'   date = Sys.Date()
#' )
#' class(x) <- "cf_intensity"
#' # print(x)
#' }
print.cf_intensity <- function(x, ...) {
  cat("Carbon Footprint Intensity\n")
  cat("==========================\n")
  cat("Intensity:", round(x$intensity_co2eq_per_kg_fpcm, 3), "kg CO2eq/kg FPCM\n\n")
  cat("Production data:\n")
  cat(" Raw milk (L):", format(x$milk_production_litres, big.mark = ","), "L\n")
  cat(" Raw milk (kg):", format(round(x$milk_production_kg), big.mark = ","), "kg\n")
  cat(" FPCM (kg):", format(round(x$fpcm_production_kg), big.mark = ","), "kg\n")
  cat(" Fat content:", x$fat_percent, "%\n")
  cat(" Protein content:", x$protein_percent, "%\n\n")
  cat("Total emissions:", format(round(x$total_emissions_co2eq), big.mark = ","), "kg CO2eq\n")
  cat("Calculated on:", as.character(x$date), "\n")
  invisible(x)
}
