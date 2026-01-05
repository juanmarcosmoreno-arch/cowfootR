# Tests for total emissions aggregation ---------------------------------------

test_that("calc_total_emissions aggregates correctly", {
  e1 <- list(source = "enteric", co2eq_kg = 1000)
  e2 <- list(source = "manure", co2eq_kg = 500)
  e3 <- list(source = "soil",   co2eq_kg = 300)

  result <- calc_total_emissions(e1, e2, e3)

  expect_s3_class(result, "cf_total")

  expect_equal(result$total_co2eq, 1800)
  expect_equal(result$n_sources, 3)

  # sanity check: breakdown should be named by source
  expect_true(all(c("enteric", "manure", "soil") %in% names(result$by_source)))
})

test_that("calc_total_emissions handles different field names", {
  e1 <- list(source = "enteric", co2eq_kg = 1000)
  e2 <- list(source = "manure",  total_co2eq_kg = 500)
  e3 <- list(source = "soil",    total_co2eq = 300)

  result <- calc_total_emissions(e1, e2, e3)

  expect_equal(result$total_co2eq, 1800)
  expect_equal(result$n_sources, 3)
})

test_that("calc_total_emissions errors on invalid input", {
  expect_error(
    calc_total_emissions(),
    regexp = "at least one|no emissions|missing",
    ignore.case = TRUE
  )

  expect_error(
    calc_total_emissions("not a list"),
    regexp = "list|emission|invalid",
    ignore.case = TRUE
  )
})
