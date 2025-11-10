# Print method for cf_total objects

Print method for cf_total objects

## Usage

``` r
# S3 method for class 'cf_total'
print(x, ...)
```

## Arguments

- x:

  A cf_total object

- ...:

  Additional arguments passed to print methods (currently ignored)

## Value

No return value, called for side effects. Prints formatted total
emissions summary to the console and invisibly returns the input object.

The input object `x`, invisibly.

## Examples

``` r
# \donttest{
x <- list(
  breakdown   = c(enteric = 45000, manure = 12000),
  total_co2eq = 57000,
  n_sources   = 2,
  date        = Sys.Date()
)
class(x) <- "cf_total"
# print(x)
# }
```
