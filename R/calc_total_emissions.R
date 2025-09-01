#' Calculate total emissions
#'
#' Aggregates results from different emission source functions
#' into a single summary with totals and breakdown.
#'
#' @param ... Results from functions like \code{calc_emissions_entero()},
#'   \code{calc_emissions_manure()}, etc. (as lists).
#'
#' @return A list with breakdown (kg CO2eq by source) and total (kg CO2eq).
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' e1 <- calc_emissions_entero(100, boundaries = b)
#' e2 <- calc_emissions_manure(100, boundaries = b)
#' calc_total_emissions(e1, e2)
calc_total_emissions <- function(...) {
  sources <- list(...)

  # Extract co2eq by source
  breakdown <- sapply(sources, function(x) {
    if (!is.null(x$co2eq_kg)) x$co2eq_kg else 0
  })

  names(breakdown) <- sapply(sources, function(x) x$source)

  total <- sum(breakdown, na.rm = TRUE)

  list(
    breakdown = breakdown,
    total_co2eq = total,
    date = Sys.Date()
  )
}
