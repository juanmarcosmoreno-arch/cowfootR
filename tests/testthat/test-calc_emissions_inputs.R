# Tests for purchased inputs emissions --------------------------------------

test_that("calc_emissions_inputs calculates basic emissions", {
  result <- calc_emissions_inputs(
    conc_kg = 1000,
    fert_n_kg = 200,
    plastic_kg = 50
  )

  expect_type(result, "list")
  expect_equal(result$source, "inputs")
  expect_true(result$total_co2eq_kg > 0)
})

test_that("calc_emissions_inputs handles regional factors", {
  regions <- c("EU", "US", "Brazil", "Argentina", "Australia", "global")

  results <- list()
  for (region in regions) {
    results[[region]] <- calc_emissions_inputs(
      conc_kg = 1000,
      feed_soy_kg = 500,
      region = region
    )
    expect_equal(results[[region]]$region, region)
  }

  # Different regions should give different results
  expect_true(length(unique(sapply(results, function(x) x$total_co2eq_kg))) > 1)
})

test_that("calc_emissions_inputs validates plastic types", {
  expect_error(
    calc_emissions_inputs(plastic_kg = 100, plastic_type = "invalid"),
    regexp = "plastic_type|invalid|allowed|must be one of|LDPE|HDPE|PP|mixed",
    ignore.case = TRUE
  )
})
