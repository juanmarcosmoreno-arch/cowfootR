# Calculate carbon footprint intensity per hectare

Computes emissions intensity per unit of land area for dairy farm
analysis.

## Usage

``` r
calc_intensity_area(
  total_emissions,
  area_total_ha,
  area_productive_ha = NULL,
  area_breakdown = NULL,
  validate_area_sum = TRUE
)
```

## Arguments

- total_emissions:

  Numeric or cf_total object. Total emissions in kg CO2eq (from
  [`calc_total_emissions()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_total_emissions.md))
  or the object itself.

- area_total_ha:

  Numeric. Total farm area in hectares.

- area_productive_ha:

  Numeric. Productive/utilized area in hectares. If NULL, uses total
  area. Default = NULL.

- area_breakdown:

  Named list or named numeric vector. Optional detailed area breakdown
  by land use type. Names should be descriptive (e.g.,
  "pasture_permanent", "crops_feed").

- validate_area_sum:

  Logical. Check if area breakdown sums to total? Default = TRUE.

## Value

A list of class "cf_area_intensity" with intensity metrics and area
analysis.

## Details

The area_breakdown parameter allows detailed tracking by land use:

    area_breakdown = list(
      pasture_permanent = 80,
      pasture_temporary = 20,
      crops_feed = 15,
      crops_cash = 5,
      infrastructure = 2,
      woodland = 8
    )

## Examples

``` r
# Basic calculation
calc_intensity_area(total_emissions = 85000, area_total_ha = 120)
#> Carbon Footprint Area Intensity
#> ===============================
#> Intensity (total area): 708.33 kg CO2eq/ha
#> Intensity (productive area): 708.33 kg CO2eq/ha
#> 
#> Area summary:
#>  Total area: 120 ha
#>  Productive area: 120 ha
#>  Land use efficiency: 100%
#> 
#> Total emissions: 85,000 kg CO2eq
#> Calculated on: 2025-11-10 

# With productive area distinction
calc_intensity_area(
  total_emissions = 95000,
  area_total_ha = 150,
  area_productive_ha = 135
)
#> Carbon Footprint Area Intensity
#> ===============================
#> Intensity (total area): 633.33 kg CO2eq/ha
#> Intensity (productive area): 703.7 kg CO2eq/ha
#> 
#> Area summary:
#>  Total area: 150 ha
#>  Productive area: 135 ha
#>  Land use efficiency: 90%
#> 
#> Total emissions: 95,000 kg CO2eq
#> Calculated on: 2025-11-10 

# With area breakdown
area_detail <- list(
  pasture_permanent = 80,
  pasture_temporary = 25,
  crops_feed = 20,
  infrastructure = 3,
  woodland = 7
)
calc_intensity_area(
  total_emissions = 88000,
  area_total_ha = 135,
  area_breakdown = area_detail
)
#> Carbon Footprint Area Intensity
#> ===============================
#> Intensity (total area): 651.85 kg CO2eq/ha
#> Intensity (productive area): 651.85 kg CO2eq/ha
#> 
#> Area summary:
#>  Total area: 135 ha
#>  Productive area: 135 ha
#>  Land use efficiency: 100%
#> 
#> Land use breakdown:
#>  pasture permanent: 80.0 ha (59.3%) -> 52148 kg CO2eq
#>  pasture temporary: 25.0 ha (18.5%) -> 16296 kg CO2eq
#>  crops feed: 20.0 ha (14.8%) -> 13037 kg CO2eq
#>  infrastructure: 3.0 ha (2.2%) -> 1956 kg CO2eq
#>  woodland: 7.0 ha (5.2%) -> 4563 kg CO2eq
#> 
#> Total emissions: 88,000 kg CO2eq
#> Calculated on: 2025-11-10 

# Using with calc_total_emissions output
# \donttest{
# b <- set_system_boundaries("farm_gate")
# e1 <- calc_emissions_enteric(100, boundaries = b)
# e2 <- calc_emissions_manure(100, boundaries = b)
# tot <- calc_total_emissions(e1, e2)
# calc_intensity_area(tot, area_total_ha = 120)
# }
```
