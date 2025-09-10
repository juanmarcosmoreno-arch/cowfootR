#' Download cowfootR Excel template
#'
#' Saves a blank Excel template with required columns for batch carbon footprint calculations.
#'
#' @param file Path where the template will be saved. Default = "cowfootR_template.xlsx".
#' @param include_examples Logical. If TRUE, includes example rows.
#'
#' @return Invisibly returns the file path.
#' @export
#'
#' @examples
#' tf <- tempfile(fileext = ".xlsx")
#' on.exit(unlink(tf, force = TRUE), add = TRUE)
#' download_template(tf)
download_template <- function(file = "cowfootR_template.xlsx",
                              include_examples = FALSE) {
  if (!requireNamespace("writexl", quietly = TRUE)) {
    stop("Package 'writexl' is required. Please install it with install.packages('writexl').")
  }

  columns <- c(
    "FarmID", "Year",
    "Milk_litres", "Fat_percent", "Protein_percent", "Milk_density",
    "Cows_milking", "Cows_dry", "Heifers_total", "Calves_total", "Bulls_total",
    "Milk_yield_kg_cow_year",
    "Body_weight_cows_kg", "Body_weight_cows_dry_kg", "Body_weight_heifers_kg",
    "Body_weight_calves_kg", "Body_weight_bulls_kg",
    "MS_intake_cows_milking_kg_day",
    "MS_intake_cows_dry_kg_day",
    "MS_intake_heifers_kg_day",
    "MS_intake_calves_kg_day",
    "MS_intake_bulls_kg_day",
    "Ym_percent",
    "Feed_grain_dry_kg", "Feed_grain_wet_kg",
    "Feed_ration_kg", "Feed_byproducts_kg", "Feed_proteins_kg",
    "Area_total_ha", "Area_productive_ha",
    "Pasture_permanent_ha", "Pasture_temporary_ha",
    "Crops_feed_ha", "Crops_cash_ha",
    "Infrastructure_ha", "Woodland_ha",
    "Area_fertilized_ha", "Soil_type", "Climate_zone",
    "N_fertilizer_kg",
    "Diesel_litres", "Petrol_litres", "Electricity_kWh",
    "LPG_kg", "Natural_gas_m3", "Country",
    "Concentrate_feed_kg", "Plastic_kg",
    "Manure_system"
  )

  if (include_examples) {
    df <- data.frame(
      FarmID = c("Farm_001", "Farm_002"),
      Year = c(2023, 2023),
      Milk_litres = c(750000, 450000),
      Fat_percent = c(3.9, 4.1),
      Protein_percent = c(3.2, 3.4),
      Milk_density = c(1.03, 1.03),
      Cows_milking = c(120, 85),
      Cows_dry = c(25, 18),
      Heifers_total = c(40, 25),
      Calves_total = c(60, 35),
      Bulls_total = c(5, 3),
      Milk_yield_kg_cow_year = c(6000, 5200),
      Body_weight_cows_kg = c(550, 520),
      Body_weight_cows_dry_kg = c(450, 420),
      Body_weight_heifers_kg = c(350, 340),
      Body_weight_calves_kg = c(150, 140),
      Body_weight_bulls_kg = c(700, 680),
      MS_intake_cows_milking_kg_day = c(17, 15),
      MS_intake_cows_dry_kg_day = c(17, 15),
      MS_intake_heifers_kg_day = c(10, 9),
      MS_intake_calves_kg_day = c(5, 4),
      MS_intake_bulls_kg_day = c(12, 11),
      Ym_percent = c(6.5, 6.5),
      Feed_grain_dry_kg   = c(120000, 80000),
      Feed_grain_wet_kg   = c(60000, 40000),
      Feed_ration_kg      = c(100000, 70000),
      Feed_byproducts_kg  = c(30000, 20000),
      Feed_proteins_kg    = c(25000, 15000),
      Area_total_ha = c(150, 95),
      Area_productive_ha = c(140, 90),
      Pasture_permanent_ha = c(100, 60),
      Pasture_temporary_ha = c(20, 15),
      Crops_feed_ha = c(15, 10),
      Crops_cash_ha = c(0, 0),
      Infrastructure_ha = c(5, 3),
      Woodland_ha = c(10, 7),
      Area_fertilized_ha = c(120, 80),
      Soil_type = c("well_drained", "poorly_drained"),
      Climate_zone = c("temperate", "temperate"),
      N_fertilizer_kg = c(8000, 5000),
      Diesel_litres = c(8500, 5000),
      Petrol_litres = c(1200, 800),
      Electricity_kWh = c(45000, 30000),
      LPG_kg = c(500, 300),
      Natural_gas_m3 = c(0, 0),
      Country = c("UY", "UY"),
      Concentrate_feed_kg = c(230000, 130000),
      Plastic_kg = c(400, 250),
      Manure_system = c("pasture", "pasture"),
      stringsAsFactors = FALSE
    )
  } else {
    df <- data.frame(matrix(ncol = length(columns), nrow = 0))
    colnames(df) <- columns
  }

  writexl::write_xlsx(df, file)
  message("Template saved to: ", file)
  invisible(file)
}
