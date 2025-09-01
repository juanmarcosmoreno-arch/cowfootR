#' Generate a carbon footprint report
#'
#' Creates a summary table of carbon footprint results,
#' including breakdown by source and intensities.
#'
#' @param total_emissions List. Output of \code{calc_total_emissions()}.
#' @param intensity_litre Numeric. Output of \code{calc_intensity_litre()}.
#' @param intensity_area Numeric. Output of \code{calc_intensity_area()}.
#'
#' @return A list of gt tables: breakdown and summary.
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' e1 <- calc_emissions_entero(100, boundaries = b)
#' e2 <- calc_emissions_manure(100, boundaries = b)
#' tot <- calc_total_emissions(e1, e2)
#' lit <- calc_intensity_litre(tot$total_co2eq, 750000)
#' are <- calc_intensity_area(tot$total_co2eq, 120)
#' report_hdc(tot, lit, are)
report_hdc <- function(total_emissions,
                       intensity_litre,
                       intensity_area) {
  if (!requireNamespace("gt", quietly = TRUE)) {
    stop("Package 'gt' is required. Please install it with install.packages('gt').")
  }

  breakdown <- data.frame(
    Source = names(total_emissions$breakdown),
    Emissions_kgCO2eq = as.numeric(total_emissions$breakdown)
  )

  summary <- data.frame(
    Metric = c("Total emissions",
               "Intensity (kg CO2eq/kg FPCM)",
               "Intensity (kg CO2eq/ha)"),
    Value = c(total_emissions$total_co2eq,
              intensity_litre,
              intensity_area)
  )

  # Build gt tables
  tab <- gt::gt(breakdown)
  tab <- gt::tab_header(tab,
                        title = "Carbon Footprint Report",
                        subtitle = paste("Generated on", Sys.Date()))
  tab <- gt::tab_spanner(tab,
                         label = "Breakdown by source",
                         columns = "Emissions_kgCO2eq")
  tab <- gt::tab_source_note(tab,
                             source_note = "cowfootR package - based on IDF methodology")

  tab_summary <- gt::gt(summary)
  tab_summary <- gt::tab_header(tab_summary,
                                title = "Summary indicators")

  list(breakdown_table = tab, summary_table = tab_summary)
}
