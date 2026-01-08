# Package index

## System boundaries and benchmarking

Helpers to define scope and contextualize results.

- [`set_system_boundaries()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/set_system_boundaries.md)
  : Define system boundaries for carbon footprint calculation
- [`benchmark_area_intensity()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/benchmark_area_intensity.md)
  : Benchmark area intensity against regional data

## Emission calculations

Functions to calculate greenhouse gas emissions by source.

- [`calc_emissions_enteric()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_enteric.md)
  : Calculate enteric methane emissions
- [`calc_emissions_manure()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_manure.md)
  : Calculate manure management emissions (Tier 1 & Tier 2)
- [`calc_emissions_soil()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_soil.md)
  : Calculate soil N2O emissions
- [`calc_emissions_energy()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_energy.md)
  : Calculate energy-related emissions
- [`calc_emissions_inputs()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_inputs.md)
  : Calculate indirect emissions from purchased inputs

## Aggregation

Functions to aggregate emissions across sources.

- [`calc_total_emissions()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_total_emissions.md)
  : Calculate total emissions (robust and boundary-aware)

## Intensity metrics

Functions to compute emission intensities.

- [`calc_intensity_litre()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_intensity_litre.md)
  : Calculate carbon footprint intensity per kg of milk
- [`calc_intensity_area()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_intensity_area.md)
  : Calculate carbon footprint intensity per hectare

## Batch processing

Functions for multi-farm analysis.

- [`calc_batch()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_batch.md)
  : Batch carbon footprint calculation

## Templates and reporting

Helpers for templates and report export.

- [`cf_download_template()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/cf_download_template.md)
  [`download_template()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/cf_download_template.md)
  : Download cowfootR Excel template
- [`export_hdc_report()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/export_hdc_report.md)
  : Export cowfootR batch results to Excel

## S3 methods

Printing methods for cowfootR objects.

- [`print(`*`<cf_total>`*`)`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/print.cf_total.md)
  : Print method for cf_total objects
- [`print(`*`<cf_intensity>`*`)`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/print.cf_intensity.md)
  : Print method for cf_intensity objects
- [`print(`*`<cf_area_intensity>`*`)`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/print.cf_area_intensity.md)
  : Print method for cf_area_intensity objects
