# Tests for system boundaries

test_that("set_system_boundaries creates correct structures", {
  b1 <- set_system_boundaries("farm_gate")
  expect_true(is.list(b1))
  expect_true(all(c("scope", "include") %in% names(b1)))
  expect_equal(b1$scope, "farm_gate")
  expect_type(b1$include, "character")

  expect_true("enteric" %in% b1$include)
  expect_true("manure" %in% b1$include)

  b2 <- set_system_boundaries("cradle_to_farm_gate")
  expect_true(is.list(b2))
  expect_true(all(c("scope", "include") %in% names(b2)))
  expect_equal(b2$scope, "cradle_to_farm_gate")
  # según tu implementación: "feed" o "inputs" podrían entrar acá
  expect_true(any(c("feed", "inputs") %in% b2$include))

  b3 <- set_system_boundaries("partial", include = c("enteric", "soil"))
  expect_equal(b3$scope, "partial")
  expect_equal(length(b3$include), 2)
  expect_setequal(b3$include, c("enteric", "soil"))
})

test_that("set_system_boundaries validates inputs with specific errors", {
  expect_error(
    set_system_boundaries("not_a_scope"),
    regexp = "scope|valid|farm_gate|cradle|partial",
    ignore.case = TRUE
  )

  expect_error(
    set_system_boundaries("partial", include = character(0)),
    regexp = "include|at least|empty|length",
    ignore.case = TRUE
  )

  expect_error(
    set_system_boundaries("partial", include = c("enteric", "not_a_source")),
    regexp = "include|valid|source|enteric|manure|soil|energy|inputs|feed",
    ignore.case = TRUE
  )
})

test_that("boundaries exclude emissions correctly (energy excluded)", {
  boundaries <- set_system_boundaries("partial", include = c("enteric", "manure"))

  res_energy <- calc_emissions_energy(diesel_l = 1000, boundaries = boundaries)

  # Aceptamos dos implementaciones válidas:
  # 1) devolver co2eq_kg = 0
  # 2) marcar excluded = TRUE (y co2eq_kg 0 o NULL)
  excl_flag <- isTRUE(res_energy$excluded)
  zero_ok <- is.numeric(res_energy$co2eq_kg) && identical(as.numeric(res_energy$co2eq_kg), 0)
  null_ok <- is.null(res_energy$co2eq_kg)

  expect_true(excl_flag || zero_ok || null_ok)

  res_enteric <- calc_emissions_enteric(n_animals = 100, boundaries = boundaries)
  expect_true(res_enteric$co2eq_kg > 0)
})
