# Tests for energy emissions

test_that("calc_emissions_energy calculates fuel emissions", {
  result <- calc_emissions_energy(
    diesel_l = 1000,
    petrol_l = 500,
    electricity_kwh = 10000,
    country = "UY"
  )

  expect_type(result, "list")
  expect_equal(result$source, "energy")
  expect_true(result$co2eq_kg > 0)
})

test_that("calc_emissions_energy handles country-specific factors", {
  result_uy <- calc_emissions_energy(electricity_kwh = 1000, country = "UY")
  result_au <- calc_emissions_energy(electricity_kwh = 1000, country = "AU")

  # Australia has higher grid emissions than Uruguay
  expect_true(result_au$co2eq_kg > result_uy$co2eq_kg)
})

test_that("calc_emissions_energy validates inputs", {
  expect_error(calc_emissions_energy(diesel_l = -100))
  expect_error(calc_emissions_energy(electricity_kwh = -1000))
})
