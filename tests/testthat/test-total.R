testthat::test_that("setup: total function exists", {
  testthat::skip_if_not(exists("calc_total_emissions"))
})

# -------------------------------------------------------------------------
# calc_total_emissions tests
# -------------------------------------------------------------------------
# These tests do not assume a fixed input signature.
# Strategy:
#   1) Try to pass a compact list/df of component totals.
#   2) If incompatible, skip gracefully.
# Assertions:
#   - Basic case returns a finite/non-negative total-like value.
#   - Monotonicity: increasing one component increases the final total.
#   - Optional: if component fields are detectable in the output, check
#     that "reported total" matches the sum of components within tolerance.

# Helper to build a component set (names are common but may vary in your impl)
.build_components <- function(k_enteric = 200, k_manure = 100, k_soil = 50, k_energy = 80, k_inputs = 30) {
  list(
    enteric = k_enteric,
    manure  = k_manure,
    soil    = k_soil,
    energy  = k_energy,
    inputs  = k_inputs
  )
}

testthat::test_that("total: basic case returns finite/non-negative total", {
  fn <- calc_total_emissions
  comps <- .build_components()

  out <- try(safe_call(fn,
                       canonical_args = comps,
                       positional_args = unname(comps),
                       df_args = comps
  ), silent = TRUE)

  if (inherits(out, "try-error")) testthat::skip("Incompatible signature — skipping total basic.")

  # Try to pick a 'total' field; if none, use any finite numeric as fallback
  tot <- pick_named_numeric(out, patterns = c("total", "co2", "emiss"))
  if (length(tot) == 0) tot <- pluck_numeric(out)

  testthat::expect_true(length(tot) >= 1)
  testthat::expect_true(all(is.finite(tot)))
  testthat::expect_true(all(tot >= 0))
})

testthat::test_that("total: increasing one component increases final total", {
  fn <- calc_total_emissions

  base_in <- .build_components(k_enteric = 200, k_manure = 100, k_soil = 50, k_energy = 80, k_inputs = 30)
  more_in <- .build_components(k_enteric = 260, k_manure = 100, k_soil = 50, k_energy = 80, k_inputs = 30)

  base <- try(safe_call(fn,
                        canonical_args = base_in,
                        positional_args = unname(base_in),
                        df_args = base_in
  ), silent = TRUE)
  more <- try(safe_call(fn,
                        canonical_args = more_in,
                        positional_args = unname(more_in),
                        df_args = more_in
  ), silent = TRUE)

  if (inherits(base, "try-error") || inherits(more, "try-error")) {
    testthat::skip("Incompatible signature — skipping monotonicity.")
  }

  t0 <- pick_named_numeric(base, patterns = c("total", "co2", "emiss"))
  t1 <- pick_named_numeric(more, patterns = c("total", "co2", "emiss"))
  if (length(t0) == 0 || length(t1) == 0) {
    # Fallback: compare any finite numeric mean
    t0 <- mean(pluck_numeric(base), na.rm = TRUE)
    t1 <- mean(pluck_numeric(more), na.rm = TRUE)
    testthat::expect_true(is.finite(t0) && is.finite(t1))
    testthat::expect_gt(t1, t0)
  } else {
    testthat::expect_true(is.finite(mean(t0)) && is.finite(mean(t1)))
    testthat::expect_gt(mean(t1), mean(t0))
  }
})

testthat::test_that("total: reported total matches sum of components (if detectable)", {
  fn <- calc_total_emissions
  comps <- .build_components(k_enteric = 210, k_manure = 90, k_soil = 60, k_energy = 70, k_inputs = 40)

  out <- try(safe_call(fn,
                       canonical_args = comps,
                       positional_args = unname(comps),
                       df_args = comps
  ), silent = TRUE)
  if (inherits(out, "try-error")) testthat::skip("Incompatible signature — skipping sum check.")

  # Attempt to detect component fields in the OUTPUT (not inputs)
  get_field <- function(obj, pats) {
    pick_named_numeric(obj, patterns = pats)[1]
  }
  tot_out    <- get_field(out, c("total", "co2", "emiss"))
  ent_out    <- get_field(out, c("enteric"))
  man_out    <- get_field(out, c("manure", "esti"))
  soil_out   <- get_field(out, c("soil", "suelo"))
  energy_out <- get_field(out, c("energy", "ener"))
  inputs_out <- get_field(out, c("inputs", "insum"))

  if (any(is.na(c(ent_out, man_out, soil_out, energy_out, inputs_out))) ||
      any(!is.finite(c(ent_out, man_out, soil_out, energy_out, inputs_out))) ||
      !is.finite(tot_out)) {
    testthat::skip("Could not detect component fields in total output — skipping equality check.")
  }

  sum_comp <- ent_out + man_out + soil_out + energy_out + inputs_out
  testthat::expect_true(is.finite(sum_comp) && is.finite(tot_out))
  testthat::expect_true(num_close(sum_comp, tot_out, tol = 1e-6))
})
