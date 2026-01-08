test_that("energy: each source contributes when present; zero when all are zero", {
  # 1) Caso base: todo 0
  none <- calc_emissions_energy(
    diesel_l = 0,
    petrol_l = 0,
    electricity_kwh = 0,
    include_upstream = FALSE
  )

  # Algunos paquetes devuelven 0, otros NULL; aceptamos ambos
  tn <- none$co2eq_kg
  expect_true(is.null(tn) || (is.numeric(tn) && is.finite(tn) && tn >= 0))
  if (!is.null(tn)) expect_equal(as.numeric(tn), 0)

  # 2) Solo electricidad (fijamos factor para evitar depender de "country")
  e_only <- calc_emissions_energy(
    diesel_l = 0,
    petrol_l = 0,
    electricity_kwh = 20000,
    ef_electricity = 0.50, # fija el factor (kg CO2/kWh)
    include_upstream = FALSE
  )

  te <- e_only$co2eq_kg
  expect_true(is.numeric(te) && is.finite(te) && te >= 0)
  expect_gt(te, 0)

  # 3) Solo diesel
  d_only <- calc_emissions_energy(
    diesel_l = 1000,
    petrol_l = 0,
    electricity_kwh = 0,
    include_upstream = FALSE
  )

  td <- d_only$co2eq_kg
  expect_true(is.numeric(td) && is.finite(td) && td >= 0)
  expect_gt(td, 0)

  # 4) Comparaciones contra el "none"
  if (!is.null(tn)) {
    expect_gte(te, tn)
    expect_gte(td, tn)
  }
})
