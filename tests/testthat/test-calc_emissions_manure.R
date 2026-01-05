# Tests for manure management emissions --------------------------------------

test_that("calc_emissions_manure works with basic inputs", {
  result <- calc_emissions_manure(
    n_cows = 100,
    manure_system = "pasture"
  )

  expect_type(result, "list")
  expect_true("co2eq_kg" %in% names(result))
  expect_true("ch4_kg" %in% names(result))
  expect_equal(result$source, "manure")
  expect_equal(result$system, "pasture")
})

test_that("calc_emissions_manure handles different systems", {
  systems <- c("pasture", "solid_storage", "liquid_storage", "anaerobic_digester")

  for (sys in systems) {
    result <- calc_emissions_manure(
      n_cows = 50,
      manure_system = sys
    )
    expect_equal(result$system, sys)
    expect_true(result$co2eq_kg >= 0)
  }
})

test_that("calc_emissions_manure validates inputs", {
  expect_error(
    calc_emissions_manure(n_cows = -50),
    regexp = "n_cows|positive|>=|greater than|must be",
    ignore.case = TRUE
  )

  expect_error(
    calc_emissions_manure(n_cows = 100, manure_system = "invalid"),
    regexp = "manure_system|invalid|allowed|must be one of|pasture|storage|digester",
    ignore.case = TRUE
  )
})
