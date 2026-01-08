# Print method for cf_area_intensity objects

Print method for cf_area_intensity objects

## Usage

``` r
# S3 method for class 'cf_area_intensity'
print(x, ...)
```

## Arguments

- x:

  A cf_area_intensity object

- ...:

  Additional arguments (ignored)

## Value

No return value, called for side effects. Prints formatted area
intensity information to the console and invisibly returns the input
object.

The input object `x`, invisibly.

## Examples

``` r
x <- list(
  intensity_per_total_ha = 900,
  intensity_per_productive_ha = 1100,
  land_use_efficiency = 0.92,
  total_emissions_co2eq = 108000,
  area_total_ha = 120,
  area_productive_ha = 110,
  date = Sys.Date()
)
class(x) <- "cf_area_intensity"
print(x)
#> Carbon Footprint Area Intensity
#> ===============================
#> Intensity (total area): 900 kg CO2eq/ha
#> Intensity (productive area): 1100 kg CO2eq/ha
#> 
#> Area summary:
#>  Total area: 120 ha
#>  Productive area: 110 ha
#>  Land use efficiency: 92%
#> 
#> Total emissions: 108,000 kg CO2eq
#> Calculated on: 2026-01-08 
```
