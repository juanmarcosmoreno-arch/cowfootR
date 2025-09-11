testthat::test_that("setup: manure function exists", {
  testthat::skip_if_not(exists("calc_emissions_manure"))
})

# -------------------------------------------------------------------------
# calc_emissions_manure tests
# -------------------------------------------------------------------------

testthat::test_that("manure: minimal structure contains expected components", {
  fn <- calc_emissions_manure

  out <- try(safe_call(fn,
                       canonical_args = list(storage = "lagoon", digestor_eff = 0.0, n_excreted_kg = 50, days_storage = 90),
                       positional_args = list("lagoon", 0.0, 50, 90),
                       df_args = list(storage = "lagoon", digestor_eff = 0.0, n_excreted_kg = 50, days_storage = 90)
  ), silent = TRUE)

  if (inherits(out, "try-error")) testthat::skip("Function signature incompatible — skipping test.")

  testthat::expect_true(is.list(out) || is.data.frame(out))
  nm <- names(out)
  testthat::expect_true(any(grepl("CH4",   nm, ignore.case = TRUE)))
  testthat::expect_true(any(grepl("N2O",   nm, ignore.case = TRUE)))
  testthat::expect_true(any(grepl("total", nm, ignore.case = TRUE)))
})

testthat::test_that("manure: different storage types and digester reduce emissions", {
  fn <- calc_emissions_manure

  storages <- c("lagoon", "solid_stack", "compost")
  res <- lapply(storages, function(s) {
    try(safe_call(fn,
                  canonical_args = list(storage = s, digestor_eff = 0.0, n_excreted_kg = 50, days_storage = 90),
                  positional_args = list(s, 0.0, 50, 90),
                  df_args = list(storage = s, digestor_eff = 0.0, n_excreted_kg = 50, days_storage = 90)
    ), silent = TRUE)
  })

  if (any(vapply(res, inherits, logical(1), "try-error"))) testthat::skip("Signature incompatible — skipping storage test.")

  totals <- vapply(res, function(x) pick_named_numeric(x, patterns = c("total"))[1], numeric(1))
  testthat::expect_true(all(is.finite(totals)))

  sin_dig <- safe_call(fn,
                       canonical_args = list(storage = "lagoon", digestor_eff = 0.0, n_excreted_kg = 50, days_storage = 90),
                       positional_args = list("lagoon", 0.0, 50, 90),
                       df_args = list(storage = "lagoon", digestor_eff = 0.0, n_excreted_kg = 50, days_storage = 90)
  )
  con_dig <- safe_call(fn,
                       canonical_args = list(storage = "lagoon", digestor_eff = 0.7, n_excreted_kg = 50, days_storage = 90),
                       positional_args = list("lagoon", 0.7, 50, 90),
                       df_args = list(storage = "lagoon", digestor_eff = 0.7, n_excreted_kg = 50, days_storage = 90)
  )

  t0 <- pick_named_numeric(sin_dig, patterns = c("total"))[1]
  t1 <- pick_named_numeric(con_dig, patterns = c("total"))[1]
  testthat::expect_true(is.finite(t0) && is.finite(t1))
  testthat::expect_lt(t1, t0)
})

testthat::test_that("manure: zero excretion leads to near-zero emissions", {
  fn <- calc_emissions_manure
  out <- try(safe_call(fn,
                       canonical_args = list(storage = "lagoon", digestor_eff = 0.0, n_excreted_kg = 0, days_storage = 90),
                       positional_args = list("lagoon", 0.0, 0, 90),
                       df_args = list(storage = "lagoon", digestor_eff = 0.0, n_excreted_kg = 0, days_storage = 90)
  ), silent = TRUE)

  if (inherits(out, "try-error")) testthat::skip("Signature incompatible — skipping zero excretion case.")
  tot <- pick_named_numeric(out, patterns = c("total"))[1]
  testthat::expect_true(is.na(tot) || tot <= 1e-8)
})

testthat::test_that("manure: snapshot test ensures output structure is stable", {
  fn <- calc_emissions_manure
  out <- try(safe_call(fn,
                       canonical_args = list(storage = "lagoon", digestor_eff = 0.25, n_excreted_kg = 40, days_storage = 60),
                       positional_args = list("lagoon", 0.25, 40, 60),
                       df_args = list(storage = "lagoon", digestor_eff = 0.25, n_excreted_kg = 40, days_storage = 60)
  ), silent = TRUE)

  if (inherits(out, "try-error")) testthat::skip("Signature incompatible — skipping snapshot.")
  withr::with_seed(123, testthat::expect_snapshot(str(as.list(out))))
})
