# Calculate total emissions (robust and boundary-aware)

Aggregates results from different sources (enteric, manure, soil,
energy, inputs) even if they don't use exactly the same field name for
the total.

## Usage

``` r
calc_total_emissions(...)
```

## Arguments

- ...:

  Results from `calc_emissions_*()` functions (lists).

## Value

Object of class `cf_total` including:

- `total_co2eq`: total absolute emissions (kg CO2eq yr-1)

- `co2eq_kg`: alias of total absolute emissions (kg CO2eq yr-1)

- `total_co2eq_kg`: alias of total absolute emissions (kg CO2eq yr-1)

- `breakdown`: named numeric vector by source (kg CO2eq yr-1)

- `by_source`: data.frame with `source`, `co2eq_kg`, and `units`

- `units_total`, `units_by_source`: unit strings

- `units`: list of unit strings (at least `units$co2eq_kg`)

## Details

IMPORTANT: If a source explicitly reports `co2eq_kg = NULL` (e.g.
excluded by system boundaries), it is treated as zero and no fallback
summation is attempted.
