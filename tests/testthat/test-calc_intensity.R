# Tests for intensity calculations

test_that("calc_intensity_litre calculates FPCM correctly", {
  result <- calc_intensity_litre(
    total_emissions = 85000,
    milk_litres = 750000,
    fat = 3.9,
    protein = 3.2
  )

  expect_s3_class(result, "cf_intensity")
  expect_true(result$intensity_co2eq_per_kg_fpcm > 0)
  expect_equal(result$milk_production_litres, 750000)
})

test_that("calc_intensity_area calculates per hectare metrics", {
  result <- calc_intensity_area(
    total_emissions = 95000,
    area_total_ha = 150,
    area_productive_ha = 135
  )

  expect_s3_class(result, "cf_area_intensity")
  expect_true(result$intensity_per_total_ha < result$intensity_per_productive_ha)
  expect_equal(result$land_use_efficiency, 135/150)
})

test_that("calc_intensity validates inputs", {
  expect_error(calc_intensity_litre(total_emissions = -1000, milk_litres = 750000))
  expect_error(calc_intensity_area(total_emissions = 85000, area_total_ha = 0))
})
