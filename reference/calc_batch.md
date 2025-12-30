# Batch carbon footprint calculation

Processes a data.frame of farms and computes emissions per farm,
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

  A data.frame with one row per farm (already loaded). This version does
  not read files.

- tier:

  Integer; methodology tier (usually 1 or 2). Default = 2.

- boundaries:

  System boundaries as returned by
  [`set_system_boundaries()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/set_system_boundaries.md).

- benchmark_region:

  Optional character code/region for benchmarking (if supported).

- save_detailed_objects:

  Logical; if TRUE, returns detailed objects per farm.

## Value

A list with `$summary` and `$farm_results`; class `cf_batch_complete`.

## Examples

``` r
# \donttest{
farms <- data.frame(FarmID = c("A","B"),
                    Milk_litres = c(5e5, 7e5),
                    Cows_milking = c(100, 140))
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
#>  $ processing_date    : Date[1:1], format: "2025-12-30"
# }
```
