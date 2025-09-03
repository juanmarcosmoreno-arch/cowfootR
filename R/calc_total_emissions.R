#' Calculate total emissions (robust and retro-compatible)
#'
#' Aggregates results from different sources (enteric, manure, soil, energy, inputs)
#' even if they don't use exactly the same field name for the total.
#'
#' @param ... Results from \code{calc_emissions_*()} functions (lists).
#' @return Object "cf_total" with breakdown (kg CO2eq by source) and total.
#' @export
calc_total_emissions <- function(...) {
  sources <- list(...)
  if (length(sources) == 0) stop("Must provide at least one emission source")

  # internal helpers -------------------------
  .first_non_null <- function(...) {
    x <- list(...)
    for (v in x) if (!is.null(v)) return(v)
    NULL
  }
  .num_or_null <- function(x) {
    if (is.null(x)) return(NULL)
    x <- suppressWarnings(as.numeric(x))
    if (length(x) == 1L && is.finite(x)) x else NULL
  }
  .sum_breakdown <- function(bd) {
    # Supports: numeric vector with names, list, data.frame
    if (is.null(bd)) return(NULL)

    # 1) numeric vector
    if (is.numeric(bd) && is.null(dim(bd))) {
      return(sum(bd, na.rm = TRUE))
    }

    # 2) list -> try unlist numeric
    if (is.list(bd) && !is.data.frame(bd)) {
      v <- suppressWarnings(unlist(bd, use.names = FALSE))
      v <- as.numeric(v)
      return(sum(v, na.rm = TRUE))
    }

    # 3) data.frame -> look for CO2 column
    if (is.data.frame(bd)) {
      cand <- c("co2eq_kg","CO2eq_kg","co2eq","kg_co2eq","emissions_kg","value","valor")
      col_ok <- intersect(cand, names(bd))
      if (length(col_ok) > 0) {
        v <- suppressWarnings(as.numeric(bd[[col_ok[1]]]))
        return(sum(v, na.rm = TRUE))
      }
      # if no clear column, try summing everything numeric
      nums <- unlist(bd[vapply(bd, is.numeric, logical(1))], use.names = FALSE)
      if (length(nums)) return(sum(nums, na.rm = TRUE))
    }

    NULL
  }
  .infer_source_name <- function(x, i) {
    nm <- .first_non_null(x$source, attr(x, "source"), x$type, x$category)
    if (is.null(nm)) nm <- paste0("source_", i)
    as.character(nm)
  }
  .extract_total <- function(x) {
    # Prioritizes typical total fields
    tot <- .first_non_null(
      .num_or_null(x$co2eq_kg),
      .num_or_null(x$total_co2eq_kg),
      .num_or_null(x$total_co2eq),
      .num_or_null(x$total),
      .num_or_null(x$emissions_total_kg)
    )
    if (!is.null(tot)) return(tot)

    # If no direct total, try calculating from breakdown
    bd <- .first_non_null(x$breakdown, x$emissions_breakdown, x$summary)
    tot_bd <- .sum_breakdown(bd)
    if (!is.null(tot_bd)) return(tot_bd)

    # Last attempt: sum all flattened numeric values (risky, but useful)
    flat <- suppressWarnings(as.numeric(unlist(x, use.names = FALSE)))
    if (length(flat)) {
      s <- sum(flat, na.rm = TRUE)
      if (is.finite(s) && s > 0) return(s)
    }

    NA_real_
  }
  # ------------------------------------------

  src_names <- character(length(sources))
  values    <- numeric(length(sources))

  for (i in seq_along(sources)) {
    x <- sources[[i]]
    if (!is.list(x)) {
      stop("All arguments must be results from calc_emissions_*() functions (got a non-list).")
    }
    src_names[i] <- .infer_source_name(x, i)
    values[i]    <- .extract_total(x)
    if (!is.finite(values[i])) {
      stop(sprintf("Could not extract a numeric total from source '%s'.", src_names[i]))
    }
  }

  # Aggregate by source name (if duplicates came in)
  breakdown <- tapply(values, src_names, sum, na.rm = TRUE)
  breakdown <- breakdown[order(names(breakdown))]

  total <- sum(breakdown, na.rm = TRUE)

  structure(
    list(
      breakdown   = breakdown,
      total_co2eq = total,
      n_sources   = length(sources),
      date        = Sys.Date()
    ),
    class = "cf_total"
  )
}

#' Print method for cf_total objects
#' @param x A cf_total object
#' @param ... Additional arguments passed to print methods (currently ignored)
#' @export
print.cf_total <- function(x, ...) {
  cat("Carbon Footprint - Total Emissions\n")
  cat("==================================\n")
  cat("Total CO2eq:", round(x$total_co2eq, 2), "kg\n")
  cat("Number of sources:", x$n_sources, "\n\n")
  cat("Breakdown by source:\n")
  for (i in seq_along(x$breakdown)) {
    cat(" ", names(x$breakdown)[i], ":", round(x$breakdown[i], 2), "kg CO2eq\n")
  }
  cat("\nCalculated on:", as.character(x$date), "\n")
  invisible(x)
}
