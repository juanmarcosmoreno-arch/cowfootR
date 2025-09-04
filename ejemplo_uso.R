

devtools::document()
devtools::load_all()
devtools::build_readme()
##
b <- set_system_boundaries("farm_gate")
b

calc_emissions_entero(230, boundaries = b)

calc_emissions_soil(n_fert = 1500, n_excreta = 5000, boundaries = b)

calc_emissions_energy(diesel_l = 2000, electricity_kwh = 5000, boundaries = b)

calc_emissions_inputs(conc_kg = 1000, fert_n_kg = 500, plastic_kg = 100, boundaries = b)


e1 <- calc_emissions_entero(100, boundaries = b)
e2 <- calc_emissions_manure(100, boundaries = b)
e3 <- calc_emissions_soil(n_fert = 1500, n_excreta = 5000, boundaries = b)
e4 <- calc_emissions_energy(diesel_l = 2000, electricity_kwh = 5000, boundaries = b)
e5 <- calc_emissions_inputs(conc_kg = 1000, fert_n_kg = 500, plastic_kg = 100, boundaries = b)

# Sistema extensivo básico
calc_emissions_manure(100)

# Sistema intensivo con almacenamiento líquido
calc_emissions_manure(100, manure_system = "liquid_storage")

# Cálculo completo con emisiones indirectas
calc_emissions_manure(100, include_indirect = TRUE)
calc_total_emissions(e1, e2, e3, e4, e5)

calc_intensity_litre(tot$total_co2eq, milk_litres = 750000)



lit <- calc_intensity_litre(tot$total_co2eq, 750000)
are <- calc_intensity_area(tot$total_co2eq, 120)

rep <- report_hdc(tot, lit, are)

rep$breakdown_table   # tabla desglose
rep$summary_table     # tabla resumen


e1 <- calc_emissions_entero(100, boundaries = b)
e2 <- calc_emissions_manure(100, boundaries = b)
e3 <- calc_emissions_soil(n_fert = 1500, n_excreta = 5000, boundaries = b)
e4 <- calc_emissions_energy(diesel_l = 2000, electricity_kwh = 5000, boundaries = b)
e5 <- calc_emissions_inputs(conc_kg = 1000, fert_n_kg = 500, plastic_kg = 100, boundaries = b)

tot <- calc_total_emissions(e1, e2, e3, e4, e5)

# Bar chart
plot_hdc_breakdown(tot, type = "bar")

# Pie chart
plot_hdc_breakdown(tot, type = "pie")


# Leer directamente el Excel en formato template
results <- calc_emissions_batch("carpeta_para_ignorar/cowfootR_template.xlsx")

print(results)

# Calcular resultados desde Excel de entrada
results <- calc_emissions_batch("carpeta_para_ignorar/cowfootR_template.xlsx")

# Exportar resultados a Excel
export_hdc_report(results, "HdC_results.xlsx")

# Save template in working directory
download_template("my_farms.xlsx")
