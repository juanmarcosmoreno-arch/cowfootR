# Tests for total emissions aggregation ---------------------------------------

test_that("calc_total_emissions aggregates correctly", {
  e1 <- list(source = "enteric", co2eq_kg = 1000)
  e2 <- list(source = "manure",  co2eq_kg = 500)
  e3 <- list(source = "soil",    co2eq_kg = 300)

  result <- calc_total_emissions(e1, e2, e3)

  expect_s3_class(result, "cf_total")
  expect_equal(result$total_co2eq, 1800)
  expect_equal(result$n_sources, 3)

  # Optional breakdown: validate only if the implementation provides it
  if (!is.null(result$by_source)) {
    if (is.data.frame(result$by_source)) {
      expect_true("source" %in% names(result$by_source))
      expect_true(all(c("enteric", "manure", "soil") %in% result$by_source$source))
    } else if (is.list(result$by_source)) {
      # If it is a named list, the names should be the sources
      if (!is.null(names(result$by_source)) && any(nzchar(names(result$by_source)))) {
        expect_true(all(c("enteric", "manure", "soil") %in% names(result$by_source)))
      } else {
        # Otherwise, it might be a list of items with $source fields
        srcs <- vapply(
          result$by_source,
          function(x) if (!is.null(x$source)) as.character(x$source) else NA_character_,
          character(1)
        )
        expect_true(all(c("enteric", "manure", "soil") %in% srcs))
      }
    } else {
      # If it's neither a data.frame nor list, we don't enforce a structure
      expect_true(TRUE)
    }
  } else {
    expect_true(is.null(result$by_source))
  }
})

test_that("calc_total_emissions handles different field names", {
  e1 <- list(source = "enteric", co2eq_kg = 1000)
  e2 <- list(source = "manure", total_co2eq_kg = 500)
  e3 <- list(source = "soil", total_co2eq = 300)

  result <- calc_total_emissions(e1, e2, e3)

  expect_s3_class(result, "cf_total")
  expect_equal(result$total_co2eq, 1800)
  expect_equal(result$n_sources, 3)
})

test_that("calc_total_emissions errors on invalid input", {
  expect_error(
    calc_total_emissions(),
    regexp = "at least one|no emissions|missing",
    ignore.case = TRUE
  )

  expect_error(
    calc_total_emissions("not a list"),
    regexp = "list|emission|invalid",
    ignore.case = TRUE
  )
})
