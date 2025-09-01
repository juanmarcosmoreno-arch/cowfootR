#' Export carbon footprint results to Excel
#'
#' Saves the results from \code{calc_emissions_batch()} into an Excel file.
#'
#' @param results Data.frame. Output from \code{calc_emissions_batch()}.
#' @param file Character. Path to the Excel file to be created.
#'
#' @return Invisibly returns the file path.
#' @export
#'
#' @examples
#' # results <- calc_emissions_batch("cowfootR_template.xlsx")
#' # export_hdc_report(results, "HdC_results.xlsx")
export_hdc_report <- function(results, file = "HdC_results.xlsx") {
  if (!requireNamespace("writexl", quietly = TRUE)) {
    stop("Package 'writexl' is required. Please install it with install.packages('writexl').")
  }

  writexl::write_xlsx(results, path = file)

  message("Report exported to: ", file)
  invisible(file)
}
