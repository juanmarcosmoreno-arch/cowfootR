#' Download cowfootR Excel template
#'
#' Saves a blank Excel template with required columns for batch carbon footprint calculations.
#'
#' @param file Path where the template will be saved. Default = "cowfootR_template.xlsx".
#'
#' @return Invisibly returns the file path.
#' @export
#'
#' @examples
#' download_template("my_farms.xlsx")
download_template <- function(file = "cowfootR_template.xlsx") {
  if (!requireNamespace("writexl", quietly = TRUE)) {
    stop("Package 'writexl' is required. Please install it with install.packages('writexl').")
  }

  columns <- c(
    "FarmID", "Year",
    # Production
    "Milk_litres", "Fat_percent", "Protein_percent",
    # Herd
    "Cows_milking", "Cows_dry",
    # Land
    "Area_total_ha", "Area_milking_cows_ha",
    # Fertilizers (tons)
    "Fert_Binary_ton", "Fert_Superphosphate_ton", "Fert_Urea_ton",
    "Fert_PotassiumChloride_ton", "Fert_Phosphorite_ton", "Fert_Other_ton",
    # Energy and fuels
    "Electricity_kWh", "Diesel_litres", "Petrol_litres",
    # Feed (kg)
    "Feed_DryGrain_kg", "Feed_WetGrain_kg", "Feed_RationMix_kg",
    "Feed_Byproducts_kg", "Feed_Proteins_kg",
    # Plastics (kg)
    "Plastic_kg"
  )

  df <- as.data.frame(matrix(ncol = length(columns), nrow = 0))
  colnames(df) <- columns

  writexl::write_xlsx(df, file)
  message("Template saved to: ", file)
  invisible(file)
}
