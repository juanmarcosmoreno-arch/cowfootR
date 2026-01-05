# Tests for manure management emissions (API-aligned, strong expectations)

test_that("calc_emissions_manure returns expected basic structure (Tier 1)", {
  res <- calc_emissions_manure(
    n_cows = 100,
    manure_system = "pasture",
    tier = 1
  )

  expect_type(res, "list")
  expect_equal(res$source, "manure")
  expect_equal(res$system, "pasture")

  # Core fields
  expect_true(is.numeric(res$co2eq_kg))
  expect_true(is.numeric(res$ch4_kg))
  expect_true(is.finite(res$co2eq_kg))
  expect_true(is.finite(res$ch4_kg))
  expect_gte(res$co2eq_kg, 0)
  expect_gte(res$ch4_kg, 0)
})

test_that("calc_emissions_manure supports all manure systems", {
  systems <- c("pasture", "solid_storage", "liquid_storage", "anaerobic_digester")

  vals <- vapply(systems, function(sys) {
    res <- calc_emissions_manure(n_cows = 50, manure_system = sys, tier = 1)
    expect_equal(res$system, sys)
    res$co2eq_kg
  }, numeric(1))

  expect_true(all(is.finite(vals)))
  expect_true(all(vals >= 0))
})

test_that("calc_emissions_manure Tier 2 works with detailed parameters", {
  res <- calc_emissions_manure(
    n_cows = 100,
    manure_system = "liquid_storage",
    tier = 2,
    avg_body_weight = 580,
    diet_digestibility = 0.68,
    climate = "temperate",
    retention_days = 90,
    system_temperature = 20
  )

  expect_type(res, "list")
  expect_equal(res$source, "manure")
  expect_equal(res$system, "liquid_storage")
  expect_true(is.numeric(res$co2eq_kg))
  expect_true(is.finite(res$co2eq_kg))
  expect_gte(res$co2eq_kg, 0)
})

test_that("calc_emissions_manure validates inputs with specific errors", {
  expect_error(
    calc_emissions_manure(n_cows = -1, manure_system = "pasture", tier = 1),
    regexp = "n_cows|number|positive|>=\\s*0|>\\s*0",
    ignore.case = TRUE
  )

  expect_error(
    calc_emissions_manure(n_cows = 100, manure_system = "invalid", tier = 1),
    regexp = "manure_system|system|valid|pasture|storage|digester",
    ignore.case = TRUE
  )

  expect_error(
    calc_emissions_manure(n_cows = 100, manure_system = "pasture", tier = 3),
    regexp = "tier|1|2|valid",
    ignore.case = TRUE
  )
})

test_that("calc_emissions_manure respects system boundaries (manure excluded)", {
  b <- set_system_boundaries(include = c("enteric", "soil", "energy", "inputs")) # exclude manure

  res <- calc_emissions_manure(
    n_cows = 100,
    manure_system = "pasture",
    tier = 1,
    boundaries = b
  )

  # depending on your implementation: excluded flag OR co2eq_kg forced to 0
  excl_flag <- isTRUE(res$excluded)
  zero_ok <- is.numeric(res$co2eq_kg) && identical(as.numeric(res$co2eq_kg), 0)

  expect_true(excl_flag || zero_ok)

  if (!is.null(res$ch4_kg)) expect_identical(as.numeric(res$ch4_kg), 0)
  if (!is.null(res$n2o_total_kg)) expect_identical(as.numeric(res$n2o_total_kg), 0)
})
