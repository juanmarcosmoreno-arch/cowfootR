# Print method for cf_intensity objects

Print method for cf_intensity objects

## Usage

``` r
# S3 method for class 'cf_intensity'
print(x, ...)
```

## Arguments

- x:

  A cf_intensity object

- ...:

  Additional arguments (ignored)

## Value

No return value, called for side effects. Prints formatted carbon
footprint intensity information to the console and invisibly returns the
input object.

The input object `x`, invisibly.

## Examples

``` r
# \donttest{
x <- list(
  intensity_co2eq_per_kg_fpcm = 0.9,
  total_emissions_co2eq = 85000,
  milk_production_litres = 750000,
  milk_production_kg = 750000 * 1.03,
  fpcm_production_kg = 750000 * 1.03 * (0.1226*4 + 0.0776*3.3 + 0.2534),
  fat_percent = 4, protein_percent = 3.3, milk_density_kg_per_l = 1.03,
  date = Sys.Date()
)
class(x) <- "cf_intensity"
# print(x)
# }
```
