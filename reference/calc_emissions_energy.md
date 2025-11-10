# Calculate energy-related emissions

Estimates CO2 emissions from fossil fuel use and electricity consumption
on dairy farms following IDF/IPCC methodology.

## Usage

``` r
calc_emissions_energy(
  diesel_l = 0,
  petrol_l = 0,
  lpg_kg = 0,
  natural_gas_m3 = 0,
  electricity_kwh = 0,
  country = "UY",
  ef_diesel = 2.67,
  ef_petrol = 2.31,
  ef_lpg = 3,
  ef_natural_gas = 2,
  ef_electricity = NULL,
  include_upstream = FALSE,
  energy_breakdown = NULL,
  boundaries = NULL
)
```

## Arguments

- diesel_l:

  Numeric. Diesel consumption (liters/year). Default = 0.

- petrol_l:

  Numeric. Petrol/gasoline consumption (liters/year). Default = 0.

- lpg_kg:

  Numeric. LPG/propane consumption (kg/year). Default = 0.

- natural_gas_m3:

  Numeric. Natural gas consumption (m³/year). Default = 0.

- electricity_kwh:

  Numeric. Electricity consumption (kWh/year). Default = 0.

- country:

  Character. Country code for electricity grid factors. Default = "UY"
  (Uruguay). Options include "UY", "AR", "BR", "NZ", "US", etc.

- ef_diesel:

  Numeric. Emission factor for diesel (kg CO2/liter). Default = 2.67
  (IPCC 2019, combustion).

- ef_petrol:

  Numeric. Emission factor for petrol (kg CO2/liter). Default = 2.31
  (IPCC 2019).

- ef_lpg:

  Numeric. Emission factor for LPG (kg CO2/kg). Default = 3.0 (IPCC
  2019).

- ef_natural_gas:

  Numeric. Emission factor for natural gas (kg CO2/m³). Default = 2.0
  (IPCC 2019).

- ef_electricity:

  Numeric. Emission factor for electricity (kg CO2/kWh). If NULL, uses
  country-specific grid factors.

- include_upstream:

  Logical. Include upstream emissions from fuel production? Default =
  FALSE (combustion only).

- energy_breakdown:

  Optional. Detailed breakdown by equipment/use (list or data.frame). If
  list, each element can include diesel_l, petrol_l, lpg_kg,
  natural_gas_m3, electricity_kwh.

- boundaries:

  Optional. An object from
  [`set_system_boundaries()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/set_system_boundaries.md).
  If "energy" is not included, returns an excluded record.

## Value

A list with detailed emissions by fuel type, total (co2eq_kg), metadata,
and (if provided) breakdown by use. Compatible with
[`calc_total_emissions()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_total_emissions.md).

## Examples

``` r
# Minimal, fast example (<<1s)
res <- calc_emissions_energy(
  diesel_l = 10,
  electricity_kwh = 100,
  country = "UY"
)
print(res$co2eq_kg)
#> [1] 34.7
```
