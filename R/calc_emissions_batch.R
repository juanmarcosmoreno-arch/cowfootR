#' Batch carbon footprint calculation
#'
#' Processes a dataset (Excel or data.frame) of multiple farms and
#' computes emissions by source, total, and intensities.
#'
#' @param data Data.frame with required columns (see template).
#'   If character, it will be read as Excel file.
#' @param boundaries System boundaries (default = farm_gate).
#'
#' @return A data.frame with results per farm.
#' @export
#'
#' @examples
#' # df <- readxl::read_excel("cowfootR_template.xlsx")
#' # results <- calc_emissions_batch(df)
calc_emissions_batch <- function(data,
                                 boundaries = set_system_boundaries("farm_gate")) {
  if (is.character(data)) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Package 'readxl' is required to read Excel files. Install with install.packages('readxl').")
    }
    data <- readxl::read_excel(data)
  }

  # Required columns from template
  required_cols <- c(
    "FarmID", "Year",
    "Milk_litres", "Fat_percent", "Protein_percent",
    "Cows_milking", "Cows_dry",
    "Area_total_ha",
    "Fert_Binarios_ton", "Fert_Superfosfato_ton", "Fert_Urea_ton",
    "Fert_CloruroK_ton", "Fert_Fosforita_ton", "Fert_Otro_ton",
    "Electricity_kWh", "Diesel_litres", "Petrol_litres",
    "Feed_GranoSeco_kg", "Feed_GranoHumedo_kg", "Feed_RacionLex_kg",
    "Feed_Subproductos_kg", "Feed_Proteicos_kg",
    "Plastic_kg"
  )

  # Add missing cols with 0
  for (col in required_cols) {
    if (!col %in% names(data)) {
      warning(paste("Column", col, "missing, filled with 0"))
      data[[col]] <- 0
    }
  }

  results <- lapply(1:nrow(data), function(i) {
    row <- data[i, ]

    # Emissions by source
    e1 <- calc_emissions_entero(row$Cows_milking, boundaries = boundaries)
    e2 <- calc_emissions_manure(row$Cows_milking + row$Cows_dry, boundaries = boundaries)

    fert_total_kg <- (row$Fert_Binarios_ton + row$Fert_Superfosfato_ton +
                        row$Fert_Urea_ton + row$Fert_CloruroK_ton +
                        row$Fert_Fosforita_ton + row$Fert_Otro_ton) * 1000
    e3 <- calc_emissions_soil(n_fert = fert_total_kg, boundaries = boundaries)

    e4 <- calc_emissions_energy(
      diesel_l = row$Diesel_litres,
      petrol_l = row$Petrol_litres,
      electricity_kwh = row$Electricity_kWh,
      boundaries = boundaries
    )

    feed_total_kg <- row$Feed_GranoSeco_kg + row$Feed_GranoHumedo_kg +
      row$Feed_RacionLex_kg + row$Feed_Subproductos_kg +
      row$Feed_Proteicos_kg
    e5 <- calc_emissions_inputs(
      conc_kg = feed_total_kg,
      fert_n_kg = fert_total_kg, # production emissions of fertilizers
      plastic_kg = row$Plastic_kg,
      boundaries = boundaries
    )

    # Total
    tot <- calc_total_emissions(e1, e2, e3, e4, e5)

    # Intensities
    lit <- calc_intensity_litre(
      tot$total_co2eq,
      milk_litres = row$Milk_litres,
      fat = row$Fat_percent,
      protein = row$Protein_percent
    )
    are <- calc_intensity_area(
      tot$total_co2eq,
      area_ha = row$Area_total_ha
    )

    data.frame(
      FarmID = row$FarmID,
      Year = row$Year,
      Em_entero = e1$co2eq_kg,
      Em_manure = e2$co2eq_kg,
      Em_soil = e3$co2eq_kg,
      Em_energy = e4$co2eq_kg,
      Em_inputs = e5$co2eq_kg,
      Em_total = tot$total_co2eq,
      Intensity_litre = lit,
      Intensity_area = are
    )
  })

  results_df <- do.call(rbind, results)
  return(results_df)
}
