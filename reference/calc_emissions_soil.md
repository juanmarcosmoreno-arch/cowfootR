# Calculate soil N2O emissions

Estimates direct and indirect N2O emissions from soils due to
fertilisation, excreta deposition and crop residues, following a Tier
1-style IPCC approach.

## Usage

``` r
calc_emissions_soil(
  n_fertilizer_synthetic = 0,
  n_fertilizer_organic = 0,
  n_excreta_pasture = 0,
  n_crop_residues = 0,
  area_ha = NULL,
  soil_type = "well_drained",
  climate = "temperate",
  ef_direct = NULL,
  include_indirect = TRUE,
  gwp_n2o = 273,
  boundaries = NULL
)
```

## Arguments

- n_fertilizer_synthetic:

  Numeric. Synthetic N fertiliser applied (kg N/year). Default = 0.

- n_fertilizer_organic:

  Numeric. Organic N fertiliser applied (kg N/year). Default = 0.

- n_excreta_pasture:

  Numeric. N excreted directly on pasture (kg N/year). Default = 0.

- n_crop_residues:

  Numeric. N in crop residues returned to soil (kg N/year). Default = 0.

- area_ha:

  Numeric. Total farm area (ha). Optional, for per-hectare metrics.

- soil_type:

  Character. "well_drained" or "poorly_drained". Default =
  "well_drained".

- climate:

  Character. "temperate" or "tropical". Default = "temperate".

- ef_direct:

  Numeric. Direct EF for N2O-N (kg N2O-N per kg N input). If NULL, uses
  IPCC-style values by soil/climate.

- include_indirect:

  Logical. Include indirect N2O (volatilisation + leaching)? Default =
  TRUE.

- gwp_n2o:

  Numeric. GWP of N2O. Default = 273 (IPCC AR6).

- boundaries:

  Optional. Object from
  [`set_system_boundaries()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/set_system_boundaries.md).
  If soil is excluded, returns `co2eq_kg = 0`.

## Value

A list with at least `source="soil"` and `co2eq_kg` (numeric), plus
detailed breakdown metadata when included by boundaries.

## Details

IMPORTANT: When system boundaries exclude soil, this function must
return a list with `source = "soil"` and `co2eq_kg = 0` (numeric zero)
to match partial-boundaries integration tests.

## Examples

``` r
# \donttest{
# Direct + indirect (default), temperate, well-drained
calc_emissions_soil(
  n_fertilizer_synthetic = 2500,
  n_fertilizer_organic   = 500,
  n_excreta_pasture      = 1200,
  n_crop_residues        = 300,
  area_ha                = 150
)
#> $source
#> [1] "soil"
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
#> [1] 2500
#> 
#> $nitrogen_inputs$organic_fertilizer_kg_n
#> [1] 500
#> 
#> $nitrogen_inputs$excreta_pasture_kg_n
#> [1] 1200
#> 
#> $nitrogen_inputs$crop_residues_kg_n
#> [1] 300
#> 
#> $nitrogen_inputs$total_kg_n
#> [1] 4500
#> 
#> 
#> $emissions_breakdown
#> $emissions_breakdown$direct_n2o_kg
#> [1] 70.714
#> 
#> $emissions_breakdown$indirect_volatilization_n2o_kg
#> [1] 9.271
#> 
#> $emissions_breakdown$indirect_leaching_n2o_kg
#> [1] 15.911
#> 
#> $emissions_breakdown$total_indirect_n2o_kg
#> [1] 25.182
#> 
#> $emissions_breakdown$total_n2o_kg
#> [1] 95.896
#> 
#> 
#> $co2eq_kg
#> [1] 26179.72
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
#> [1] "2025-11-10"
#> 
#> $per_hectare_metrics
#> $per_hectare_metrics$n_input_kg_per_ha
#> [1] 30
#> 
#> $per_hectare_metrics$n2o_kg_per_ha
#> [1] 0.639
#> 
#> $per_hectare_metrics$co2eq_kg_per_ha
#> [1] 174.53
#> 
#> $per_hectare_metrics$emission_intensity_kg_co2eq_per_kg_n
#> [1] 5.82
#> 
#> 
#> $source_contributions
#> $source_contributions$synthetic_fertilizer_pct
#> [1] 55.6
#> 
#> $source_contributions$organic_fertilizer_pct
#> [1] 11.1
#> 
#> $source_contributions$excreta_pasture_pct
#> [1] 26.7
#> 
#> $source_contributions$crop_residues_pct
#> [1] 6.7
#> 
#> $source_contributions$direct_emissions_pct
#> [1] 73.7
#> 
#> $source_contributions$indirect_emissions_pct
#> [1] 26.3
#> 
#> 

# Direct-only
calc_emissions_soil(n_fertilizer_synthetic = 2000, include_indirect = FALSE)
#> $source
#> [1] "soil"
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
#> [1] 2000
#> 
#> $nitrogen_inputs$organic_fertilizer_kg_n
#> [1] 0
#> 
#> $nitrogen_inputs$excreta_pasture_kg_n
#> [1] 0
#> 
#> $nitrogen_inputs$crop_residues_kg_n
#> [1] 0
#> 
#> $nitrogen_inputs$total_kg_n
#> [1] 2000
#> 
#> 
#> $emissions_breakdown
#> $emissions_breakdown$direct_n2o_kg
#> [1] 31.429
#> 
#> $emissions_breakdown$indirect_volatilization_n2o_kg
#> [1] 0
#> 
#> $emissions_breakdown$indirect_leaching_n2o_kg
#> [1] 0
#> 
#> $emissions_breakdown$total_indirect_n2o_kg
#> [1] 0
#> 
#> $emissions_breakdown$total_n2o_kg
#> [1] 31.429
#> 
#> 
#> $co2eq_kg
#> [1] 8580
#> 
#> $emission_factors
#> $emission_factors$ef_direct
#> [1] 0.01
#> 
#> $emission_factors$ef_volatilization
#> [1] NA
#> 
#> $emission_factors$ef_leaching
#> [1] NA
#> 
#> $emission_factors$gwp_n2o
#> [1] 273
#> 
#> $emission_factors$factors_source
#> [1] "IPCC-style defaults (temperate, well_drained)"
#> 
#> 
#> $methodology
#> [1] "Tier 1-style (direct only)"
#> 
#> $standards
#> [1] "IPCC 2019 Refinement, IDF 2022"
#> 
#> $date
#> [1] "2025-11-10"
#> 
#> $source_contributions
#> $source_contributions$synthetic_fertilizer_pct
#> [1] 100
#> 
#> $source_contributions$organic_fertilizer_pct
#> [1] 0
#> 
#> $source_contributions$excreta_pasture_pct
#> [1] 0
#> 
#> $source_contributions$crop_residues_pct
#> [1] 0
#> 
#> $source_contributions$direct_emissions_pct
#> [1] 100
#> 
#> $source_contributions$indirect_emissions_pct
#> [1] 0
#> 
#> 

# Boundary exclusion example
b <- list(include = c("energy", "manure"))  # soil not included
calc_emissions_soil(n_fertilizer_synthetic = 1000, boundaries = b)$co2eq_kg  # 0
#> [1] 0
# }
```
