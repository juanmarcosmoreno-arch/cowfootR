# Tests for export and template functions

test_that("export_hdc_report creates Excel file", {
  skip_if_not_installed("writexl")

  farms <- data.frame(
    FarmID = c("A", "B"),
    Milk_litres = c(500000, 700000),
    Cows_milking = c(100, 140),
    stringsAsFactors = FALSE
  )

  batch_result <- suppressMessages(calc_batch(data = farms, tier = 1))

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  suppressMessages(export_hdc_report(batch_result, file = temp_file))

  expect_true(file.exists(temp_file))
})

test_that("download_template creates template file", {
  skip_if_not_installed("writexl")

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  suppressMessages(download_template(file = temp_file, include_examples = TRUE))

  expect_true(file.exists(temp_file))
})
