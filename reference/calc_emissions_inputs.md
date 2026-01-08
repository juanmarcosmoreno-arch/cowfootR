# Calculate indirect emissions from purchased inputs

Estimates CO2e emissions from purchased inputs such as feeds,
fertilizers, and plastics using regional factors, with optional
uncertainty analysis.

## Usage

``` r
calc_emissions_inputs(
  conc_kg = 0,
  fert_n_kg = 0,
  plastic_kg = 0,
  feed_grain_dry_kg = 0,
  feed_grain_wet_kg = 0,
  feed_ration_kg = 0,
  feed_byproducts_kg = 0,
  feed_proteins_kg = 0,
  feed_corn_kg = 0,
  feed_soy_kg = 0,
  feed_wheat_kg = 0,
  region = "global",
  fert_type = "mixed",
  plastic_type = "mixed",
  include_uncertainty = FALSE,
  transport_km = NULL,
  ef_conc = NULL,
  ef_fert = NULL,
  ef_plastic = NULL,
  boundaries = NULL
)
```

## Arguments

- conc_kg:

  Numeric. Purchased concentrate feed (kg/year). Default = 0.

- fert_n_kg:

  Numeric. Purchased nitrogen fertilizer (kg N/year). Default = 0.

- plastic_kg:

  Numeric. Agricultural plastics used (kg/year). Default = 0.

- feed_grain_dry_kg:

  Numeric. Grain dry (kg/year, DM). Default = 0.

- feed_grain_wet_kg:

  Numeric. Grain wet (kg/year, DM). Default = 0.

- feed_ration_kg:

  Numeric. Ration (total mixed ration) (kg/year, DM). Default = 0.

- feed_byproducts_kg:

  Numeric. Byproducts (kg/year, DM). Default = 0.

- feed_proteins_kg:

  Numeric. Protein feeds (kg/year, DM). Default = 0.

- feed_corn_kg:

  Numeric. Corn (kg/year, DM). Default = 0.

- feed_soy_kg:

  Numeric. Soybean meal (kg/year, DM). Default = 0.

- feed_wheat_kg:

  Numeric. Wheat (kg/year, DM). Default = 0.

- region:

  Character. "EU","US","Brazil","Argentina","Australia","global".
  Default "global".

- fert_type:

  Character. "urea","ammonium_nitrate","mixed","organic". Default
  "mixed".

- plastic_type:

  Character. "LDPE","HDPE","PP","mixed". Default "mixed".

- include_uncertainty:

  Logical. Include uncertainty ranges? Default FALSE.

- transport_km:

  Numeric. Average feed transport distance (km). Optional.

- ef_conc, ef_fert, ef_plastic:

  Numeric overrides for emission factors (kg CO2e per unit).

- boundaries:

  Optional. Object from
  [`set_system_boundaries()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/set_system_boundaries.md).

## Value

A list with fields:

- source = "inputs"

- emissions_breakdown (named values per input)

- co2eq_kg (numeric total)

- total_co2eq_kg (duplicate of co2eq_kg)

- emission_factors_used, inputs_summary, contribution_analysis,
  uncertainty (if requested)

- metadata (methodology, standards, date)

## Details

Notes:

- When system boundaries exclude "inputs", this function MUST return a
  list with `source = "inputs"` and a numeric `co2eq_kg = 0` to satisfy
  partial-boundaries integration.

- The primary total field is `co2eq_kg` (for compatibility with
  [`calc_total_emissions()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_total_emissions.md));
  `total_co2eq_kg` is included as a duplicate for convenience.

## Examples

``` r
# Quick example (runs fast)
calc_emissions_inputs(conc_kg = 1000, fert_n_kg = 200, region = "EU")
#> $source
#> [1] "inputs"
#> 
#> $emissions_breakdown
#> $emissions_breakdown$concentrate_co2eq_kg
#> [1] 750
#> 
#> $emissions_breakdown$fertilizer_co2eq_kg
#> [1] 1360
#> 
#> $emissions_breakdown$plastic_co2eq_kg
#> [1] 0
#> 
#> $emissions_breakdown$feeds_co2eq_kg
#>  grain_dry  grain_wet     ration byproducts   proteins       corn        soy 
#>          0          0          0          0          0          0          0 
#>      wheat 
#>          0 
#> 
#> $emissions_breakdown$total_feeds_co2eq_kg
#> [1] 0
#> 
#> $emissions_breakdown$transport_adjustment_co2eq_kg
#> [1] 0
#> 
#> 
#> $co2eq_kg
#> [1] 2110
#> 
#> $total_co2eq_kg
#> [1] 2110
#> 
#> $region
#> [1] "EU"
#> 
#> $emission_factors_used
#> $emission_factors_used$concentrate
#> $emission_factors_used$concentrate$value
#> [1] 0.75
#> 
#> $emission_factors_used$concentrate$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$fertilizer
#> $emission_factors_used$fertilizer$value
#> [1] 6.8
#> 
#> $emission_factors_used$fertilizer$type
#> [1] "mixed"
#> 
#> $emission_factors_used$fertilizer$unit
#> [1] "kg CO2e/kg N"
#> 
#> 
#> $emission_factors_used$plastic
#> $emission_factors_used$plastic$value
#> [1] 2.3
#> 
#> $emission_factors_used$plastic$type
#> [1] "mixed"
#> 
#> $emission_factors_used$plastic$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds
#> $emission_factors_used$feeds$grain_dry
#> $emission_factors_used$feeds$grain_dry$value
#> [1] 0.42
#> 
#> $emission_factors_used$feeds$grain_dry$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$grain_wet
#> $emission_factors_used$feeds$grain_wet$value
#> [1] 0.32
#> 
#> $emission_factors_used$feeds$grain_wet$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$ration
#> $emission_factors_used$feeds$ration$value
#> [1] 0.65
#> 
#> $emission_factors_used$feeds$ration$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$byproducts
#> $emission_factors_used$feeds$byproducts$value
#> [1] 0.18
#> 
#> $emission_factors_used$feeds$byproducts$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$proteins
#> $emission_factors_used$feeds$proteins$value
#> [1] 2.2
#> 
#> $emission_factors_used$feeds$proteins$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$corn
#> $emission_factors_used$feeds$corn$value
#> [1] 0.48
#> 
#> $emission_factors_used$feeds$corn$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$soy
#> $emission_factors_used$feeds$soy$value
#> [1] 2.6
#> 
#> $emission_factors_used$feeds$soy$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$wheat
#> $emission_factors_used$feeds$wheat$value
#> [1] 0.51
#> 
#> $emission_factors_used$feeds$wheat$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> 
#> $emission_factors_used$region_source
#> [1] "EU"
#> 
#> $emission_factors_used$transport_km
#> [1] 0
#> 
#> 
#> $inputs_summary
#> $inputs_summary$concentrate_kg
#> [1] 1000
#> 
#> $inputs_summary$fertilizer_n_kg
#> [1] 200
#> 
#> $inputs_summary$plastic_kg
#> [1] 0
#> 
#> $inputs_summary$total_feeds_kg
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg
#> $inputs_summary$feed_breakdown_kg$grain_dry
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$grain_wet
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$ration
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$byproducts
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$proteins
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$corn
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$soy
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$wheat
#> [1] 0
#> 
#> 
#> 
#> $contribution_analysis
#> $contribution_analysis$concentrate_pct
#> [1] 35.5
#> 
#> $contribution_analysis$fertilizer_pct
#> [1] 64.5
#> 
#> $contribution_analysis$plastic_pct
#> [1] 0
#> 
#> $contribution_analysis$feeds_pct
#> [1] 0
#> 
#> $contribution_analysis$transport_pct
#> [1] 0
#> 
#> 
#> $uncertainty
#> NULL
#> 
#> $methodology
#> [1] "Regional emission factors with optional uncertainty analysis"
#> 
#> $standards
#> [1] "IDF 2022; generic LCI sources"
#> 
#> $date
#> [1] "2026-01-08"
#> 

# With uncertainty analysis
calc_emissions_inputs(feed_corn_kg = 2000, region = "US", include_uncertainty = TRUE)
#> $source
#> [1] "inputs"
#> 
#> $emissions_breakdown
#> $emissions_breakdown$concentrate_co2eq_kg
#> [1] 0
#> 
#> $emissions_breakdown$fertilizer_co2eq_kg
#> [1] 0
#> 
#> $emissions_breakdown$plastic_co2eq_kg
#> [1] 0
#> 
#> $emissions_breakdown$feeds_co2eq_kg
#>  grain_dry  grain_wet     ration byproducts   proteins       corn        soy 
#>          0          0          0          0          0        760          0 
#>      wheat 
#>          0 
#> 
#> $emissions_breakdown$total_feeds_co2eq_kg
#> [1] 760
#> 
#> $emissions_breakdown$transport_adjustment_co2eq_kg
#> [1] 0
#> 
#> 
#> $co2eq_kg
#> [1] 760
#> 
#> $total_co2eq_kg
#> [1] 760
#> 
#> $region
#> [1] "US"
#> 
#> $emission_factors_used
#> $emission_factors_used$concentrate
#> $emission_factors_used$concentrate$value
#> [1] 0.65
#> 
#> $emission_factors_used$concentrate$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$fertilizer
#> $emission_factors_used$fertilizer$value
#> [1] 6.4
#> 
#> $emission_factors_used$fertilizer$type
#> [1] "mixed"
#> 
#> $emission_factors_used$fertilizer$unit
#> [1] "kg CO2e/kg N"
#> 
#> 
#> $emission_factors_used$plastic
#> $emission_factors_used$plastic$value
#> [1] 2.4
#> 
#> $emission_factors_used$plastic$type
#> [1] "mixed"
#> 
#> $emission_factors_used$plastic$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds
#> $emission_factors_used$feeds$grain_dry
#> $emission_factors_used$feeds$grain_dry$value
#> [1] 0.35
#> 
#> $emission_factors_used$feeds$grain_dry$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$grain_wet
#> $emission_factors_used$feeds$grain_wet$value
#> [1] 0.28
#> 
#> $emission_factors_used$feeds$grain_wet$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$ration
#> $emission_factors_used$feeds$ration$value
#> [1] 0.55
#> 
#> $emission_factors_used$feeds$ration$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$byproducts
#> $emission_factors_used$feeds$byproducts$value
#> [1] 0.12
#> 
#> $emission_factors_used$feeds$byproducts$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$proteins
#> $emission_factors_used$feeds$proteins$value
#> [1] 1.5
#> 
#> $emission_factors_used$feeds$proteins$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$corn
#> $emission_factors_used$feeds$corn$value
#> [1] 0.38
#> 
#> $emission_factors_used$feeds$corn$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$soy
#> $emission_factors_used$feeds$soy$value
#> [1] 1.6
#> 
#> $emission_factors_used$feeds$soy$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> $emission_factors_used$feeds$wheat
#> $emission_factors_used$feeds$wheat$value
#> [1] 0.45
#> 
#> $emission_factors_used$feeds$wheat$unit
#> [1] "kg CO2e/kg"
#> 
#> 
#> 
#> $emission_factors_used$region_source
#> [1] "US"
#> 
#> $emission_factors_used$transport_km
#> [1] 0
#> 
#> 
#> $inputs_summary
#> $inputs_summary$concentrate_kg
#> [1] 0
#> 
#> $inputs_summary$fertilizer_n_kg
#> [1] 0
#> 
#> $inputs_summary$plastic_kg
#> [1] 0
#> 
#> $inputs_summary$total_feeds_kg
#> [1] 2000
#> 
#> $inputs_summary$feed_breakdown_kg
#> $inputs_summary$feed_breakdown_kg$grain_dry
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$grain_wet
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$ration
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$byproducts
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$proteins
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$corn
#> [1] 2000
#> 
#> $inputs_summary$feed_breakdown_kg$soy
#> [1] 0
#> 
#> $inputs_summary$feed_breakdown_kg$wheat
#> [1] 0
#> 
#> 
#> 
#> $contribution_analysis
#> $contribution_analysis$concentrate_pct
#> [1] 0
#> 
#> $contribution_analysis$fertilizer_pct
#> [1] 0
#> 
#> $contribution_analysis$plastic_pct
#> [1] 0
#> 
#> $contribution_analysis$feeds_pct
#> [1] 100
#> 
#> $contribution_analysis$transport_pct
#> [1] 0
#> 
#> 
#> $uncertainty
#> $uncertainty$mean
#> [1] 830.47
#> 
#> $uncertainty$median
#> [1] 831.64
#> 
#> $uncertainty$sd
#> [1] 119.45
#> 
#> $uncertainty$cv_percent
#> [1] 14.4
#> 
#> $uncertainty$percentiles
#> $uncertainty$percentiles$p5
#>     5% 
#> 643.49 
#> 
#> $uncertainty$percentiles$p25
#>    25% 
#> 724.52 
#> 
#> $uncertainty$percentiles$p75
#>    75% 
#> 934.82 
#> 
#> $uncertainty$percentiles$p95
#>     95% 
#> 1015.21 
#> 
#> 
#> $uncertainty$confidence_interval_95
#> $uncertainty$confidence_interval_95$lower
#>   2.5% 
#> 631.41 
#> 
#> $uncertainty$confidence_interval_95$upper
#>   97.5% 
#> 1026.93 
#> 
#> 
#> 
#> $methodology
#> [1] "Regional emission factors with optional uncertainty analysis"
#> 
#> $standards
#> [1] "IDF 2022; generic LCI sources"
#> 
#> $date
#> [1] "2026-01-08"
#> 
```
