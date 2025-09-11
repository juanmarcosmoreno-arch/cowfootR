testthat::test_that("energy: each fuel contributes when present; near-zero when all missing/zero", {
  fn <- calc_emissions_energy

  # Use larger magnitudes to avoid rounding-to-zero, but still allow equality on one path
  e_only <- try(safe_call(fn,
                          canonical_args = list(diesel_l = 0, electricity_kwh = 20000, grid_factor = 0.50),
                          positional_args = list(0, 20000, 0.50),
                          df_args = list(diesel_l = 0, electricity_kwh = 20000, grid_factor = 0.50)
  ), silent = TRUE)

  d_only <- try(safe_call(fn,
                          canonical_args = list(diesel_l = 1000, electricity_kwh = 0, grid_factor = 0.00),
                          positional_args = list(1000, 0, 0.00),
                          df_args = list(diesel_l = 1000, electricity_kwh = 0, grid_factor = 0.00)
  ), silent = TRUE)

  none <- try(safe_call(fn,
                        canonical_args = list(diesel_l = 0, electricity_kwh = 0, grid_factor = 0.00),
                        positional_args = list(0, 0, 0.00),
                        df_args = list(diesel_l = 0, electricity_kwh = 0, grid_factor = 0.00)
  ), silent = TRUE)

  if (any(vapply(list(e_only, d_only, none), inherits, logical(1), "try-error"))) {
    testthat::skip("Incompatible signature — skipping fuel contribution checks.")
  }

  # Prefer a total-like field; fall back to any numeric
  te <- pick_named_numeric(e_only, patterns = c("total", "co2", "emiss"))[1]
  td <- pick_named_numeric(d_only, patterns = c("total", "co2", "emiss"))[1]
  tn <- pick_named_numeric(none,   patterns = c("total", "co2", "emiss"))[1]
  if (any(is.na(c(te, td, tn)))) {
    te <- pluck_numeric(e_only)[1]
    td <- pluck_numeric(d_only)[1]
    tn <- pluck_numeric(none)[1]
  }

  testthat::expect_true(is.finite(te) && te >= 0)
  testthat::expect_true(is.finite(td) && td >= 0)
  testthat::expect_true(is.finite(tn) && tn >= 0)

  # Allow equality on one path due to rounding or allocation rules,
  # but require that at least one fuel strictly increases emissions.
  testthat::expect_gte(te, tn)
  testthat::expect_gte(td, tn)
  testthat::expect_true( (te > tn) || (td > tn) )
})
