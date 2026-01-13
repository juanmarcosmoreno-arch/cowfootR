# Batch carbon footprint calculation

Processes a data.frame of farms and computes annual emissions per farm,
returning a summary plus per-farm details (optionally).

## Usage

``` r
calc_batch(
  data,
  tier = 2,
  boundaries = set_system_boundaries("farm_gate"),
  benchmark_region = NULL,
  save_detailed_objects = FALSE
)
```

## Arguments

- data:

  A data.frame with one row per farm and annual activity data. At
  minimum, the following columns are required:

  - `FarmID`: Unique farm identifier.

  - `Milk_litres`: Annual milk production (litres/year).

  - `Cows_milking`: Number of milking cows.

  Additional columns are optional and enable more detailed Tier 2
  calculations, including herd structure, feed intake, manure
  management, soil nitrogen inputs, energy use, and purchased inputs.
  When optional variables are not provided, default IPCC- or
  IDF-consistent values are used. All inputs are assumed to represent
  one accounting year.

- tier:

  Integer; methodology tier (usually 1 or 2). Default = 2.

- boundaries:

  System boundaries as returned by
  [`set_system_boundaries()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/set_system_boundaries.md).

- benchmark_region:

  Optional character string specifying a geographic or regional
  benchmark (e.g., country or production region). When provided,
  emission intensity results are compared against region-specific
  reference values using internal benchmarking functions. This argument
  does not affect emission calculations and is only used for comparative
  performance assessment.

- save_detailed_objects:

  Logical; if TRUE, returns detailed objects per farm.

## Value

A list with `$summary` and `$farm_results`; class `cf_batch_complete`.
Absolute emissions returned in `$farm_results` (e.g., `emissions_total`,
`emissions_enteric`, `emissions_manure`, etc.) are annual emissions
expressed as kg CO2-equivalent per year (kg CO2eq yr-1) at the farm
(system) level, within the defined system boundaries. Intensity metrics
are reported as kg CO2eq per kg FPCM and kg CO2eq per ha (based on
annual milk production and managed area).

## Details

The input data frame is intentionally flexible to support heterogeneous
data availability across farms. Each row represents one farm and all
inputs are assumed to correspond to a single accounting year, unless
explicitly stated otherwise by the column name (e.g., \*\_kg_day).

Column names follow cowfootR conventions. The complete and authoritative
specification of supported input columns (including expected units and
whether they are required or optional) is provided by the Excel template
generated with
[`cf_download_template()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/cf_download_template.md).
This template represents the full set of columns that can be used by
`calc_batch()`.

In addition, the vignettes "Get started" and "IPCC Methodology Tiers in
cowfootR" describe how these columns are used conceptually and
methodologically.

**Tier 2–relevant optional columns:** When `tier = 2`, `calc_batch()`
uses additional farm-specific information if available. The most
relevant optional columns include:

- **Enteric fermentation:** `Milk_yield_kg_cow_year`,
  `Body_weight_cows_kg`, `MS_intake_cows_milking_kg_day`, `Ym_percent`.

- **Young stock (optional refinement):** `Body_weight_heifers_kg`,
  `Body_weight_calves_kg`, `Body_weight_bulls_kg`,
  `MS_intake_heifers_kg_day`, `MS_intake_calves_kg_day`,
  `MS_intake_bulls_kg_day`.

- **Manure management:** `Manure_system`, `Diet_digestibility`,
  `Protein_intake_kg_day`, `Retention_days`, `System_temperature`,
  `Climate_zone`.

If any Tier 2–relevant column is missing, the function automatically
falls back to Tier 1–consistent default assumptions following IPCC and
IDF guidance. Missing optional inputs therefore do not cause errors.

## Examples

``` r
# \donttest{
farms <- data.frame(
  FarmID = c("A", "B"),
  Milk_litres = c(5e5, 7e5),
  Cows_milking = c(100, 140)
)
res <- calc_batch(
  data = farms,
  tier = 2,
  boundaries = set_system_boundaries("farm_gate"),
  benchmark_region = "uruguay",
  save_detailed_objects = FALSE
)
#> Batch: 2 rows; tier=2 ...
str(res$summary)
#> List of 6
#>  $ n_farms_processed  : int 2
#>  $ n_farms_successful : int 2
#>  $ n_farms_with_errors: int 0
#>  $ boundaries_used    :List of 2
#>   ..$ scope  : chr "farm_gate"
#>   ..$ include: chr [1:5] "enteric" "manure" "soil" "energy" ...
#>  $ benchmark_region   : chr "uruguay"
#>  $ processing_date    : Date[1:1], format: "2026-01-13"
# }
```
