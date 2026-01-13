# Get started with cowfootR

## Get started with cowfootR

This vignette provides a practical, end-to-end introduction to
**cowfootR**. It is intended for new users who want to understand the
core workflow of the package and obtain a first carbon footprint
estimate for a dairy farm.

The focus is on: - understanding the workflow - knowing which functions
to call and in what order - seeing actual outputs produced by the
package

More detailed explanations of parameters, methodological choices, and
advanced use cases are covered in the other vignettes.

### What does cowfootR do?

cowfootR estimates greenhouse gas (GHG) emissions from dairy farms
following IPCC (2019) and IDF (2022) guidelines.

The package: - calculates emissions by source - aggregates them into
total farm emissions - computes intensity metrics per unit of milk or
land - supports single-farm and batch (multi-farm) analysis

The standard workflow is: 1- Define system boundaries 2- Calculate
emissions by source 3- Aggregate total emissions 4- Calculate intensity
metrics

This vignette walks through these steps using a minimal example.

### Installation and loading the package

``` r
install.packages("cowfootR")
```

Or install the development version:

``` r
devtools::install_github("juanmarcosmoreno-arch/cowfootR")
```

Load the package:

``` r
library(cowfootR)
```

### Step 1: Define system boundaries

System boundaries determine which emission sources are included in the
assessment.

The most common option is “farm_gate”, which includes on-farm emissions
only.

``` r
boundaries <- set_system_boundaries("farm_gate")
boundaries
#> $scope
#> [1] "farm_gate"
#> 
#> $include
#> [1] "enteric" "manure"  "soil"    "energy"  "inputs"
```

Other options (e.g. “cradle_to_farm_gate”) are described in the Workflow
overview vignette.

#### Units and reporting basis

Unless otherwise stated, cowfootR reports: - **Absolute emissions** as
**annual farm totals** in **kg CO₂eq per year (kg CO₂eq yr⁻¹)**, within
the selected system boundaries. - **Milk intensity** as **kg CO₂eq per
kg FPCM** (FPCM computed following IDF). - **Area intensity** as **kg
CO₂eq per hectare (kg CO₂eq ha⁻¹ yr⁻¹)**.

### Step 2: Calculate emissions by source

Each emission source is calculated using a dedicated function. All
functions return structured objects with emissions expressed in kg
CO₂eq.All functions return structured objects with emissions expressed
as **kg CO₂eq yr⁻¹** (annual totals), unless stated otherwise.

#### Enteric fermentation

Enteric fermentation accounts for methane (CH₄) produced during ruminal
digestion.

``` r
enteric <- calc_emissions_enteric(
  n_animals = 100,
  cattle_category = "dairy_cows",
  boundaries = boundaries
)
enteric
#> $source
#> [1] "enteric"
#> 
#> $category
#> [1] "dairy_cows"
#> 
#> $production_system
#> [1] "mixed"
#> 
#> $ch4_kg
#> [1] 11500
#> 
#> $co2eq_kg
#> [1] 312800
#> 
#> $units_ch4
#> [1] "kg CH4 yr-1"
#> 
#> $units_co2eq
#> [1] "kg CO2eq yr-1"
#> 
#> $emission_factors
#> $emission_factors$emission_factor_ch4
#> [1] 115
#> 
#> $emission_factors$ym_percent
#> [1] 6.5
#> 
#> $emission_factors$gwp_ch4
#> [1] 27.2
#> 
#> $emission_factors$method_used
#> [1] "Tier 1"
#> 
#> 
#> $inputs
#> $inputs$n_animals
#> [1] 100
#> 
#> $inputs$avg_body_weight
#> [1] 550
#> 
#> $inputs$avg_milk_yield
#> [1] 6000
#> 
#> $inputs$dry_matter_intake
#> NULL
#> 
#> $inputs$feed_inputs
#> NULL
#> 
#> $inputs$tier
#> [1] 1
#> 
#> 
#> $methodology
#> [1] "IPCC Tier 1 (default factors)"
#> 
#> $standards
#> [1] "IPCC 2019 Refinement, IDF 2022"
#> 
#> $date
#> [1] "2026-01-13"
#> 
#> $per_animal
#> $per_animal$ch4_kg
#> [1] 115
#> 
#> $per_animal$co2eq_kg
#> [1] 3128
#> 
#> $per_animal$milk_intensity_kg_co2eq_per_kg_milk
#> [1] 0.5213
```

#### Manure management

This includes CH₄ and N₂O emissions from manure handling systems.

``` r
manure <- calc_emissions_manure(
  n_cows = 100,
  boundaries = boundaries
)
manure
#> $source
#> [1] "manure"
#> 
#> $system
#> [1] "pasture"
#> 
#> $tier
#> [1] 1
#> 
#> $climate
#> [1] "temperate"
#> 
#> $ch4_kg
#> [1] 150
#> 
#> $n2o_direct_kg
#> [1] 314.29
#> 
#> $n2o_indirect_kg
#> [1] 0
#> 
#> $n2o_total_kg
#> [1] 314.29
#> 
#> $co2eq_kg
#> [1] 89880
#> 
#> $units
#> $units$ch4_kg
#> [1] "kg CH4 yr-1"
#> 
#> $units$n2o_kg
#> [1] "kg N2O yr-1"
#> 
#> $units$co2eq_kg
#> [1] "kg CO2eq yr-1"
#> 
#> 
#> $emission_factors
#> $emission_factors$ef_ch4
#> [1] 1.5
#> 
#> $emission_factors$ef_n2o_direct
#> [1] 0.02
#> 
#> $emission_factors$gwp_ch4
#> [1] 27.2
#> 
#> $emission_factors$gwp_n2o
#> [1] 273
#> 
#> 
#> $inputs
#> $inputs$n_cows
#> [1] 100
#> 
#> $inputs$n_excreted
#> [1] 100
#> 
#> $inputs$manure_system
#> [1] "pasture"
#> 
#> $inputs$include_indirect
#> [1] FALSE
#> 
#> $inputs$avg_body_weight
#> [1] NA
#> 
#> $inputs$diet_digestibility
#> [1] NA
#> 
#> $inputs$retention_days
#> NULL
#> 
#> $inputs$system_temperature
#> NULL
#> 
#> 
#> $methodology
#> [1] "IPCC Tier 1 (default emission factors)"
#> 
#> $standards
#> [1] "IPCC 2019 Refinement, IDF 2022"
#> 
#> $date
#> [1] "2026-01-13"
#> 
#> $per_cow
#> $per_cow$ch4_kg
#> [1] 1.5
#> 
#> $per_cow$n2o_kg
#> [1] 3.142857
#> 
#> $per_cow$co2eq_kg
#> [1] 898.8
#> 
#> $per_cow$units
#> $per_cow$units$ch4_kg
#> [1] "kg CH4 yr-1"
#> 
#> $per_cow$units$n2o_kg
#> [1] "kg N2O yr-1"
#> 
#> $per_cow$units$co2eq_kg
#> [1] "kg CO2eq yr-1"
```

#### Soil emissions

Soil emissions mainly originate from nitrogen inputs such as fertilizers
and excreta deposited during grazing.

``` r
soil <- calc_emissions_soil(
  n_fertilizer_synthetic = 1500,
  n_excreta_pasture = 5000,
  area_ha = 120,
  boundaries = boundaries
)
soil
#> $source
#> [1] "soil"
#> 
#> $units
#> $units$n2o_kg
#> [1] "kg N2O yr-1"
#> 
#> $units$co2eq_kg
#> [1] "kg CO2eq yr-1"
#> 
#> 
#> $soil_conditions
#> $soil_conditions$soil_type
#> [1] "well_drained"
#> 
#> $soil_conditions$climate
#> [1] "temperate"
#> 
#> 
#> $nitrogen_inputs
#> $nitrogen_inputs$synthetic_fertilizer_kg_n
#> [1] 1500
#> 
#> $nitrogen_inputs$organic_fertilizer_kg_n
#> [1] 0
#> 
#> $nitrogen_inputs$excreta_pasture_kg_n
#> [1] 5000
#> 
#> $nitrogen_inputs$crop_residues_kg_n
#> [1] 0
#> 
#> $nitrogen_inputs$total_kg_n
#> [1] 6500
#> 
#> 
#> $emissions_breakdown
#> $emissions_breakdown$direct_n2o_kg
#> [1] 102.143
#> 
#> $emissions_breakdown$indirect_volatilization_n2o_kg
#> [1] 18.071
#> 
#> $emissions_breakdown$indirect_leaching_n2o_kg
#> [1] 22.982
#> 
#> $emissions_breakdown$total_indirect_n2o_kg
#> [1] 41.054
#> 
#> $emissions_breakdown$total_n2o_kg
#> [1] 143.196
#> 
#> 
#> $co2eq_kg
#> [1] 39092.62
#> 
#> $emission_factors
#> $emission_factors$ef_direct
#> [1] 0.01
#> 
#> $emission_factors$ef_volatilization
#> [1] 0.01
#> 
#> $emission_factors$ef_leaching
#> [1] 0.0075
#> 
#> $emission_factors$gwp_n2o
#> [1] 273
#> 
#> $emission_factors$factors_source
#> [1] "IPCC-style defaults (temperate, well_drained)"
#> 
#> 
#> $methodology
#> [1] "Tier 1-style (direct + indirect)"
#> 
#> $standards
#> [1] "IPCC 2019 Refinement, IDF 2022"
#> 
#> $date
#> [1] "2026-01-13"
#> 
#> $per_hectare_metrics
#> $per_hectare_metrics$n_input_kg_per_ha
#> [1] 54.2
#> 
#> $per_hectare_metrics$n2o_kg_per_ha
#> [1] 1.193
#> 
#> $per_hectare_metrics$co2eq_kg_per_ha
#> [1] 325.77
#> 
#> $per_hectare_metrics$emission_intensity_kg_co2eq_per_kg_n
#> [1] 6.01
#> 
#> 
#> $source_contributions
#> $source_contributions$synthetic_fertilizer_pct
#> [1] 23.1
#> 
#> $source_contributions$organic_fertilizer_pct
#> [1] 0
#> 
#> $source_contributions$excreta_pasture_pct
#> [1] 76.9
#> 
#> $source_contributions$crop_residues_pct
#> [1] 0
#> 
#> $source_contributions$direct_emissions_pct
#> [1] 71.3
#> 
#> $source_contributions$indirect_emissions_pct
#> [1] 28.7
```

#### Energy use

Energy-related emissions come from fuel combustion and electricity
consumption.

``` r
energy <- calc_emissions_energy(
  diesel_l = 2000,
  electricity_kwh = 5000,
  boundaries = boundaries
)
energy
#> $source
#> [1] "energy"
#> 
#> $units
#> $units$co2_kg
#> [1] "kg CO2 yr-1"
#> 
#> $units$co2eq_kg
#> [1] "kg CO2eq yr-1"
#> 
#> $units$diesel_l
#> [1] "L yr-1"
#> 
#> $units$petrol_l
#> [1] "L yr-1"
#> 
#> $units$lpg_kg
#> [1] "kg yr-1"
#> 
#> $units$natural_gas_m3
#> [1] "m3 yr-1"
#> 
#> $units$electricity_kwh
#> [1] "kWh yr-1"
#> 
#> 
#> $fuel_emissions
#> $fuel_emissions$diesel_co2_kg
#> [1] 5340
#> 
#> $fuel_emissions$petrol_co2_kg
#> [1] 0
#> 
#> $fuel_emissions$lpg_co2_kg
#> [1] 0
#> 
#> $fuel_emissions$natural_gas_co2_kg
#> [1] 0
#> 
#> $fuel_emissions$electricity_co2_kg
#> [1] 400
#> 
#> $fuel_emissions$units
#> $fuel_emissions$units$co2_kg
#> [1] "kg CO2 yr-1"
#> 
#> 
#> 
#> $direct_co2eq_kg
#> [1] 5740
#> 
#> $upstream_co2eq_kg
#> [1] 0
#> 
#> $co2eq_kg
#> [1] 5740
#> 
#> $emission_factors
#> $emission_factors$diesel_kg_co2_per_l
#> [1] 2.67
#> 
#> $emission_factors$petrol_kg_co2_per_l
#> [1] 2.31
#> 
#> $emission_factors$lpg_kg_co2_per_kg
#> [1] 3
#> 
#> $emission_factors$natural_gas_kg_co2_per_m3
#> [1] 2
#> 
#> $emission_factors$electricity_kg_co2_per_kwh
#> [1] 0.08
#> 
#> $emission_factors$electricity_country
#> [1] "UY"
#> 
#> 
#> $inputs
#> $inputs$diesel_l
#> [1] 2000
#> 
#> $inputs$petrol_l
#> [1] 0
#> 
#> $inputs$lpg_kg
#> [1] 0
#> 
#> $inputs$natural_gas_m3
#> [1] 0
#> 
#> $inputs$electricity_kwh
#> [1] 5000
#> 
#> $inputs$include_upstream
#> [1] FALSE
#> 
#> 
#> $methodology
#> [1] "IPCC 2019 emission factors"
#> 
#> $standards
#> [1] "IPCC 2019 Refinement, IDF 2022"
#> 
#> $date
#> [1] "2026-01-13"
#> 
#> $energy_metrics
#> $energy_metrics$electricity_share_pct
#> [1] 7
#> 
#> $energy_metrics$fossil_fuel_share_pct
#> [1] 93
#> 
#> $energy_metrics$co2_intensity_kg_per_mwh
#> [1] 80
```

#### Purchased inputs

This category includes emissions embodied in feeds, fertilizers, and
materials.

``` r
inputs <- calc_emissions_inputs(
  conc_kg = 1000,
  fert_n_kg = 500,
  boundaries = boundaries
)
inputs
#> $source
#> [1] "inputs"
#> 
#> $units
#> $units$co2eq_kg
#> [1] "kg CO2eq yr-1"
#> 
#> $units$conc_kg
#> [1] "kg yr-1"
#> 
#> $units$fert_n_kg
#> [1] "kg N yr-1"
#> 
#> $units$plastic_kg
#> [1] "kg yr-1"
#> 
#> $units$feed_kg
#> [1] "kg DM yr-1"
#> 
#> $units$transport_km
#> [1] "km"
#> 
#> $units$ef_conc
#> [1] "kg CO2e per kg"
#> 
#> $units$ef_fert
#> [1] "kg CO2e per kg N"
#> 
#> $units$ef_plastic
#> [1] "kg CO2e per kg"
#> 
#> $units$ef_feed
#> [1] "kg CO2e per kg DM"
#> 
#> $units$ef_truck
#> [1] "kg CO2e per (kg·km)"
#> 
#> 
#> $emissions_breakdown
#> $emissions_breakdown$concentrate_co2eq_kg
#> [1] 700
#> 
#> $emissions_breakdown$fertilizer_co2eq_kg
#> [1] 3300
#> 
#> $emissions_breakdown$plastic_co2eq_kg
#> [1] 0
#> 
#> $emissions_breakdown$feeds_co2eq_kg
#>  grain_dry  grain_wet     ration byproducts   proteins       corn        soy 
#>          0          0          0          0          0          0          0 
#>      wheat 
#>          0 
#> 
#> $emissions_breakdown$total_feeds_co2eq_kg
#> [1] 0
#> 
#> $emissions_breakdown$transport_adjustment_co2eq_kg
#> [1] 0
#> 
#> 
#> $co2eq_kg
#> [1] 4000
#> 
#> $total_co2eq_kg
#> [1] 4000
#> 
#> $region
#> [1] "global"
#> 
#> $emission_factors_used
#> $emission_factors_used$concentrate
#> $emission_factors_used$concentrate$value
#> [1] 0.7
#> 
#> $emission_factors_used$concentrate$unit
#> [1] "kg CO2e per kg"
#> 
#> 
#> $emission_factors_used$fertilizer
#> $emission_factors_used$fertilizer$value
#> [1] 6.6
#> 
#> $emission_factors_used$fertilizer$type
#> [1] "mixed"
#> 
#> $emission_factors_used$fertilizer$unit
#> [1] "kg CO2e per kg N"
#> 
#> 
#> $emission_factors_used$plastic
#> $emission_factors_used$plastic$value
#> [1] 2.5
#> 
#> $emission_factors_used$plastic$type
#> [1] "mixed"
#> 
#> $emission_factors_used$plastic$unit
#> [1] "kg CO2e per kg"
#> 
#> 
#> $emission_factors_used$feeds
#> $emission_factors_used$feeds$grain_dry
#> $emission_factors_used$feeds$grain_dry$value
#> [1] 0.4
#> 
#> $emission_factors_used$feeds$grain_dry$unit
#> [1] "kg CO2e per kg DM"
#> 
#> 
#> $emission_factors_used$feeds$grain_wet
#> $emission_factors_used$feeds$grain_wet$value
#> [1] 0.3
#> 
#> $emission_factors_used$feeds$grain_wet$unit
#> [1] "kg CO2e per kg DM"
#> 
#> 
#> $emission_factors_used$feeds$ration
#> $emission_factors_used$feeds$ration$value
#> [1] 0.6
#> 
#> $emission_factors_used$feeds$ration$unit
#> [1] "kg CO2e per kg DM"
#> 
#> 
#> $emission_factors_used$feeds$byproducts
#> $emission_factors_used$feeds$byproducts$value
#> [1] 0.15
#> 
#> $emission_factors_used$feeds$byproducts$unit
#> [1] "kg CO2e per kg DM"
#> 
#> 
#> $emission_factors_used$feeds$proteins
#> $emission_factors_used$feeds$proteins$value
#> [1] 1.8
#> 
#> $emission_factors_used$feeds$proteins$unit
#> [1] "kg CO2e per kg DM"
#> 
#> 
#> $emission_factors_used$feeds$corn
#> $emission_factors_used$feeds$corn$value
#> [1] 0.45
#> 
#> $emission_factors_used$feeds$corn$unit
#> [1] "kg CO2e per kg DM"
#> 
#> 
#> $emission_factors_used$feeds$soy
#> $emission_factors_used$feeds$soy$value
#> [1] 2.1
#> 
#> $emission_factors_used$feeds$soy$unit
#> [1] "kg CO2e per kg DM"
#> 
#> 
#> $emission_factors_used$feeds$wheat
#> $emission_factors_used$feeds$wheat$value
#> [1] 0.52
#> 
#> $emission_factors_used$feeds$wheat$unit
#> [1] "kg CO2e per kg DM"
#> 
#> 
#> 
#> $emission_factors_used$transport
#> $emission_factors_used$transport$ef_truck
#> [1] 1e-04
#> 
#> $emission_factors_used$transport$unit
#> [1] "kg CO2e per (kg·km)"
#> 
#> $emission_factors_used$transport$transport_km
#> [1] 0
#> 
#> 
#> $emission_factors_used$region_source
#> [1] "global"
#> 
#> 
#> $inputs_summary
#> $inputs_summary$concentrate_kg
#> [1] 1000
#> 
#> $inputs_summary$fertilizer_n_kg
#> [1] 500
#> 
#> $inputs_summary$plastic_kg
#> [1] 0
#> 
#> $inputs_summary$total_feeds_kg
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg
#> $inputs_summary$feed_breakdown_kg$grain_dry
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$grain_wet
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$ration
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$byproducts
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$proteins
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$corn
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$soy
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$wheat
#> [1] 0
#> 
#> 
#> 
#> $contribution_analysis
#> $contribution_analysis$concentrate_pct
#> [1] 17.5
#> 
#> $contribution_analysis$fertilizer_pct
#> [1] 82.5
#> 
#> $contribution_analysis$plastic_pct
#> [1] 0
#> 
#> $contribution_analysis$feeds_pct
#> [1] 0
#> 
#> $contribution_analysis$transport_pct
#> [1] 0
#> 
#> 
#> $uncertainty
#> NULL
#> 
#> $methodology
#> [1] "Regional emission factors with optional uncertainty analysis"
#> 
#> $standards
#> [1] "IDF 2022; generic LCI sources"
#> 
#> $date
#> [1] "2026-01-13"
```

### Step 3: Aggregate total emissions

All emission sources are combined using calc_total_emissions().

``` r
total_emissions <- calc_total_emissions(
  enteric,
  manure,
  soil,
  energy,
  inputs
)
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
#> Calculated on: 2026-01-13
```

### Step 4: Calculate intensity metrics

Intensity metrics relate total emissions to production or land use.

#### Milk intensity

Emissions per unit of milk are expressed as kg CO₂eq per kg of fat- and
protein-corrected milk (FPCM).

``` r
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
#> Calculated on: 2026-01-13
```

#### Area intensity

Emissions per hectare are useful for land-based comparisons.

``` r
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
#> Calculated on: 2026-01-13
```

### Interpreting results

In most dairy systems: - Enteric fermentation is the largest emission
source - Inputs and soils are often the second-largest contributors -
Energy use typically represents a smaller share

Results should always be interpreted considering: - data quality -
system boundaries - production system characteristics

### What’s next?

This vignette covered the minimum workflow needed to use cowfootR.

Next steps: - See Introduction to Dairy Life Cycle Assessment for
conceptual background - See Single Farm Analysis for a more detailed
example - See Complete Parameter Reference Guide for full parameter
documentation - See Workflow overview for batch processing and reporting

### Summary

    -   cowfootR follows a modular, step-by-step workflow
    -   Each emission source is calculated independently
    -   Results can be expressed as total emissions or intensities
    -   This vignette provides a starting point; advanced topics are covered elsewhere
