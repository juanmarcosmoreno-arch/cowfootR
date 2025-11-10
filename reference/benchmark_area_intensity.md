# Benchmark area intensity against regional data

Benchmark area intensity against regional data

## Usage

``` r
benchmark_area_intensity(
  cf_area_intensity,
  region = NULL,
  benchmark_data = NULL
)
```

## Arguments

- cf_area_intensity:

  A cf_area_intensity object

- region:

  Character. Region for comparison ("uruguay", "argentina", "brazil",
  "new_zealand", "ireland", "global")

- benchmark_data:

  Named list. Custom benchmark data with mean and range

## Value

Original object with added benchmarking information

## Examples

``` r
# \donttest{
res <- calc_intensity_area(total_emissions = 90000, area_total_ha = 150, area_productive_ha = 140)
out <- benchmark_area_intensity(res, region = "uruguay")
# str(out$benchmarking)
# }
```
