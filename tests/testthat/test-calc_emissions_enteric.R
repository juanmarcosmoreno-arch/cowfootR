# Tests for enteric emissions calculation ----------------------------------

test_that("calc_emissions_enteric works with basic inputs", {
  result <- calc_emissions_enteric(n_animals = 100)

  expect_type(result, "list")
  expect_true("co2eq_kg" %in% names(result))
  expect_true("ch4_kg" %in% names(result))
  expect_true(result$co2eq_kg > 0)
  expect_equal(result$source, "enteric")
})

test_that("calc_emissions_enteric handles different cattle categories", {
  categories <- c("dairy_cows", "heifers", "calves", "bulls")

  for (cat in categories) {
    result <- calc_emissions_enteric(
      n_animals = 50,
      cattle_category = cat
    )

    expect_equal(result$category, cat)
    expect_true(result$co2eq_kg > 0)
  }
})

test_that("calc_emissions_enteric validates inputs", {
  expect_error(
    calc_emissions_enteric(n_animals = -10),
    regexp = "n_animals|must be.*(>=|positive)|negative",
    ignore.case = TRUE
  )

  expect_error(
    calc_emissions_enteric(n_animals = 100, cattle_category = "invalid"),
    regexp = "cattle_category|invalid|allowed|must be one of",
    ignore.case = TRUE
  )

  expect_error(
    calc_emissions_enteric(n_animals = 100, tier = 3),
    regexp = "tier|must be.*(1|2)|invalid",
    ignore.case = TRUE
  )
})
