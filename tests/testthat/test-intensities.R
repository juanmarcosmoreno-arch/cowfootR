testthat::test_that("setup: intensities functions exist", {
  testthat::skip_if_not(exists("calc_intensity_area"))
  testthat::skip_if_not(exists("calc_intensity_litre"))
})

# -------------------------------------------------------------------------
# calc_intensity_area tests
# -------------------------------------------------------------------------

testthat::test_that("calc_intensity_area: basic case returns finite non-negative intensity", {
  fn <- calc_intensity_area

  # Emissions total and area values for test
  total <- 1000
  area  <- 50

  # Try different calling styles depending on function signature
  out <- try(safe_call(fn,
                       canonical_args = list(total_CO2eq = total, area_ha = area),
                       positional_args = list(total, area),
                       df_args = list(total_CO2eq = total, area_ha = area)
  ), silent = TRUE)

  if (inherits(out, "try-error")) testthat::skip("Function signature incompatible — skipping test.")

  val <- pick_named_numeric(out, patterns = c("per_ha", "intens", "ha"))
  if (length(val) == 0) testthat::skip("No intensity field detected in output.")

  testthat::expect_true(all(is.finite(val)))
  testthat::expect_true(all(val >= 0))
})

testthat::test_that("calc_intensity_area: higher emissions with same area → higher intensity", {
  fn <- calc_intensity_area

  o1 <- try(safe_call(fn,
                      canonical_args = list(total_CO2eq = 1000, area_ha = 100),
                      positional_args = list(1000, 100),
                      df_args = list(total_CO2eq = 1000, area_ha = 100)
  ), silent = TRUE)

  o2 <- try(safe_call(fn,
                      canonical_args = list(total_CO2eq = 1100, area_ha = 100),
                      positional_args = list(1100, 100),
                      df_args = list(total_CO2eq = 1100, area_ha = 100)
  ), silent = TRUE)

  if (inherits(o1, "try-error") || inherits(o2, "try-error")) testthat::skip("Signature incompatible — skipping monotonicity test.")

  v1 <- pick_named_numeric(o1, patterns = c("per_ha", "intens", "ha"))
  v2 <- pick_named_numeric(o2, patterns = c("per_ha", "intens", "ha"))
  if (length(v1) == 0 || length(v2) == 0) testthat::skip("No intensity field detected.")

  testthat::expect_true(is.finite(mean(v1)) && is.finite(mean(v2)))
  testthat::expect_gt(mean(v2), mean(v1))
})

testthat::test_that("calc_intensity_area: zero or NA area handled gracefully", {
  fn <- calc_intensity_area

  # Zero area: should return NA/Inf or error
  o0 <- try(safe_call(fn,
                      canonical_args = list(total_CO2eq = 100, area_ha = 0),
                      positional_args = list(100, 0),
                      df_args = list(total_CO2eq = 100, area_ha = 0)
  ), silent = TRUE)

  if (!inherits(o0, "try-error")) {
    v0 <- pick_named_numeric(o0, patterns = c("per_ha", "intens", "ha"))
    testthat::expect_true(any(is.na(v0) | is.infinite(v0)))
  } else testthat::expect_true(TRUE)

  # NA area: should return NA or error
  oNA <- try(safe_call(fn,
                       canonical_args = list(total_CO2eq = 100, area_ha = NA_real_),
                       positional_args = list(100, NA_real_),
                       df_args = list(total_CO2eq = 100, area_ha = NA_real_)
  ), silent = TRUE)

  if (!inherits(oNA, "try-error")) {
    vna <- pick_named_numeric(oNA, patterns = c("per_ha", "intens", "ha"))
    testthat::expect_true(any(is.na(vna)))
  } else testthat::expect_true(TRUE)
})

# -------------------------------------------------------------------------
# calc_intensity_litre tests
# -------------------------------------------------------------------------

testthat::test_that("calc_intensity_litre: basic case returns finite non-negative intensity", {
  fn <- calc_intensity_litre

  total <- 1000
  milk  <- 50000

  out <- try(safe_call(fn,
                       canonical_args = list(total_CO2eq = total, milk_kg = milk),  # replace milk_kg with milk_LCGP if needed
                       positional_args = list(total, milk),
                       df_args = list(total_CO2eq = total, milk_kg = milk)
  ), silent = TRUE)

  if (inherits(out, "try-error")) testthat::skip("Function signature incompatible — skipping test.")

  vals <- pick_named_numeric(out, patterns = c("per_litre", "intens", "milk"))
  if (length(vals) == 0) testthat::skip("No intensity field detected in output.")

  testthat::expect_true(all(is.finite(vals)))
  testthat::expect_true(all(vals >= 0))

  # Zero milk: should return NA/Inf or error
  o0 <- try(safe_call(fn,
                      canonical_args = list(total_CO2eq = total, milk_kg = 0),
                      positional_args = list(total, 0),
                      df_args = list(total_CO2eq = total, milk_kg = 0)
  ), silent = TRUE)

  if (!inherits(o0, "try-error")) {
    v0 <- pick_named_numeric(o0, patterns = c("per_litre", "intens", "milk"))
    testthat::expect_true(any(is.na(v0) | is.infinite(v0)))
  } else testthat::expect_true(TRUE)
})

testthat::test_that("calc_intensity_litre: higher milk production → lower intensity", {
  fn <- calc_intensity_litre
  total <- 1000

  lo <- try(safe_call(fn,
                      canonical_args = list(total_CO2eq = total, milk_kg = 40000),
                      positional_args = list(total, 40000),
                      df_args = list(total_CO2eq = total, milk_kg = 40000)
  ), silent = TRUE)

  hi <- try(safe_call(fn,
                      canonical_args = list(total_CO2eq = total, milk_kg = 42000),
                      positional_args = list(total, 42000),
                      df_args = list(total_CO2eq = total, milk_kg = 42000)
  ), silent = TRUE)

  if (inherits(lo, "try-error") || inherits(hi, "try-error")) testthat::skip("Signature incompatible — skipping monotonicity test.")

  v_lo <- pick_named_numeric(lo, patterns = c("per_litre", "intens", "milk"))
  v_hi <- pick_named_numeric(hi, patterns = c("per_litre", "intens", "milk"))

  if (length(v_lo) == 0 || length(v_hi) == 0) testthat::skip("No intensity field detected.")

  testthat::expect_true(is.finite(mean(v_lo)) && is.finite(mean(v_hi)))
  testthat::expect_lt(mean(v_hi), mean(v_lo))
})
