# Tests for soil emissions -----------------------------------------------------

test_that("calc_emissions_soil calculates direct emissions correctly", {
  result <- calc_emissions_soil(
    n_fertilizer_synthetic = 1500,
    area_ha = 100,
    include_indirect = FALSE
  )

  expect_type(result, "list")
  expect_equal(result$source, "soil")
  expect_true(is.numeric(result$co2eq_kg))
  expect_gt(result$co2eq_kg, 0)
})

test_that("calc_emissions_soil calculates indirect emissions", {
  result <- calc_emissions_soil(
    n_fertilizer_synthetic = 800,
    n_fertilizer_organic = 200,
    n_excreta_pasture = 3000,
    area_ha = 150,
    include_indirect = TRUE
  )

  # Indirect emissions should be > 0 when include_indirect = TRUE and N inputs exist
  expect_true("emissions_breakdown" %in% names(result))
  expect_true("total_indirect_n2o_kg" %in% names(result$emissions_breakdown))
  expect_true(is.numeric(result$emissions_breakdown$total_indirect_n2o_kg))
  expect_gt(result$emissions_breakdown$total_indirect_n2o_kg, 0)
})

test_that("calc_emissions_soil validates inputs", {
  expect_error(
    calc_emissions_soil(n_fertilizer_synthetic = -100),
    regexp = "n_fertilizer_synthetic|non-?negative|>=|positive|must be",
    ignore.case = TRUE
  )

  expect_error(
    calc_emissions_soil(soil_type = "invalid"),
    regexp = "soil_type|invalid|allowed|must be one of|drain|well|poor",
    ignore.case = TRUE
  )
})
