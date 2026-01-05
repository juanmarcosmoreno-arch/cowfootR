# Tests for intensity calculations (strong + consistent)

test_that("calc_intensity_litre returns an S3 cf_intensity with finite positive intensity", {
  res <- calc_intensity_litre(
    total_emissions = 85000,
    milk_litres = 750000,
    fat = 3.9,
    protein = 3.2
  )

  expect_s3_class(res, "cf_intensity")
  expect_true(is.numeric(res$intensity_co2eq_per_kg_fpcm))
  expect_true(is.finite(res$intensity_co2eq_per_kg_fpcm))
  expect_gt(res$intensity_co2eq_per_kg_fpcm, 0)

  expect_equal(res$milk_production_litres, 750000)
})

test_that("calc_intensity_litre decreases when milk increases (same emissions)", {
  res_lo <- calc_intensity_litre(
    total_emissions = 85000,
    milk_litres = 700000,
    fat = 3.9,
    protein = 3.2
  )

  res_hi <- calc_intensity_litre(
    total_emissions = 85000,
    milk_litres = 800000,
    fat = 3.9,
    protein = 3.2
  )

  expect_lt(res_hi$intensity_co2eq_per_kg_fpcm, res_lo$intensity_co2eq_per_kg_fpcm)
})

test_that("calc_intensity_litre validates inputs (specific failures)", {
  expect_error(
    calc_intensity_litre(total_emissions = -1, milk_litres = 750000, fat = 4, protein = 3.3),
    regexp = "total|emission|positive|>=\\s*0",
    ignore.case = TRUE
  )

  expect_error(
    calc_intensity_litre(total_emissions = 85000, milk_litres = 0, fat = 4, protein = 3.3),
    regexp = "milk|litre|positive|>\\s*0|>=\\s*1",
    ignore.case = TRUE
  )
})

test_that("calc_intensity_area returns an S3 cf_area_intensity with coherent metrics", {
  res <- calc_intensity_area(
    total_emissions = 95000,
    area_total_ha = 150,
    area_productive_ha = 135
  )

  expect_s3_class(res, "cf_area_intensity")
  expect_true(is.numeric(res$intensity_per_total_ha))
  expect_true(is.numeric(res$intensity_per_productive_ha))
  expect_true(is.finite(res$intensity_per_total_ha))
  expect_true(is.finite(res$intensity_per_productive_ha))

  # Con menor área (productiva) el indicador debería ser mayor
  expect_gt(res$intensity_per_productive_ha, res$intensity_per_total_ha)

  # Eficiencia de uso del suelo consistente
  expect_equal(res$land_use_efficiency, 135 / 150)
})

test_that("calc_intensity_area increases when emissions increase (same area)", {
  r1 <- calc_intensity_area(total_emissions = 90000, area_total_ha = 150, area_productive_ha = 135)
  r2 <- calc_intensity_area(total_emissions = 99000, area_total_ha = 150, area_productive_ha = 135)

  expect_gt(r2$intensity_per_total_ha, r1$intensity_per_total_ha)
  expect_gt(r2$intensity_per_productive_ha, r1$intensity_per_productive_ha)
})

test_that("calc_intensity_area validates inputs (specific failures)", {
  expect_error(
    calc_intensity_area(total_emissions = 85000, area_total_ha = 0, area_productive_ha = 0),
    regexp = "area|hectare|positive|>\\s*0|>=\\s*1",
    ignore.case = TRUE
  )

  expect_error(
    calc_intensity_area(total_emissions = -1, area_total_ha = 150, area_productive_ha = 135),
    regexp = "total|emission|positive|>=\\s*0",
    ignore.case = TRUE
  )
})
