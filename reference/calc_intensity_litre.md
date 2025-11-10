# Calculate carbon footprint intensity per kg of milk

Computes emissions intensity as kg CO2eq per kg of fat- and
protein-corrected milk (FPCM).

## Usage

``` r
calc_intensity_litre(
  total_emissions,
  milk_litres,
  fat = 4,
  protein = 3.3,
  milk_density = 1.03
)
```

## Arguments

- total_emissions:

  Numeric or cf_total object. Total emissions in kg CO2eq (from
  [`calc_total_emissions()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_total_emissions.md))
  or the object itself.

- milk_litres:

  Numeric. Annual milk production in litres.

- fat:

  Numeric. Average fat percentage of milk (0-100). Default = 4.

- protein:

  Numeric. Average protein percentage of milk (0-100). Default = 3.3.

- milk_density:

  Numeric. Milk density in kg/L. Default = 1.03.

## Value

A list of class "cf_intensity" with intensity (kg CO2eq/kg FPCM), FPCM
production, and calculation details.

## Details

The correction to FPCM (fat- and protein-corrected milk) follows the IDF
formula: \$\$FPCM = milk_kg \* (0.1226 \* fat_pct + 0.0776 \*
protein_pct + 0.2534)\$\$

Where milk_kg = milk_litres \* milk_density

## Examples

``` r
# \donttest{
# Using numeric total emissions directly
calc_intensity_litre(total_emissions = 85000, milk_litres = 750000)
#> Carbon Footprint Intensity
#> ==========================
#> Intensity: 0.11 kg CO2eq/kg FPCM
#> 
#> Production data:
#>  Raw milk (L): 750,000 L
#>  Raw milk (kg): 772,500 kg
#>  FPCM (kg): 772,407 kg
#>  Fat content: 4 %
#>  Protein content: 3.3 %
#> 
#> Total emissions: 85,000 kg CO2eq
#> Calculated on: 2025-11-10 

# If you have a cf_total object 'tot' (e.g., from calc_total_emissions):
# calc_intensity_litre(tot, milk_litres = 750000)
# }
```
