# Define system boundaries for carbon footprint calculation

Define system boundaries for carbon footprint calculation

## Usage

``` r
set_system_boundaries(scope = "farm_gate", include = NULL)
```

## Arguments

- scope:

  Character. Options:

  - "farm_gate" (default): includes enteric, manure, soil, energy,
    inputs

  - "cradle_to_farm_gate": includes feed production + farm emissions

  - "partial": user-specified

- include:

  Character vector of processes to include (optional).

## Value

A list with \$scope and \$include

## Examples

``` r
b1 <- set_system_boundaries("farm_gate")
b2 <- set_system_boundaries(include = c("enteric", "manure", "soil"))
b3 <- set_system_boundaries(include = c("enteric", "manure"))
b1$scope
#> [1] "farm_gate"
b2$include
#> [1] "enteric" "manure"  "soil"   
b3$include
#> [1] "enteric" "manure" 
```
