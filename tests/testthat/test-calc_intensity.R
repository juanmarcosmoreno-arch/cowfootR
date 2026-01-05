# Tests for intensity calculations --------------------------------------------

test_that("calc_intensity_litre calculates FPCM correctly", {
  result <- calc_intensity_litre(
    total_emissions = 85000,
    milk_litres = 750000,
    fat = 3.9,
    protein = 3.2
  )

  expect_s3_class(result, "cf_intensity")

  # core outputs
  expect_true(is.numeric(result$intensity_co2eq_per_kg_fpcm))
  expect_gt(result$intensity_co2eq_per_kg_fpcm, 0)

  expect_equal(result$milk_production_litres, 750000)

  # helpful sanity checks (avoid over-specifying exact numbers)
  expect_true(is.numeric(result$fpcm_production_kg))
  expect_gt(result$fpcm_production_kg, 0)
})

test_that("calc_intensity_area calculates per hectare metrics", {
  result <- calc_intensity_area(
    total_emissions = 95000,
    area_total_ha = 150,
    area_productive_ha = 135
  )

  expect_s3_class(result, "cf_area_intensity")

  expect_true(is.numeric(result$intensity_per_total_ha))
  expect_true(is.numeric(result$intensity_per_productive_ha))

  # If productive area < total area => intensity per productive ha should be higher
  expect_lt(result$intensity_per_total_ha, result$intensity_per_productive_ha)

  expect_equal(result$land_use_efficiency, 135 / 150)
})

test_that("calc_intensity validates inputs", {
  expect_error(
    calc_intensity_litre(total_emissions = -1000, milk_litres = 750000),
    regexp = "total_emissions|non-?negative|>=|positive|must be",
    ignore.case = TRUE
  )

  expect_error(
    calc_intensity_area(total_emissions = 85000, area_total_ha = 0),
    regexp = "area_total_ha|>\\s*0|positive|must be",
    ignore.case = TRUE
  )
})
