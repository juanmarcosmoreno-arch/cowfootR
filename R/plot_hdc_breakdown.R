#' Plot carbon footprint breakdown by source
#'
#' Creates an interactive plotly chart showing the breakdown
#' of emissions by source (entero, manure, soil, energy, inputs).
#'
#' @param total_emissions List. Output from \code{calc_total_emissions()}.
#' @param type Character. Type of plot: "bar" (default) or "pie".
#'
#' @return A plotly object.
#' @export
#'
#' @examples
#' b <- set_system_boundaries("farm_gate")
#' e1 <- calc_emissions_entero(100, boundaries = b)
#' e2 <- calc_emissions_manure(100, boundaries = b)
#' tot <- calc_total_emissions(e1, e2)
#' plot_hdc_breakdown(tot, type = "bar")
plot_hdc_breakdown <- function(total_emissions,
                               type = c("bar", "pie")) {
  if (!requireNamespace("plotly", quietly = TRUE)) {
    stop("Package 'plotly' is required. Please install it with install.packages('plotly').")
  }

  type <- match.arg(type)

  breakdown <- data.frame(
    Source = names(total_emissions$breakdown),
    Emissions = as.numeric(total_emissions$breakdown)
  )

  if (type == "bar") {
    p <- plotly::plot_ly(
      data = breakdown,
      x = ~Emissions,
      y = ~Source,
      type = "bar",
      orientation = "h",
      text = ~paste(round(Emissions, 1), "kg CO2eq"),
      hoverinfo = "text",
      marker = list(color = "steelblue")
    )
    p <- plotly::layout(
      p,
      title = "Carbon Footprint Breakdown by Source",
      xaxis = list(title = "Emissions (kg CO2eq)"),
      yaxis = list(title = "")
    )
  } else if (type == "pie") {
    p <- plotly::plot_ly(
      data = breakdown,
      labels = ~Source,
      values = ~Emissions,
      type = "pie",
      textinfo = "label+percent",
      hoverinfo = "label+value+percent"
    )
    p <- plotly::layout(
      p,
      title = "Carbon Footprint Breakdown (Proportions)"
    )
  }

  return(p)
}
