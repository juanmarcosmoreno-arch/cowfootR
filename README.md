

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
#> Total CO2eq: 451512.6 kg
#> Number of sources: 5 
#> 
#> Breakdown by source:
#>   energy : 5740 kg CO2eq
#>   enteric : 312800 kg CO2eq
#>   inputs : 4000 kg CO2eq
#>   manure : 89880 kg CO2eq
#>   soil : 39092.62 kg CO2eq
#> 
#> Calculated on: 2026-01-05

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
#> Calculated on: 2026-01-05

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
#> Calculated on: 2026-01-05
```

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
