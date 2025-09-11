# tests/testthat/helper-utils.R
# --------------------------------------------------------------------
# Helper utilities for robust, signature-agnostic tests.
# These helpers let tests adapt to different function signatures
# (named args, positional args, or a single data/list argument),
# and extract numeric intensity values without assuming exact output
# shapes or column names.
# --------------------------------------------------------------------

# Are two numeric vectors close within a tolerance?
# Useful when a function performs internal rounding or minor transforms.
num_close <- function(x, y, tol = 1e-8) {
  x <- suppressWarnings(as.numeric(x))
  y <- suppressWarnings(as.numeric(y))
  isTRUE(all(abs(x - y) < tol, na.rm = TRUE))
}

# Extract all finite numeric values from a list/data.frame/atomic vector.
# This is a fallback when the output structure is not strictly specified.
pluck_numeric <- function(x) {
  if (is.null(x)) return(numeric())
  v <- if (is.data.frame(x)) unlist(as.list(x)) else unlist(x, use.names = TRUE)
  v <- suppressWarnings(as.numeric(v))
  v[is.finite(v)]
}

# Pick the FIRST numeric field whose name matches any of the provided patterns.
# Example patterns for intensities: c("per_ha", "intens", "ha") or c("per_litre","intens","milk")
# If nothing matches, returns numeric(0) and the calling test can skip gracefully.
pick_named_numeric <- function(x, patterns = c("intens", "per_")) {
  if (is.null(x)) return(numeric(0))

  # data.frame case
  if (is.data.frame(x)) {
    nm <- names(x); if (is.null(nm)) return(numeric(0))
    hits <- which(Reduce(`|`, lapply(patterns, function(p) grepl(p, nm, ignore.case = TRUE))))
    if (length(hits) == 0) return(numeric(0))
    v <- suppressWarnings(as.numeric(x[[hits[1]]]))
    return(v[is.finite(v)])
  }

  # list case
  if (is.list(x)) {
    nm <- names(x); if (is.null(nm)) return(numeric(0))
    hits <- which(Reduce(`|`, lapply(patterns, function(p) grepl(p, nm, ignore.case = TRUE))))
    if (length(hits) == 0) return(numeric(0))
    v <- suppressWarnings(as.numeric(x[[hits[1]]]))
    return(v[is.finite(v)])
  }

  # atomic vector case
  if (is.atomic(x)) {
    vx <- suppressWarnings(as.numeric(x))
    return(vx[is.finite(vx)])
  }

  numeric(0)
}

# Check whether a function accepts ALL specified argument names.
# Returns FALSE if formals() cannot be retrieved.
fn_accepts <- function(fn, names_vec) {
  fml <- try(formals(fn), silent = TRUE)
  if (inherits(fml, "try-error") || is.null(fml)) return(FALSE)
  fm_names <- names(fml)
  if (is.null(fm_names)) return(FALSE)
  all(names_vec %in% fm_names)
}

# Safely call a function trying three strategies, in this order:
#   1) Named canonical arguments, if the function accepts ALL of them.
#   2) Positional call, if the number of supplied args <= number of formals.
#   3) Single-object call (data/list), if the function has a single formal or
#      if it explicitly accepts `data` or `df`.
# If none of those succeed, the caller should handle the error (often by skipping).
#
# Args:
#   fn             : function to call
#   canonical_args : named list (e.g., list(total_CO2eq = 1000, area_ha = 50))
#   positional_args: list of values to pass positionally
#   df_args        : named list to be passed as a single object (data/df)
#
# Returns:
#   The function result, or throws an error if all strategies fail.
safe_call <- function(fn, canonical_args = list(), positional_args = list(), df_args = list()) {
  # 1) Named canonical arguments (only if ALL names are accepted)
  if (length(canonical_args) && fn_accepts(fn, names(canonical_args))) {
    return(do.call(fn, canonical_args))
  }

  # 2) Positional call (only if formals() is available and lengths make sense)
  fml <- try(formals(fn), silent = TRUE)
  if (!inherits(fml, "try-error") && !is.null(fml)) {
    if (length(positional_args) > 0 && length(positional_args) <= length(fml)) {
      return(do.call(fn, positional_args))
    }
  }

  # 3) Single-object call: prefer explicit `data` or `df`, otherwise map to the sole formal
  if (length(df_args)) {
    if (fn_accepts(fn, c("data"))) {
      return(do.call(fn, list(data = df_args)))
    }
    if (fn_accepts(fn, c("df"))) {
      return(do.call(fn, list(df = as.data.frame(df_args))))
    }
    if (!inherits(fml, "try-error") && length(fml) == 1) {
      nm <- names(fml)[1]
      return(do.call(fn, stats::setNames(list(df_args), nm)))
    }
  }

  stop("Could not adapt test call to the function signature (tests helper).")
}
