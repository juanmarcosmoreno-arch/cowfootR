# Tests for soil emissions

test_that("calc_emissions_soil calculates direct emissions correctly", {
  result <- calc_emissions_soil(
    n_fertilizer_synthetic = 1500,
    area_ha = 100,
    include_indirect = FALSE
  )

  expect_type(result, "list")
  expect_equal(result$source, "soil")
  expect_true(result$co2eq_kg > 0)
})

test_that("calc_emissions_soil calculates indirect emissions", {
  result <- calc_emissions_soil(
    n_fertilizer_synthetic = 800,
    n_fertilizer_organic = 200,
    n_excreta_pasture = 3000,
    area_ha = 150,
    include_indirect = TRUE
  )

  expect_true(result$emissions_breakdown$total_indirect_n2o_kg > 0)
})

test_that("calc_emissions_soil validates inputs", {
  expect_error(calc_emissions_soil(n_fertilizer_synthetic = -100))
  expect_error(calc_emissions_soil(soil_type = "invalid"))
})
