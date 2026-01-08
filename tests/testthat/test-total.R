# Tests for total emissions aggregation (calc_total_emissions)

test_that("calc_total_emissions aggregates correctly with standard fields", {
  e1 <- list(source = "enteric", co2eq_kg = 1000)
  e2 <- list(source = "manure", co2eq_kg = 500)
  e3 <- list(source = "soil", co2eq_kg = 300)

  result <- calc_total_emissions(e1, e2, e3)

  expect_s3_class(result, "cf_total")
  expect_equal(result$total_co2eq, 1800)
  expect_equal(result$n_sources, 3)
})

test_that("calc_total_emissions supports alternative CO2eq field names", {
  e1 <- list(source = "enteric", co2eq_kg = 1000)
  e2 <- list(source = "manure", total_co2eq_kg = 500)
  e3 <- list(source = "soil", total_co2eq = 300)

  result <- calc_total_emissions(e1, e2, e3)

  expect_s3_class(result, "cf_total")
  expect_equal(result$total_co2eq, 1800)
})

test_that("calc_total_emissions is monotonic (increasing one source increases total)", {
  base <- calc_total_emissions(
    list(source = "enteric", co2eq_kg = 1000),
    list(source = "manure", co2eq_kg = 500)
  )

  more <- calc_total_emissions(
    list(source = "enteric", co2eq_kg = 1100),
    list(source = "manure", co2eq_kg = 500)
  )

  expect_gt(more$total_co2eq, base$total_co2eq)
})

test_that("calc_total_emissions errors on invalid input (specific message)", {
  expect_error(
    calc_total_emissions(),
    regexp = "at least|no sources|missing",
    ignore.case = TRUE
  )

  expect_error(
    calc_total_emissions("not a list"),
    regexp = "list|cf_|source|invalid",
    ignore.case = TRUE
  )
})
