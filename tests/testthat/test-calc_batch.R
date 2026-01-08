# Tests for batch processing -----------------------------------------------

test_that("calc_batch processes multiple farms", {
  farms <- data.frame(
    FarmID = c("A", "B"),
    Milk_litres = c(500000, 700000),
    Cows_milking = c(100, 140),
    Area_total_ha = c(120, 180),
    stringsAsFactors = FALSE
  )

  result <- calc_batch(
    data = farms,
    tier = 1,
    boundaries = set_system_boundaries("farm_gate")
  )

  expect_s3_class(result, "cf_batch_complete")
  expect_equal(result$summary$n_farms_processed, 2)
  expect_equal(length(result$farm_results), 2)
})

test_that("calc_batch validates tier input", {
  # Use a minimal but valid 1-row dataset so the function reaches tier validation
  farms <- data.frame(
    FarmID = "A",
    Year = "2025",
    Milk_litres = 500000,
    Cows_milking = 100,
    stringsAsFactors = FALSE
  )

  expect_error(
    calc_batch(data = farms, tier = 3),
    regexp = "`tier` must be 1 or 2|tier.*(1|2)",
    ignore.case = TRUE
  )
})

test_that("calc_batch validates empty input", {
  expect_error(
    calc_batch(data = data.frame()),
    regexp = "zero rows|nrow\\(data\\) == 0|empty|must.*contain",
    ignore.case = TRUE
  )
})

test_that("calc_batch handles errors gracefully", {
  farms <- data.frame(
    FarmID = c("Good", "Bad"),
    Milk_litres = c(500000, -100),
    Cows_milking = c(100, 50),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    calc_batch(
      data = farms,
      tier = 1,
      boundaries = set_system_boundaries("farm_gate")
    )
  )

  expect_equal(result$summary$n_farms_successful, 1)
  expect_equal(result$summary$n_farms_with_errors, 1)
})
