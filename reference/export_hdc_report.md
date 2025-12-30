# Export cowfootR batch results to Excel

Exports results from
[`calc_batch()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_batch.md)
into an Excel file with summary and farm-level sheets.

## Usage

``` r
export_hdc_report(
  batch_results,
  file = "cowfootR_report.xlsx",
  include_details = FALSE
)
```

## Arguments

- batch_results:

  A `cf_batch_complete` object returned by
  [`calc_batch()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_batch.md).

- file:

  Path to the Excel file to save. Default = "cowfootR_report.xlsx".

- include_details:

  Logical. If TRUE, includes extra sheets with detailed objects (if
  available).

## Value

Invisibly returns the file path.

## Examples

``` r
# \donttest{
# Minimal dummy object (como el devuelto por calc_batch)
br <- list(
  summary = list(
    n_farms_processed = 1L,
    n_farms_successful = 1L,
    n_farms_with_errors = 0L,
    boundaries_used = list(scope = "farm_gate"),
    benchmark_region = NA_character_,
    processing_date = Sys.Date()
  ),
  farm_results = list(list(
    success = TRUE,
    farm_id = "Farm_A",
    year = format(Sys.Date(), "%Y"),
    emissions_enteric = 100, emissions_manure = 50, emissions_soil = 20,
    emissions_energy = 10, emissions_inputs = 5, emissions_total = 185,
    intensity_milk_kg_co2eq_per_kg_fpcm = 1.2,
    intensity_area_kg_co2eq_per_ha_total = 800,
    intensity_area_kg_co2eq_per_ha_productive = 1000,
    fpcm_production_kg = 150000, milk_production_kg = 154500,
    milk_production_litres = 150000,
    land_use_efficiency = 3000,
    total_animals = 200, dairy_cows = 120,
    benchmark_region = NA_character_, benchmark_performance = NA_character_,
    processing_date = Sys.Date(), boundaries_used = "farm_gate",
    tier_used = "tier_2", detailed_objects = NULL
  ))
)
class(br) <- "cf_batch_complete"

f <- tempfile(fileext = ".xlsx")
export_hdc_report(br, file = f)
#> Batch report saved to: /tmp/RtmpJ2uGud/file1b95ee3f562.xlsx
file.exists(f)
#> [1] TRUE
# }
```
