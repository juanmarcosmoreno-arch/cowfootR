# Download cowfootR Excel template

Saves a blank Excel template with required columns for batch carbon
footprint calculations.

## Usage

``` r
cf_download_template(file = "cowfootR_template.xlsx", include_examples = FALSE)

download_template(...)
```

## Arguments

- file:

  Path where the template will be saved. Default =
  "cowfootR_template.xlsx".

- include_examples:

  Logical. If TRUE, includes example rows.

## Value

Invisibly returns the file path.

## Examples

``` r
tf <- tempfile(fileext = ".xlsx")
on.exit(unlink(tf, force = TRUE), add = TRUE)
cf_download_template(tf)
#> Template saved to: /tmp/RtmpJbwaV1/file1b5356519f.xlsx
```
