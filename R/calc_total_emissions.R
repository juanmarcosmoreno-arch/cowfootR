#' Calculate total emissions (robust and boundary-aware)
#'
#' Aggregates results from different sources (enteric, manure, soil, energy, inputs)
#' even if they don't use exactly the same field name for the total.
#' IMPORTANT: If a source explicitly reports \code{co2eq_kg = NULL} (e.g. excluded by
#' system boundaries), it is treated as zero and no fallback summation is attempted.
#'
#' @param ... Results from \code{calc_emissions_*()} functions (lists).
#' @return Object "cf_total" with breakdown (kg CO2eq by source) and total.
#' @export
#' @examples
#' \donttest{
#' # hipotético: totales ya agregados por fuente
#' enteric <- list(co2eq_kg = 45000, source = "enteric")
#' manure  <- list(co2eq_kg = 12000, source = "manure")
#' soil    <- list(co2eq_kg = 18000, source = "soil")
#' energy  <- list(co2eq_kg =  8000, source = "energy")
#'
#' tot <- calc_total_emissions(enteric = enteric, manure = manure, soil = soil, energy = energy)
#' # print(tot)
#' }
calc_total_emissions <- function(...) {
  sources <- list(...)
  if (length(sources) == 0) stop("Must provide at least one emission source")

  dot_names <- names(match.call(expand.dots = FALSE)$...)
  if (is.null(dot_names)) dot_names <- rep("", length(sources))

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
    if (is.null(bd)) return(NULL)

    if (is.numeric(bd) && is.null(dim(bd))) {
      return(sum(bd, na.rm = TRUE))
    }

    if (is.list(bd) && !is.data.frame(bd)) {
      v <- suppressWarnings(as.numeric(unlist(bd, use.names = FALSE)))
      return(sum(v, na.rm = TRUE))
    }

    if (is.data.frame(bd)) {
      cand <- c("co2eq_kg","CO2eq_kg","co2eq","kg_co2eq","emissions_kg","value","valor")
      col_ok <- intersect(cand, names(bd))
      if (length(col_ok) > 0) {
        v <- suppressWarnings(as.numeric(bd[[col_ok[1]]]))
        return(sum(v, na.rm = TRUE))
      }
      nums <- unlist(bd[vapply(bd, is.numeric, logical(1))], use.names = FALSE)
      if (length(nums)) return(sum(nums, na.rm = TRUE))
    }

    NULL
  }
  .infer_source_name <- function(x, i, dot_nm = "") {
    # prioridad: nombre provisto en ... → campo 'source' → atributo → type/category → fallback
    nm <- if (nzchar(dot_nm)) dot_nm else .first_non_null(x$source, attr(x, "source"), x$type, x$category)
    if (is.null(nm) || !nzchar(nm)) nm <- paste0("source_", i)
    as.character(nm)
  }
  .extract_total <- function(x) {
    if (isTRUE(x$excluded) || identical(x$methodology, "excluded_by_boundaries")) {
      return(0)
    }
    if ("co2eq_kg" %in% names(x) && is.null(x$co2eq_kg)) {
      return(0)
    }
    tot <- .first_non_null(
      .num_or_null(x$co2eq_kg),
      .num_or_null(x$total_co2eq_kg),
      .num_or_null(x$total_co2eq),
      .num_or_null(x$total),
      .num_or_null(x$emissions_total_kg)
    )
    if (!is.null(tot)) return(tot)

    bd <- .first_non_null(x$breakdown, x$emissions_breakdown, x$summary)
    tot_bd <- .sum_breakdown(bd)
    if (!is.null(tot_bd)) return(tot_bd)

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
    src_names[i] <- .infer_source_name(x, i, dot_nm = dot_names[i])
    values[i]    <- .extract_total(x)
    if (!is.finite(values[i])) {
      stop(sprintf("Could not extract a numeric total from source '%s'.", src_names[i]))
    }
  }

  breakdown <- tapply(values, src_names, sum, na.rm = TRUE)
  # asegurar vector named puro (no array) por si tapply devuelve 'array'
  breakdown <- as.numeric(breakdown); names(breakdown) <- names(tapply(values, src_names, sum, na.rm = TRUE))

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
#'
#' @param x A cf_total object
#' @param ... Additional arguments passed to print methods (currently ignored)
#' @return No return value, called for side effects. Prints formatted total emissions
#'   summary to the console and invisibly returns the input object.
#' @return The input object `x`, invisibly.
#' @export
#' @examples
#' \donttest{
#' x <- list(
#'   breakdown   = c(enteric = 45000, manure = 12000),
#'   total_co2eq = 57000,
#'   n_sources   = 2,
#'   date        = Sys.Date()
#' )
#' class(x) <- "cf_total"
#' # print(x)
#' }
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
