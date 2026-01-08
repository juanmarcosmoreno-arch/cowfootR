# Calculate enteric methane emissions

Estimates enteric methane (CH4) emissions from cattle using IPCC Tier 1
or Tier 2 approaches with practical defaults for dairy systems.

## Usage

``` r
calc_emissions_enteric(
  n_animals,
  cattle_category = "dairy_cows",
  production_system = "mixed",
  avg_milk_yield = 6000,
  avg_body_weight = NULL,
  dry_matter_intake = NULL,
  feed_inputs = NULL,
  ym_percent = 6.5,
  emission_factor_ch4 = NULL,
  tier = 1L,
  gwp_ch4 = 27.2,
  boundaries = NULL
)
```

## Arguments

- n_animals:

  Numeric scalar \> 0. Number of animals.

- cattle_category:

  Character. One of "dairy_cows", "heifers", "calves", "bulls". Default
  = "dairy_cows".

- production_system:

  Character. One of "intensive", "extensive", "mixed". Default =
  "mixed".

- avg_milk_yield:

  Numeric \>= 0. Average annual milk yield per cow (kg/year). Default
  = 6000. Used in Tier 2 fallback for dairy cows.

- avg_body_weight:

  Numeric \> 0. Average live weight (kg). If NULL, a category-specific
  default is used (e.g. 550 kg for dairy cows).

- dry_matter_intake:

  Numeric \> 0. Dry matter intake (kg/animal/day). If provided (Tier 2),
  overrides body-weight/energy-based estimation.

- feed_inputs:

  Named numeric vector/list with feed DM amounts in kg/year per herd
  (e.g., grain_dry, grain_wet, byproducts, proteins). Optional. If given
  and `dry_matter_intake` is NULL, DMI is inferred as
  `sum(feed_inputs)/(n_animals*365)`.

- ym_percent:

  Numeric in (0, 100\]. Methane conversion factor Ym (% of GE to CH4).
  Default = 6.5.

- emission_factor_ch4:

  Numeric \> 0. If provided, CH4 EF (kg CH4/head/year) is used directly;
  otherwise it is calculated (Tier 1 or Tier 2).

- tier:

  Integer 1 or 2. Default = 1.

- gwp_ch4:

  Numeric. GWP for CH4 (100-yr, AR6). Default = 27.2.

- boundaries:

  Optional list from
  [`set_system_boundaries()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/set_system_boundaries.md).

## Value

List with CH4 (kg), CO2eq (kg), inputs, factors, and metadata. Includes
`co2eq_kg` for compatibility with
[`calc_total_emissions()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_total_emissions.md).

## Examples

``` r
# \donttest{
# Tier 1, mixed dairy cows
calc_emissions_enteric(n_animals = 100)
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
#> [1] "2026-01-08"
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
#> 
#> 

# Tier 2 with explicit DMI
calc_emissions_enteric(
  n_animals = 120, tier = 2, avg_milk_yield = 7500, dry_matter_intake = 18
)
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
#> [1] 16989.91
#> 
#> $co2eq_kg
#> [1] 462125.7
#> 
#> $emission_factors
#> $emission_factors$emission_factor_ch4
#> [1] 141.583
#> 
#> $emission_factors$ym_percent
#> [1] 6.5
#> 
#> $emission_factors$gwp_ch4
#> [1] 27.2
#> 
#> $emission_factors$method_used
#> [1] "Tier 2"
#> 
#> 
#> $inputs
#> $inputs$n_animals
#> [1] 120
#> 
#> $inputs$avg_body_weight
#> [1] 550
#> 
#> $inputs$avg_milk_yield
#> [1] 7500
#> 
#> $inputs$dry_matter_intake
#> [1] 18
#> 
#> $inputs$feed_inputs
#> NULL
#> 
#> $inputs$tier
#> [1] 2
#> 
#> 
#> $methodology
#> [1] "IPCC Tier 2 (GE-based where possible)"
#> 
#> $standards
#> [1] "IPCC 2019 Refinement, IDF 2022"
#> 
#> $date
#> [1] "2026-01-08"
#> 
#> $per_animal
#> $per_animal$ch4_kg
#> [1] 141.583
#> 
#> $per_animal$co2eq_kg
#> [1] 3851.047
#> 
#> $per_animal$milk_intensity_kg_co2eq_per_kg_milk
#> [1] 0.5135
#> 
#> 

# Boundary exclusion: enteric not included
b <- list(include = c("manure", "energy"))
calc_emissions_enteric(100, boundaries = b)$co2eq_kg  # NULL → excluded
#> NULL
# }
```
