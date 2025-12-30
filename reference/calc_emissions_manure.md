# Calculate manure management emissions (Tier 1 & Tier 2)

Estimates CH4 and N2O emissions from manure management using IPCC Tier 1
or Tier 2 methodology with practical settings for dairy systems.

## Usage

``` r
calc_emissions_manure(
  n_cows,
  manure_system = "pasture",
  tier = 1L,
  ef_ch4 = NULL,
  n_excreted = 100,
  ef_n2o_direct = 0.02,
  include_indirect = FALSE,
  climate = "temperate",
  avg_body_weight = 600,
  diet_digestibility = 0.65,
  protein_intake_kg = NULL,
  retention_days = NULL,
  system_temperature = NULL,
  gwp_ch4 = 27.2,
  gwp_n2o = 273,
  boundaries = NULL
)
```

## Arguments

- n_cows:

  Numeric scalar \> 0. Number of dairy cows.

- manure_system:

  Character. One of "pasture", "solid_storage", "liquid_storage",
  "anaerobic_digester". Default = "pasture".

- tier:

  Integer. IPCC tier (1 or 2). Default = 1.

- ef_ch4:

  Numeric. CH4 EF (kg CH4/cow/year). If `NULL`, system-specific defaults
  are used (Tier 1 only).

- n_excreted:

  Numeric. N excreted per cow per year (kg N). Default = 100. In Tier 2
  it may be recalculated if protein intake is provided.

- ef_n2o_direct:

  Numeric. Direct N2O-N EF (kg N2O-N per kg N). Default = 0.02.

- include_indirect:

  Logical. Include indirect N2O (volatilization + leaching)? Default =
  FALSE.

- climate:

  Character. One of "cold", "temperate", "warm". Default = "temperate"
  (Tier 2).

- avg_body_weight:

  Numeric. Average live weight (kg). Default = 600 (Tier 2).

- diet_digestibility:

  Numeric in (0, 1\]. Apparent digestibility. Default = 0.65 (Tier 2).

- protein_intake_kg:

  Numeric. Daily protein intake (kg/day). If provided, Tier 2 can refine
  N excretion.

- retention_days:

  Numeric. Days manure remains in system (Tier 2 adjustment).

- system_temperature:

  Numeric. Average system temperature (Tier 2 adjustment).

- gwp_ch4:

  Numeric. GWP for CH4 (AR6). Default = 27.2.

- gwp_n2o:

  Numeric. GWP for N2O (AR6). Default = 273.

- boundaries:

  Optional list from
  [`set_system_boundaries()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/set_system_boundaries.md).

## Value

A list with CH4 (kg), N2O (kg), CO2eq (kg), metadata, and per-cow
metrics. The returned object includes a `co2eq_kg` field compatible with
[`calc_total_emissions()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_total_emissions.md).

## Examples

``` r
# \donttest{
# Tier 1, liquid storage
calc_emissions_manure(n_cows = 120, manure_system = "liquid_storage")
#> $source
#> [1] "manure"
#> 
#> $system
#> [1] "liquid_storage"
#> 
#> $tier
#> [1] 1
#> 
#> $climate
#> [1] "temperate"
#> 
#> $ch4_kg
#> [1] 3600
#> 
#> $n2o_direct_kg
#> [1] 377.14
#> 
#> $n2o_indirect_kg
#> [1] 0
#> 
#> $n2o_total_kg
#> [1] 377.14
#> 
#> $co2eq_kg
#> [1] 200880
#> 
#> $emission_factors
#> $emission_factors$ef_ch4
#> [1] 30
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
#> [1] 120
#> 
#> $inputs$n_excreted
#> [1] 100
#> 
#> $inputs$manure_system
#> [1] "liquid_storage"
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
#> 
#> $methodology
#> [1] "IPCC Tier 1 (default emission factors)"
#> 
#> $standards
#> [1] "IPCC 2019 Refinement, IDF 2022"
#> 
#> $date
#> [1] "2025-12-30"
#> 
#> $per_cow
#> $per_cow$ch4_kg
#> [1] 30
#> 
#> $per_cow$n2o_kg
#> [1] 3.142857
#> 
#> $per_cow$co2eq_kg
#> [1] 1674
#> 
#> 

# Tier 1 with indirect N2O
calc_emissions_manure(n_cows = 120, manure_system = "solid_storage", include_indirect = TRUE)
#> $source
#> [1] "manure"
#> 
#> $system
#> [1] "solid_storage"
#> 
#> $tier
#> [1] 1
#> 
#> $climate
#> [1] "temperate"
#> 
#> $ch4_kg
#> [1] 2400
#> 
#> $n2o_direct_kg
#> [1] 377.14
#> 
#> $n2o_indirect_kg
#> [1] 80.14
#> 
#> $n2o_total_kg
#> [1] 457.29
#> 
#> $co2eq_kg
#> [1] 190119
#> 
#> $emission_factors
#> $emission_factors$ef_ch4
#> [1] 20
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
#> [1] 120
#> 
#> $inputs$n_excreted
#> [1] 100
#> 
#> $inputs$manure_system
#> [1] "solid_storage"
#> 
#> $inputs$include_indirect
#> [1] TRUE
#> 
#> $inputs$avg_body_weight
#> [1] NA
#> 
#> $inputs$diet_digestibility
#> [1] NA
#> 
#> 
#> $methodology
#> [1] "IPCC Tier 1 (default emission factors)"
#> 
#> $standards
#> [1] "IPCC 2019 Refinement, IDF 2022"
#> 
#> $date
#> [1] "2025-12-30"
#> 
#> $per_cow
#> $per_cow$ch4_kg
#> [1] 20
#> 
#> $per_cow$n2o_kg
#> [1] 3.810714
#> 
#> $per_cow$co2eq_kg
#> [1] 1584.325
#> 
#> 

# Tier 2 (VS_B0_MCF approach) with refinements
calc_emissions_manure(
  n_cows = 100, manure_system = "liquid_storage", tier = 2,
  avg_body_weight = 580, diet_digestibility = 0.68, climate = "temperate",
  protein_intake_kg = 3.2, include_indirect = TRUE
)
#> $source
#> [1] "manure"
#> 
#> $system
#> [1] "liquid_storage"
#> 
#> $tier
#> [1] 2
#> 
#> $climate
#> [1] "temperate"
#> 
#> $ch4_kg
#> [1] 52573.48
#> 
#> $n2o_direct_kg
#> [1] 440.5
#> 
#> $n2o_indirect_kg
#> [1] 80.94
#> 
#> $n2o_total_kg
#> [1] 521.45
#> 
#> $co2eq_kg
#> [1] 1572353
#> 
#> $emission_factors
#> $emission_factors$ef_ch4
#> [1] NA
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
#> [1] 140.16
#> 
#> $inputs$manure_system
#> [1] "liquid_storage"
#> 
#> $inputs$include_indirect
#> [1] TRUE
#> 
#> $inputs$avg_body_weight
#> [1] 580
#> 
#> $inputs$diet_digestibility
#> [1] 0.68
#> 
#> 
#> $methodology
#> [1] "IPCC Tier 2 (VS_B0_MCF calculation)"
#> 
#> $standards
#> [1] "IPCC 2019 Refinement, IDF 2022"
#> 
#> $date
#> [1] "2025-12-30"
#> 
#> $per_cow
#> $per_cow$ch4_kg
#> [1] 525.7348
#> 
#> $per_cow$n2o_kg
#> [1] 5.214453
#> 
#> $per_cow$co2eq_kg
#> [1] 15723.53
#> 
#> 
#> $tier2_details
#> $tier2_details$vs_kg_per_day
#> [1] 30.624
#> 
#> $tier2_details$b0_used
#> [1] 0.18
#> 
#> $tier2_details$mcf_used
#> [1] 39
#> 
#> 
# }
```
