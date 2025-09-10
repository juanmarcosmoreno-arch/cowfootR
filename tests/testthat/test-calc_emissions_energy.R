# Tests for energy emissions

test_that("calc_emissions_energy calcula emisiones por combustible y electricidad", {
  res <- calc_emissions_energy(
    diesel_l = 1000,
    petrol_l = 500,
    electricity_kwh = 10000,
    country = "UY"
  )

  expect_type(res, "list")
  expect_equal(res$source, "energy")

  # Campos esperados básicos
  expect_true(is.list(res$fuel_emissions))
  expect_true(is.numeric(res$co2eq_kg))
  expect_true(is.numeric(res$direct_co2eq_kg))
  expect_true(is.numeric(res$upstream_co2eq_kg))

  # Debe dar positivo si hay consumo > 0
  expect_gt(res$co2eq_kg, 0)
})

test_that("calc_emissions_energy usa factores país para electricidad", {
  # Sólo electricidad para aislar el efecto del factor de red
  uy <- calc_emissions_energy(electricity_kwh = 1000, country = "UY")
  au <- calc_emissions_energy(electricity_kwh = 1000, country = "AU")

  # Australia (0.75) > Uruguay (0.08)
  expect_gt(au$co2eq_kg, uy$co2eq_kg)

  # País desconocido -> warning y factor 0.35; debería quedar entre UY y AU
  unk <- suppressWarnings(calc_emissions_energy(electricity_kwh = 1000, country = "ZZ"))
  expect_gt(unk$co2eq_kg, uy$co2eq_kg)
  expect_lt(unk$co2eq_kg, au$co2eq_kg)
})

test_that("calc_emissions_energy valida entradas no negativas", {
  expect_error(calc_emissions_energy(diesel_l = -100))
  expect_error(calc_emissions_energy(electricity_kwh = -1000))
})

test_that("calc_emissions_energy respeta límites del sistema (energy excluido)", {
  # Excluir "energy" vía 'include' (NO tocar la función)
  b <- set_system_boundaries(include = c("enteric", "manure", "soil", "inputs"))

  res <- calc_emissions_energy(
    diesel_l = 10, electricity_kwh = 100, country = "UY", boundaries = b
  )

  # Debe marcarse como excluido y NO contribuir; la función hoy puede devolver NULL o 0
  excl_flag <- isTRUE(res$excluded)
  null_ok   <- is.null(res$co2eq_kg)
  zero_ok   <- (is.numeric(res$co2eq_kg) && identical(as.numeric(res$co2eq_kg), 0))

  expect_true(excl_flag || null_ok || zero_ok)

  # Y si existiese 'direct_co2eq_kg' u otros, que sean 0 cuando esté excluido
  if (!is.null(res$direct_co2eq_kg))  expect_identical(as.numeric(res$direct_co2eq_kg), 0)
  if (!is.null(res$upstream_co2eq_kg)) expect_identical(as.numeric(res$upstream_co2eq_kg), 0)
})
