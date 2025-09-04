library(cowfootR)
devtools::document()
devtools::load_all()
library(dplyr)
# ======================================================================
# Ejemplo: Cálculo de Huella de Carbono en un tambo lechero
# Usando funciones calc_emissions_* y calc_intensity_*
# ======================================================================

# 1. Definir límites del sistema
# ----------------------------------------------------------------------
# scope = "farm_gate": incluye emisiones hasta la tranquera
# factors = "IPCC2019": versión de factores de emisión
boundaries <- set_system_boundaries(
  scope   = "farm_gate",
  factors = "IPCC2019"
)


# 2. Emisiones entéricas (fermentación ruminal)
# ----------------------------------------------------------------------
# n_cows = número de animales
# cattle_category = categoría (dairy_cows, heifers, calves, bulls)
# production_system = sistema (intensive, extensive, mixed)
# tier = metodología IPCC (1 = default, 2 = energético)
em_enteric_cows <- calc_emissions_enteric(
  n_cows = 120,
  cattle_category = "dairy_cows",
  production_system = "mixed",
  avg_milk_yield = 6500,
  boundaries = boundaries
)

em_enteric_heifers <- calc_emissions_enteric(
  n_cows = 30,
  cattle_category = "heifers",
  production_system = "mixed",
  boundaries = boundaries
)


# 3. Emisiones de estiércol (CH4 + N2O)
# ----------------------------------------------------------------------
# manure_system = manejo del estiércol (pasture, solid_storage, liquid_storage)
# include_indirect = si se incluyen emisiones indirectas (volatilización y lixiviación)
em_manure <- calc_emissions_manure(
  n_cows = 150,
  manure_system = "pasture",
  include_indirect = TRUE,
  boundaries = boundaries
)


# 4. Emisiones de suelo (N2O de fertilizantes, excretas y residuos de cultivo)
# ----------------------------------------------------------------------
# n_fertilizer_synthetic = N de fertilizante sintético aplicado (kg N/año)
# n_excreta_pasture = N depositado en pasturas (kg N/año)
# area_ha = superficie total (ha)
em_soil <- calc_emissions_soil(
  n_fertilizer_synthetic = 1200,
  n_fertilizer_organic   = 200,
  n_excreta_pasture      = 3000,
  n_crop_residues        = 500,
  area_ha = 100,
  soil_type = "well_drained",
  climate = "temperate",
  boundaries = boundaries
)


# 5. Emisiones de energía (combustibles + electricidad)
# ----------------------------------------------------------------------
# diesel_l = consumo de gasoil (litros/año)
# electricity_kwh = electricidad consumida (kWh/año)
# include_upstream = incluir emisiones previas (extracción/transporte)
em_energy <- calc_emissions_energy(
  diesel_l       = 18000,
  electricity_kwh = 25000,
  country = "UY",          # Uruguay
  include_upstream = TRUE,
  boundaries = boundaries
)


# 6. Emisiones de insumos comprados (concentrados, fertilizantes, plásticos)
# ----------------------------------------------------------------------
em_inputs <- calc_emissions_inputs(
  conc_kg    = 25000,
  fert_n_kg  = 800,
  plastic_kg = 200,
  boundaries = boundaries
)


# 7. Total de emisiones
# ----------------------------------------------------------------------
# Se suman todas las fuentes de emisión en un único objeto
total_em <- calc_total_emissions(
  em_enteric_cows,
  em_enteric_heifers,
  em_manure,
  em_soil,
  em_energy,
  em_inputs
)

print(total_em)   # Usa el método print para ver desglose y total


# 8. Intensidad por litro de leche (FPCM corregido)
# ----------------------------------------------------------------------
# milk_litres = producción anual de leche (litros)
# fat, protein = composición de la leche (%)
intensity_litre <- calc_intensity_litre(
  total_emissions = total_em,
  milk_litres = 1.1e6,
  fat = 3.9,
  protein = 3.3
)

print(intensity_litre)


# 9. Intensidad por hectárea
# ----------------------------------------------------------------------
# area_total_ha = superficie total (ha)
# area_productive_ha = área efectivamente productiva (ha)
# area_breakdown = desglose por tipo de uso de suelo
area_detail <- list(
  pasture_permanent = 70,
  pasture_temporary = 20,
  crops_feed = 10,
  infrastructure = 5,
  woodland = 5
)

intensity_area <- calc_intensity_area(
  total_emissions = total_em,
  area_total_ha = 110,
  area_productive_ha = 100,
  area_breakdown = area_detail
)

print(intensity_area)


# 10. Benchmarking regional (opcional)
# ----------------------------------------------------------------------
# Compara resultados con referencias por país/región
intensity_area_bench <- benchmark_area_intensity(
  intensity_area,
  region = "uruguay"
)

print(intensity_area_bench$benchmarking)

# 11. Descarga de plantilla Excel para sumar datos de muchos tambos
# ----------------------------------------------------------------------
# Compara resultados con referencias por país/región

download_template()
tambos <- readxl::read_excel("otro/cowfootR_template.xlsx")

# 12. calculo de huella de muchos tambos
# ----------------------------------------------------------------------
# Compara resultados con referencias por país/región
res <- calc_emissions_batch(tambos, benchmark_region = "uruguay")


# 3. Exportar reporte
export_hdc_report(res, "report_farms.xlsx", include_details = TRUE)
head(tambos)
