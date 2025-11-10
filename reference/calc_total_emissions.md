# Calculate total emissions (robust and boundary-aware)

Aggregates results from different sources (enteric, manure, soil,
energy, inputs) even if they don't use exactly the same field name for
the total. IMPORTANT: If a source explicitly reports `co2eq_kg = NULL`
(e.g. excluded by system boundaries), it is treated as zero and no
fallback summation is attempted.

## Usage

``` r
calc_total_emissions(...)
```

## Arguments

- ...:

  Results from `calc_emissions_*()` functions (lists).

## Value

Object "cf_total" with breakdown (kg CO2eq by source) and total.

## Examples

``` r
# \donttest{
# hipotético: totales ya agregados por fuente
enteric <- list(co2eq_kg = 45000, source = "enteric")
manure  <- list(co2eq_kg = 12000, source = "manure")
soil    <- list(co2eq_kg = 18000, source = "soil")
energy  <- list(co2eq_kg =  8000, source = "energy")

tot <- calc_total_emissions(enteric = enteric, manure = manure, soil = soil, energy = energy)
# print(tot)
# }
```
