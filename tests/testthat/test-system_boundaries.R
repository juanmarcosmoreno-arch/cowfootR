# Tests for system boundaries

test_that("set_system_boundaries creates correct structures", {
  b1 <- set_system_boundaries("farm_gate")
  expect_equal(b1$scope, "farm_gate")
  expect_true("enteric" %in% b1$include)
  expect_true("manure" %in% b1$include)

  b2 <- set_system_boundaries("cradle_to_farm_gate")
  expect_true("feed" %in% b2$include)

  b3 <- set_system_boundaries("partial", include = c("enteric", "soil"))
  expect_equal(length(b3$include), 2)
})

test_that("boundaries exclude emissions correctly", {
  boundaries <- set_system_boundaries("partial", include = c("enteric", "manure"))

  result_energy <- calc_emissions_energy(
    diesel_l = 1000,
    boundaries = boundaries
  )
  expect_equal(result_energy$co2eq_kg, 0)

  result_enteric <- calc_emissions_enteric(
    n_animals = 100,
    boundaries = boundaries
  )
  expect_true(result_enteric$co2eq_kg > 0)
})
