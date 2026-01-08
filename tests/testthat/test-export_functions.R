# Tests for export and template functions

test_that("export_hdc_report creates an Excel file and returns the path", {
  skip_if_not_installed("writexl")

  farms <- data.frame(
    FarmID = c("A", "B"),
    Milk_litres = c(500000, 700000),
    Cows_milking = c(100, 140),
    Area_total_ha = c(120, 180),
    stringsAsFactors = FALSE
  )

  batch_result <- calc_batch(
    data = farms,
    tier = 1,
    boundaries = set_system_boundaries("farm_gate")
  )

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  out <- export_hdc_report(batch_result, file = temp_file)

  expect_true(file.exists(temp_file))
  expect_gt(file.info(temp_file)$size, 0)

  # La función devuelve la ruta (según el comportamiento actual)
  expect_true(is.character(out))
  expect_true(normalizePath(out, winslash = "/", mustWork = FALSE) ==
    normalizePath(temp_file, winslash = "/", mustWork = FALSE))
})

test_that("cf_download_template creates an Excel template file", {
  skip_if_not_installed("writexl")

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  out <- cf_download_template(file = temp_file, include_examples = TRUE)

  expect_true(file.exists(temp_file))
  expect_gt(file.info(temp_file)$size, 0)

  # Si devuelve la ruta, la verificamos; si devuelve invisible(NULL), también está ok
  if (!is.null(out)) {
    expect_true(is.character(out))
  }
})
