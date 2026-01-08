test_that("calc_emissions_enteric matches a Tier 1 reference case", {

  boundaries <- set_system_boundaries("farm_gate")

  res <- calc_emissions_enteric(
    n_animals = 1,
    cattle_category = "dairy_cows",
    avg_body_weight = 550,
    ym_percent = 6.0,
    tier = 1,
    boundaries = boundaries
  )

  expect_true(is.list(res))
  expect_true("co2eq_kg" %in% names(res))
  expect_true(is.finite(res$co2eq_kg))
  expect_gt(res$co2eq_kg, 0)

  # ---- Valor de referencia ----
  expected <- 3128

  expect_false(is.na(expected))

  expect_equal(
    res$co2eq_kg,
    expected,
    tolerance = 1e-6
  )
})
