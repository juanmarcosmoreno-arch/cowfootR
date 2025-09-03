library(cowfootR)
devtools::document()
devtools::load_all()
# =====================================================================
# Ejemplo actualizado de cálculo de huella de carbono en un tambo lechero
# con parámetros realistas y anotaciones de defaults/constantes
# =====================================================================

# 1. Definir límites del sistema
bound <- set_system_boundaries(
  scope   = "farm_gate",
  include = c("enteric", "manure", "soil", "energy", "inputs")
)

# 2. Emisiones entéricas (CH4)
enteric <- calc_emissions_enteric(
  n_cows            = 120,
  cattle_category   = "dairy_cows",     # default = "dairy_cows"
  production_system = "mixed",          # default = "mixed"
  avg_milk_yield    = 7000,             # producción anual por vaca (kg leche corregida)
  avg_body_weight   = 600,              # peso vivo promedio (kg)
  ms_intake         = 21,               # consumo de MS (kg/vaca/día) ajustado ↑
  feed_inputs       = list(             # kg base seca/año (opcional)
    grain_dry   = 25000,
    grain_wet   = 8000,
    ration      = 12000,
    byproducts  = 6000,
    proteins    = 4000
  ),
  ym_percent        = 6.5,              # constante IDF/IPCC (Tier 2)
  ef_ch4            = NULL,             # default = usa Tier
  tier              = 2,                # default = 1 → aquí lo forzamos a Tier 2
  gwp_ch4           = 27.2,             # constante IPCC AR6 (100 años)
  boundaries        = bound
)

# 3. Emisiones de estiércol (CH4 + N2O)
manure_tier1 <- calc_emissions_manure(
  n_cows          = 120,
  manure_system   = "solid_storage",    # default = "pasture"
  tier            = 1,                  # Tier 1 (default, no necesitas especificarlo)
  ef_ch4          = NULL,               # default = usa valores IPCC/IDF por sistema
  n_excreted      = 85,                 # ajustado ↓ (kg N/cab/año) típico 80–90
  ef_n2o_direct   = 0.02,               # constante IPCC 2019
  include_indirect= TRUE,               # default = FALSE → lo activamos
  gwp_ch4         = 27.2,               # constante IPCC AR6
  gwp_n2o         = 273,                # constante IPCC AR6
  boundaries      = bound
)

manure_tier2 <- calc_emissions_manure(
  n_cows          = 120,
  manure_system   = "solid_storage",    # mismo sistema
  tier            = 2,                  # ¡TIER 2 para mayor precisión!

  # === DATOS ADICIONALES TIER 2 ===
  climate         = "temperate",        # región climática
  avg_body_weight = 590,                # peso promedio vacas (kg)
  diet_digestibility = 0.65,            # digestibilidad dieta (65% - típico sólidos)

  # === DATOS OPCIONALES AVANZADOS ===
  protein_intake_kg = 3.2,              # ingesta proteína diaria (kg/día)
  retention_days    = 75,               # días en almacenamiento sólido
  system_temperature = 16,              # temperatura promedio sistema (°C)

  # === PARÁMETROS ORIGINALES (mantener) ===
  n_excreted      = 85,                 # kg N/cab/año (será recalculado si protein_intake_kg disponible)
  ef_n2o_direct   = 0.02,               # constante IPCC 2019
  include_indirect= TRUE,               # emisiones indirectas activadas
  gwp_ch4         = 27.2,               # constante IPCC AR6
  gwp_n2o         = 273,                # constante IPCC AR6
  boundaries      = bound
)

# 4. Emisiones de suelo (N2O)
soil <- calc_emissions_soil(
  n_fertilizer_synthetic = 1800,        # kg N/año
  n_fertilizer_organic   = 300,         # kg N/año
  n_excreta_pasture      = 5000,        # kg N/año depositado en pastoreo
  n_crop_residues        = 1200,        # kg N/año
  area_ha                = 150,         # superficie (ha)
  soil_type              = "poorly_drained",  # default = "well_drained"
  climate                = "temperate",      # default = "temperate"
  ef_direct              = NULL,        # default = usa valores IPCC según suelo/clima
  include_indirect       = TRUE,        # default = TRUE
  gwp_n2o                = 273,         # constante IPCC AR6
  boundaries             = bound
)

# 5. Emisiones de energía (CO2)
energy <- calc_emissions_energy(
  diesel_l        = 6000,   # litros/año
  petrol_l        = 500,    # litros/año
  lpg_kg          = 800,    # kg/año
  natural_gas_m3  = 1000,   # m³/año
  electricity_kwh = 20000,  # kWh/año
  country         = "UY",   # default = "UY", Uruguay (0.08 kg CO2/kWh)
  ef_diesel       = 2.67,   # constante IPCC 2019
  ef_petrol       = 2.31,   # constante IPCC 2019
  ef_lpg          = 3.0,    # constante IPCC 2019
  ef_natural_gas  = 2.0,    # constante IPCC 2019
  ef_electricity  = NULL,   # default = factor país
  include_upstream= TRUE,   # default = FALSE → lo activamos
  energy_breakdown = list(  # desglose opcional
    ordeñe    = list(diesel_l = 500, electricity_kwh = 5000),
    tractor   = list(diesel_l = 4000),
    generador = list(diesel_l = 1500, lpg_kg = 800)
  ),
  boundaries = bound
)

# 6. Emisiones de insumos (CO2eq indirecto)
inputs <- calc_emissions_inputs(
  # Cantidades de insumos
  conc_kg            = 2000,   # kg/año
  fert_n_kg          = 600,    # kg N/año
  plastic_kg         = 150,    # kg/año
  feed_grain_dry_kg  = 30000,  # kg/año
  feed_grain_wet_kg  = 10000,  # kg/año
  feed_ration_kg     = 12000,  # kg/año
  feed_byproducts_kg = 7000,   # kg/año
  feed_proteins_kg   = 5000,   # kg/año

  # Configuración regional y de tipos
  region = "global",              # Opciones: "EU", "US", "Brazil", "Argentina", "Australia", "global"
  fert_type = "mixed",           # Opciones: "urea", "ammonium_nitrate", "mixed", "organic"
  plastic_type = "mixed",        # Opciones: "LDPE", "HDPE", "PP", "mixed"

  # Factores de emisión personalizados (opcional - si no se especifican, usa los regionales)
  ef_conc = 0.7,                 # kg CO2eq/kg (opcional - usa factor regional si es NULL)
  ef_fert = 6.6,                 # kg CO2eq/kg N (opcional - usa factor regional si es NULL)
  ef_plastic = 2.5,              # kg CO2eq/kg (opcional - usa factor regional si es NULL)

  # Análisis adicionales
  include_uncertainty = FALSE,    # Cambiar a TRUE si quieres análisis de incertidumbre
  transport_km = NULL,           # Distancia de transporte en km (opcional)

  # Límites del sistema
  boundaries = bound
)

# 7. Integrar todas las fuentes
total <- calc_total_emissions(enteric, manure_tier1, soil, energy, inputs)


# 8. Mostrar resultados
print(total)

#8. Intensidad por litro de leche (FPCM corregido)
# ----------------------------------------------------------------------
# milk_litres = producción anual de leche (litros)
# fat, protein = composición de la leche (%)
intensity_litre <- calc_intensity_litre(
  total_emissions = total,
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
  total_emissions = total,
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

# Paso 2: comparar con benchmark de Uruguay
bench <- benchmark_area_intensity(area_int, region = "uruguay")

# Ver resultados
bench$benchmarking

# 11. Descarga de plantilla Excel para sumar datos de muchos tambos
# ----------------------------------------------------------------------
# Compara resultados con referencias por país/región

download_template()
tambos <- readxl::read_excel("otro/cowfootR_template.xlsx")

# 12. calculo de huella de muchos tambos
# ----------------------------------------------------------------------


res_batch <- calc_batch(tambos,
                        tier = 2,
                        benchmark_region = "uruguay",
                        save_detailed_objects = TRUE)  # opcional

# Exportar a Excel
export_hdc_report(res_batch)

# O con detalles adicionales
export_hdc_report(res_batch,
                  file = "mi_reporte_completo.xlsx",
                  include_details = TRUE)


