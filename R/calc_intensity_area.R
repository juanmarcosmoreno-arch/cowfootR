#' Calculate carbon footprint intensity per hectare
#'
#' Computes emissions intensity per unit of land area for dairy farm analysis.
#'
#' @param total_emissions Numeric or cf_total object. Total emissions in kg CO2eq
#'   (from \code{calc_total_emissions()}) or the object itself.
#' @param area_total_ha Numeric. Total farm area in hectares.
#' @param area_productive_ha Numeric. Productive/utilized area in hectares.
#'   If NULL, uses total area. Default = NULL.
#' @param area_breakdown Named list or named numeric vector. Optional detailed area breakdown by land use type.
#'   Names should be descriptive (e.g., "pasture_permanent", "crops_feed").
#' @param validate_area_sum Logical. Check if area breakdown sums to total? Default = TRUE.
#'
#' @details
#' The area_breakdown parameter allows detailed tracking by land use:
#' \preformatted{
#' area_breakdown = list(
#'   pasture_permanent = 80,
#'   pasture_temporary = 20,
#'   crops_feed = 15,
#'   crops_cash = 5,
#'   infrastructure = 2,
#'   woodland = 8
#' )
#' }
#'
#' @return A list of class "cf_area_intensity" with intensity metrics and area analysis.
#' @export
#'
#' @examples
#' # Basic calculation
#' calc_intensity_area(total_emissions = 85000, area_total_ha = 120)
#'
#' # With productive area distinction
#' calc_intensity_area(
#'   total_emissions = 95000,
#'   area_total_ha = 150,
#'   area_productive_ha = 135
#' )
#'
#' # With area breakdown
#' area_detail <- list(
#'   pasture_permanent = 80,
#'   pasture_temporary = 25,
#'   crops_feed = 20,
#'   infrastructure = 3,
#'   woodland = 7
#' )
#' calc_intensity_area(
#'   total_emissions = 88000,
#'   area_total_ha = 135,
#'   area_breakdown = area_detail
#' )
#'
#' # Using with calc_total_emissions output
#' # \donttest{
#' # b <- set_system_boundaries("farm_gate")
#' # e1 <- calc_emissions_enteric(100, boundaries = b)
#' # e2 <- calc_emissions_manure(100, boundaries = b)
#' # tot <- calc_total_emissions(e1, e2)
#' # calc_intensity_area(tot, area_total_ha = 120)
#' # }
calc_intensity_area <- function(total_emissions,
                                area_total_ha,
                                area_productive_ha = NULL,
                                area_breakdown = NULL,
                                validate_area_sum = TRUE) {

  # Extract emissions value if cf_total object is passed
  if (inherits(total_emissions, "cf_total")) {
    emissions_value <- total_emissions$total_co2eq
    emissions_breakdown <- total_emissions
  } else if (is.numeric(total_emissions)) {
    emissions_value <- total_emissions
    emissions_breakdown <- NULL
  } else {
    stop("total_emissions must be numeric or a cf_total object")
  }

  # Input validation
  if (length(emissions_value) != 1 || is.na(emissions_value) || emissions_value < 0) {
    stop("total_emissions must be a single non-negative number")
  }
  if (length(area_total_ha) != 1 || is.na(area_total_ha) || area_total_ha <= 0) {
    stop("area_total_ha must be a single positive number")
  }

  if (!is.null(area_productive_ha)) {
    if (length(area_productive_ha) != 1 || is.na(area_productive_ha) || area_productive_ha <= 0) {
      stop("area_productive_ha must be a single positive number")
    }
    if (area_productive_ha > area_total_ha) {
      stop("Productive area cannot exceed total area")
    }
  } else {
    area_productive_ha <- area_total_ha
  }

  # Validate area breakdown if provided
  if (!is.null(area_breakdown)) {
    # Allow named numeric vectors too
    if (is.list(area_breakdown)) {
      ab_values <- unlist(area_breakdown, use.names = TRUE)
    } else if (is.numeric(area_breakdown) && !is.null(names(area_breakdown))) {
      ab_values <- area_breakdown
    } else {
      stop("area_breakdown must be a named list or a named numeric vector")
    }

    if (any(!is.finite(ab_values)) || any(ab_values < 0)) {
      stop("All area_breakdown values must be finite non-negative numbers")
    }

    total_breakdown_area <- sum(ab_values)

    if (validate_area_sum) {
      if (abs(total_breakdown_area - area_total_ha) > 0.1) {
        stop(paste0("Area breakdown sum (", round(total_breakdown_area, 1),
                    " ha) doesn't match total area (", area_total_ha, " ha). ",
                    "Set validate_area_sum = FALSE to override."))
      }
    } else if (abs(total_breakdown_area - area_total_ha) > 0.1) {
      warning(paste0("Area breakdown sum (", round(total_breakdown_area, 1),
                     " ha) doesn't match total area (", area_total_ha, " ha)"))
    }
  }

  # Calculate basic intensities
  intensity_total <- emissions_value / area_total_ha
  intensity_productive <- emissions_value / area_productive_ha

  # Build result object
  result <- list(
    intensity_per_total_ha = round(intensity_total, 2),
    intensity_per_productive_ha = round(intensity_productive, 2),
    total_emissions_co2eq = emissions_value,
    area_total_ha = area_total_ha,
    area_productive_ha = area_productive_ha,
    land_use_efficiency = round(area_productive_ha / area_total_ha, 3),
    date = Sys.Date()
  )

  # Add area breakdown analysis if provided
  if (!is.null(area_breakdown)) {
    # ensure named numeric vector
    if (exists("ab_values")) {
      land_use_ha <- ab_values
    } else {
      land_use_ha <- unlist(area_breakdown, use.names = TRUE)
    }

    proportional_emissions <- vapply(land_use_ha, function(a) {
      round(emissions_value * (a / area_total_ha), 1)
    }, FUN.VALUE = numeric(1))

    area_percentages <- vapply(land_use_ha, function(a) {
      round((a / area_total_ha) * 100, 1)
    }, FUN.VALUE = numeric(1))

    result$area_breakdown <- list(
      land_use_ha = as.list(land_use_ha),
      land_use_percentages = as.list(area_percentages),
      proportional_emissions_co2eq = as.list(proportional_emissions),
      breakdown_total_ha = sum(land_use_ha)
    )
  }

  # Add emissions source breakdown if available
  if (!is.null(emissions_breakdown) && "breakdown" %in% names(emissions_breakdown)) {
    result$emissions_sources <- emissions_breakdown$breakdown
  }

  structure(result, class = "cf_area_intensity")
}

#' Print method for cf_area_intensity objects
#'
#' @param x A cf_area_intensity object
#' @param ... Additional arguments (ignored)
#' @return The input object `x`, invisibly.
#' @export
#' @examples
#' x <- list(
#'   intensity_per_total_ha = 900,
#'   intensity_per_productive_ha = 1100,
#'   land_use_efficiency = 0.92,
#'   total_emissions_co2eq = 108000,
#'   area_total_ha = 120,
#'   area_productive_ha = 110,
#'   date = Sys.Date()
#' )
#' class(x) <- "cf_area_intensity"
#' print(x)
print.cf_area_intensity <- function(x, ...) {
  cat("Carbon Footprint Area Intensity\n")
  cat("===============================\n")
  cat("Intensity (total area):", x$intensity_per_total_ha, "kg CO2eq/ha\n")
  cat("Intensity (productive area):", x$intensity_per_productive_ha, "kg CO2eq/ha\n\n")

  cat("Area summary:\n")
  cat(" Total area:", x$area_total_ha, "ha\n")
  cat(" Productive area:", x$area_productive_ha, "ha\n")
  cat(" Land use efficiency:", paste0(round(x$land_use_efficiency * 100, 1), "%\n\n"))

  if (!is.null(x$area_breakdown)) {
    cat("Land use breakdown:\n")
    for (nm in names(x$area_breakdown$land_use_ha)) {
      area <- x$area_breakdown$land_use_ha[[nm]]
      percentage <- x$area_breakdown$land_use_percentages[[nm]]
      emissions <- x$area_breakdown$proportional_emissions_co2eq[[nm]]
      cat(sprintf(" %s: %.1f ha (%.1f%%) -> %.0f kg CO2eq\n",
                  gsub("_", " ", nm), area, percentage, emissions))
    }
    cat("\n")
  }

  cat("Total emissions:", format(round(x$total_emissions_co2eq), big.mark = ","), "kg CO2eq\n")
  cat("Calculated on:", as.character(x$date), "\n")
  invisible(x)
}

#' Benchmark area intensity against regional data
#'
#' @param cf_area_intensity A cf_area_intensity object
#' @param region Character. Region for comparison ("uruguay", "argentina", "brazil",
#'   "new_zealand", "ireland", "global")
#' @param benchmark_data Named list. Custom benchmark data with mean and range
#'
#' @return Original object with added benchmarking information
#' @export
#' @examples
#' \donttest{
#' res <- calc_intensity_area(total_emissions = 90000, area_total_ha = 150, area_productive_ha = 140)
#' out <- benchmark_area_intensity(res, region = "uruguay")
#' # str(out$benchmarking)
#' }
benchmark_area_intensity <- function(cf_area_intensity,
                                     region = NULL,
                                     benchmark_data = NULL) {

  if (!inherits(cf_area_intensity, "cf_area_intensity")) {
    stop("Input must be a cf_area_intensity object")
  }

  # Default regional benchmarks (kg CO2eq/ha) - placeholders, reemplazar con fuentes reales (IDF/FAO/etc.)
  default_benchmarks <- list(
    uruguay = list(mean = 6000, range = c(5000, 7000),  source = "Placeholder"),
    argentina = list(mean = 6800, range = c(5500, 8500), source = "Placeholder"),
    brazil = list(mean = 7200, range = c(5500, 9000),   source = "Placeholder"),
    new_zealand = list(mean = 8500, range = c(7000, 10500), source = "Placeholder"),
    ireland = list(mean = 9200, range = c(8000, 11000), source = "Placeholder"),
    global = list(mean = 7500, range = c(4000, 12000),  source = "FAO/IDF (placeholder)")
  )

  if (!is.null(benchmark_data)) {
    if (!all(c("mean", "range") %in% names(benchmark_data))) {
      stop("benchmark_data must have 'mean' and 'range' elements")
    }
    benchmark <- benchmark_data
    if (is.null(benchmark$source)) benchmark$source <- "User provided"
  } else if (!is.null(region) && region %in% names(default_benchmarks)) {
    benchmark <- default_benchmarks[[region]]
  } else {
    stop("Must provide either a valid region or benchmark_data")
  }
  intensity <- cf_area_intensity$intensity_per_productive_ha

  # Calculate comparison metrics
  vs_mean_pct <- round((intensity / benchmark$mean - 1) * 100, 1)

  performance <- if (intensity < benchmark$range[1]) {
    "Excellent (below typical range)"
  } else if (intensity <= benchmark$mean) {
    "Good (below average)"
  } else if (intensity <= benchmark$range[2]) {
    "Average (within typical range)"
  } else {
    "Above average (above typical range)"
  }

  # Add benchmarking to the object
  cf_area_intensity$benchmarking <- list(
    region = region,
    benchmark_mean = benchmark$mean,
    benchmark_range = benchmark$range,
    benchmark_source = benchmark$source,
    vs_mean_percent = vs_mean_pct,
    performance_category = performance
  )

  cf_area_intensity
}
