
# cowfootR <img src="man/figures/logo.png" align="right" width="120" />

Tools to estimate the carbon footprint of dairy farms.  
Implements methods based on IDF (International Dairy Federation)  
and IPCC guidelines for greenhouse gas accounting.

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/cowfootR)](https://CRAN.R-project.org/package=cowfootR)
[![R-CMD-check](https://github.com/juanmarcosmoreno-arch/cowfootR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/juanmarcosmoreno-arch/cowfootR/actions/workflows/R-CMD-check.yaml)
[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html#maturing)
[![Codecov test
coverage](https://codecov.io/gh/juanmarcosmoreno-arch/cowfootR/graph/badge.svg)](https://app.codecov.io/gh/juanmarcosmoreno-arch/cowfootR)
<!-- badges: end -->

## Overview

`cowfootR` provides a comprehensive toolkit for calculating carbon
footprints of dairy farms following IPCC guidelines ([IPCC 2019
Refinement](https://www.ipcc-nggip.iges.or.jp/public/2019rf/index.html))
and International Dairy Federation guidance for the dairy sector ([IDF
Bulletin
520](https://shop.fil-idf.org/products/the-idf-global-carbon-footprint-standard-for-the-dairy-sector?_pos=1&_sid=8a3f414f8&_ss=r)).
The package includes:

- **Individual emission calculations** from enteric fermentation,
  manure, soil, energy, and inputs
- **Batch processing** capabilities for multiple farms
- **Intensity metrics** per liter of milk and per hectare
- **System boundary flexibility** (farm gate, cradle-to-farm gate, etc.)
- **Excel integration** for data input and report generation

## Installation

``` r
install.packages("cowfootR")
```

Or install the development version:

``` r
devtools::install_github("juanmarcosmoreno-arch/cowfootR")
```

## Quick Start

Below is a minimal, end-to-end example showing the core workflow of
`cowfootR` for a single dairy farm.

``` r
library(cowfootR)

# 1. Define system boundaries
boundaries <- set_system_boundaries("farm_gate")

# 2. Calculate emissions by source
enteric <- calc_emissions_enteric(
  n_animals = 100,
  cattle_category = "dairy_cows",
  boundaries = boundaries
)

manure <- calc_emissions_manure(
  n_cows = 100,
  boundaries = boundaries
)

soil <- calc_emissions_soil(
  n_fertilizer_synthetic = 1500,
  n_excreta_pasture = 5000,
  area_ha = 120,
  boundaries = boundaries
)

energy <- calc_emissions_energy(
  diesel_l = 2000,
  electricity_kwh = 5000,
  boundaries = boundaries
)

inputs <- calc_emissions_inputs(
  conc_kg = 1000,
  fert_n_kg = 500,
  boundaries = boundaries
)

# 3. Aggregate total emissions
total_emissions <- calc_total_emissions(enteric, manure, soil, energy, inputs)
total_emissions
#> Carbon Footprint - Total Emissions
#> ==================================
#> Total CO2eq: 451512.6 kg CO2eq yr-1 
#> Number of sources: 5 
#> 
#> Breakdown by source:
#>   energy : 5740 kg CO2eq yr-1 
#>   enteric : 312800 kg CO2eq yr-1 
#>   inputs : 4000 kg CO2eq yr-1 
#>   manure : 89880 kg CO2eq yr-1 
#>   soil : 39092.62 kg CO2eq yr-1 
#> 
#> Calculated on: 2026-01-14

# 4. Intensity metrics
milk_intensity <- calc_intensity_litre(
  total_emissions = total_emissions,
  milk_litres = 750000,
  fat = 4.0,
  protein = 3.3
)
milk_intensity
#> Carbon Footprint Intensity
#> ==========================
#> Intensity: 0.585 kg CO2eq/kg FPCM
#> 
#> Production data:
#>  Raw milk (L): 750,000 L
#>  Raw milk (kg): 772,500 kg
#>  FPCM (kg): 772,407 kg
#>  Fat content: 4 %
#>  Protein content: 3.3 %
#> 
#> Total emissions: 451,513 kg CO2eq
#> Calculated on: 2026-01-14

area_intensity <- calc_intensity_area(
  total_emissions = total_emissions,
  area_total_ha = 120
)
area_intensity
#> Carbon Footprint Area Intensity
#> ===============================
#> Intensity (total area): 3762.61 kg CO2eq/ha
#> Intensity (productive area): 3762.61 kg CO2eq/ha
#> 
#> Area summary:
#>  Total area: 120 ha
#>  Productive area: 120 ha
#>  Land use efficiency: 100%
#> 
#> Total emissions: 451,513 kg CO2eq
#> Calculated on: 2026-01-14
```

**Note on units:**  
All absolute emission results returned by `cowfootR` are annual
farm-level totals and are expressed as **kg CO2eq yr⁻1** within the
defined system boundaries. Intensity metrics are expressed as **kg CO2eq
per kg FPCM** and **kg CO2eq ha⁻1 yr⁻1** (derived from annual totals).

## Batch processing (typical real-world use)

In practical applications, `cowfootR` is most often used to process data
from multiple farms simultaneously. This is handled through the
`calc_batch()` function, which applies the same methodological workflow
across all farms in a structured dataset.

Below is a minimal example illustrating batch processing for multiple
farms.

``` r
library(cowfootR)

# Example dataset with two farms
farms <- data.frame(
  FarmID = c("Farm_A", "Farm_B"),
  Year = c(2023, 2023),
  Milk_litres = c(500000, 750000),
  Cows_milking = c(90, 130),
  Area_total_ha = c(110, 160),
  Diesel_litres = c(4000, 6500),
  Electricity_kWh = c(18000, 26000),
  Concentrate_feed_kg = c(120000, 180000),
  stringsAsFactors = FALSE
)

# Define system boundaries
boundaries <- set_system_boundaries("farm_gate")

# Run batch carbon footprint calculation
batch_results <- calc_batch(
  data = farms,
  tier = 2,
  boundaries = boundaries,
  benchmark_region = "uruguay"
)
#> Batch: 2 rows; tier=2 ...

# Summary of batch processing
batch_results$summary
#> $n_farms_processed
#> [1] 2
#> 
#> $n_farms_successful
#> [1] 2
#> 
#> $n_farms_with_errors
#> [1] 0
#> 
#> $boundaries_used
#> $boundaries_used$scope
#> [1] "farm_gate"
#> 
#> $boundaries_used$include
#> [1] "enteric" "manure"  "soil"    "energy"  "inputs" 
#> 
#> 
#> $benchmark_region
#> [1] "uruguay"
#> 
#> $processing_date
#> [1] "2026-01-14"

# Farm-level results
batch_results$farm_results
#> [[1]]
#> [[1]]$success
#> [1] TRUE
#> 
#> [[1]]$farm_id
#> [1] "Farm_A"
#> 
#> [[1]]$year
#> [1] "2023"
#> 
#> [[1]]$emissions_enteric
#> [1] 230826.6
#> 
#> [[1]]$emissions_manure
#> [1] 183066.1
#> 
#> [[1]]$emissions_soil
#> [1] 0
#> 
#> [[1]]$emissions_energy
#> [1] 13794
#> 
#> [[1]]$emissions_inputs
#> [1] 84000
#> 
#> [[1]]$emissions_total
#> [1] 511686.8
#> 
#> [[1]]$intensity_milk_kg_co2eq_per_kg_fpcm
#> [1] 0.9936858
#> 
#> [[1]]$intensity_area_kg_co2eq_per_ha_total
#> [1] 4651.7
#> 
#> [[1]]$intensity_area_kg_co2eq_per_ha_productive
#> [1] 4651.7
#> 
#> [[1]]$fpcm_production_kg
#> [1] 514938.2
#> 
#> [[1]]$milk_production_kg
#> [1] 515000
#> 
#> [[1]]$milk_production_litres
#> [1] 5e+05
#> 
#> [[1]]$land_use_efficiency
#> [1] 1
#> 
#> [[1]]$total_animals
#> [1] 90
#> 
#> [[1]]$dairy_cows
#> [1] 90
#> 
#> [[1]]$benchmark_region
#> [1] "uruguay"
#> 
#> [[1]]$benchmark_performance
#> [1] "Excellent (below typical range)"
#> 
#> [[1]]$processing_date
#> [1] "2026-01-14"
#> 
#> [[1]]$boundaries_used
#> [1] "farm_gate"
#> 
#> [[1]]$tier_used
#> [1] "tier_2"
#> 
#> [[1]]$detailed_objects
#> NULL
#> 
#> 
#> [[2]]
#> [[2]]$success
#> [1] TRUE
#> 
#> [[2]]$farm_id
#> [1] "Farm_B"
#> 
#> [[2]]$year
#> [1] "2023"
#> 
#> [[2]]$emissions_enteric
#> [1] 333416.3
#> 
#> [[2]]$emissions_manure
#> [1] 264428.9
#> 
#> [[2]]$emissions_soil
#> [1] 0
#> 
#> [[2]]$emissions_energy
#> [1] 22142.25
#> 
#> [[2]]$emissions_inputs
#> [1] 126000
#> 
#> [[2]]$emissions_total
#> [1] 745987.4
#> 
#> [[2]]$intensity_milk_kg_co2eq_per_kg_fpcm
#> [1] 0.9657954
#> 
#> [[2]]$intensity_area_kg_co2eq_per_ha_total
#> [1] 4662.42
#> 
#> [[2]]$intensity_area_kg_co2eq_per_ha_productive
#> [1] 4662.42
#> 
#> [[2]]$fpcm_production_kg
#> [1] 772407.3
#> 
#> [[2]]$milk_production_kg
#> [1] 772500
#> 
#> [[2]]$milk_production_litres
#> [1] 750000
#> 
#> [[2]]$land_use_efficiency
#> [1] 1
#> 
#> [[2]]$total_animals
#> [1] 130
#> 
#> [[2]]$dairy_cows
#> [1] 130
#> 
#> [[2]]$benchmark_region
#> [1] "uruguay"
#> 
#> [[2]]$benchmark_performance
#> [1] "Excellent (below typical range)"
#> 
#> [[2]]$processing_date
#> [1] "2026-01-14"
#> 
#> [[2]]$boundaries_used
#> [1] "farm_gate"
#> 
#> [[2]]$tier_used
#> [1] "tier_2"
#> 
#> [[2]]$detailed_objects
#> NULL

# Export results to Excel
export_hdc_report(
  batch_results,
  file = "cowfootR_batch_report.xlsx"
)
#> Batch report saved to: cowfootR_batch_report.xlsx
```

Batch results can be directly exported to an Excel report using
`export_hdc_report()`, facilitating integration with reporting workflows
commonly used by consultants, researchers, and stakeholders.

### Emission Sources Covered

- **Enteric fermentation**: CH₄ from ruminal fermentation
- **Manure management**: CH₄ and N₂O from manure systems
- **Soil emissions**: N₂O from fertilizer application and excreta
- **Energy consumption**: CO₂ from diesel, electricity, and other fuels
- **External inputs**: CO₂eq from feed, fertilizers, and materials

### System Boundaries

``` r
boundaries_fg <- set_system_boundaries("farm_gate")
boundaries_cfg <- set_system_boundaries("cradle_to_farm_gate")
```

### Intensity Metrics

The package calculates multiple intensity metrics:

- **Per liter of milk**: kg CO₂eq per liter
- **Per kg FPCM**: kg CO₂eq per kg Fat and Protein Corrected Milk
- **Per hectare**: kg CO₂eq per hectare (total and productive area)
- **Land use efficiency**: productive area / total area ratio

## Data Requirements

### Required Columns

- `FarmID`: Unique farm identifier
- `Year`: Year of data collection  
- `Milk_litres`: Annual milk production (liters)
- `Cows_milking`: Number of milking cows
- `Area_total_ha`: Total farm area (hectares)

### Optional Columns

- Animal data: `Cows_dry`, `Heifers_total`, `Calves_total`,
  `Bulls_total`
- Production: `Fat_percent`, `Protein_percent`, `Milk_yield_kg_cow_year`
- Feed: `MS_intake_cows_milking_kg_day`, `Ym_percent`,
  `Concentrate_feed_kg`
- Fertilizer: `N_fertilizer_kg`, `N_fertilizer_organic_kg`
- Energy: `Diesel_litres`, `Electricity_kWh`, `Petrol_litres`
- Land use: `Area_productive_ha`, `Pasture_permanent_ha`

Use `cf_download_template()` to get the complete column structure.

## Error Handling

The package includes robust error handling for batch processing:

For batch processing, Excel templates, reporting, and error handling,
please see the package vignettes and the documentation website.

## Contributing

This package is under active development. Please report issues or
suggest improvements on
[GitHub](https://github.com/juanmarcosmoreno-arch/cowfootR/issues).

## References

- IPCC 2019 Refinement to the 2006 IPCC Guidelines for National
  Greenhouse Gas Inventories
  <https://www.ipcc-nggip.iges.or.jp/public/2019rf/index.html>
- International Dairy Federation (IDF). 2022. The IDF global Carbon
  Footprint standard for the dairy sector
  <https://shop.fil-idf.org/products/the-idf-global-carbon-footprint-standard-for-the-dairy-sector?_pos=1&_sid=8a3f414f8&_ss=r>
- FAO. 2010. Greenhouse Gas Emissions from the Dairy Sector
  <https://www.fao.org/4/k7930e/k7930e00.pdf>

## License

MIT License © 2025 Juan Moreno

[![pkgdown
site](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://juanmarcosmoreno-arch.github.io/cowfootR/)
