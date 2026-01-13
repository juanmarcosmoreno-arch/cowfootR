# Internal helper: regional emission factors
# Not exported; used by calc_emissions_inputs()
get_regional_emission_factors <- function() {
  list(
    global = list(
      fertilizer = list(
        mixed = list(mean = 6.6, range = c(5.5, 7.8)),
        urea = list(mean = 7.2, range = c(6.1, 8.5)),
        ammonium_nitrate = list(mean = 6.1, range = c(5.2, 7.2)),
        organic = list(mean = 0.8, range = c(0.5, 1.2))
      ),
      feeds = list(
        concentrate = list(mean = 0.70, range = c(0.50, 1.20)),
        grain_dry   = list(mean = 0.40, range = c(0.30, 0.60)),
        grain_wet   = list(mean = 0.30, range = c(0.25, 0.45)),
        ration      = list(mean = 0.60, range = c(0.40, 0.80)),
        byproducts  = list(mean = 0.15, range = c(0.10, 0.25)),
        proteins    = list(mean = 1.80, range = c(1.20, 2.50)),
        corn        = list(mean = 0.45, range = c(0.35, 0.65)),
        soy         = list(mean = 2.10, range = c(1.50, 2.80)),
        wheat       = list(mean = 0.52, range = c(0.40, 0.70))
      ),
      plastic = list(
        mixed = list(mean = 2.5, range = c(1.8, 3.5)),
        LDPE  = list(mean = 2.8, range = c(2.2, 3.6)),
        HDPE  = list(mean = 2.3, range = c(1.9, 2.9)),
        PP    = list(mean = 2.1, range = c(1.6, 2.8))
      )
    ),
    EU = list(
      fertilizer = list(
        mixed = list(mean = 6.8, range = c(5.8, 7.9)),
        urea = list(mean = 7.5, range = c(6.5, 8.7)),
        ammonium_nitrate = list(mean = 6.3, range = c(5.5, 7.3)),
        organic = list(mean = 0.9, range = c(0.6, 1.3))
      ),
      feeds = list(
        concentrate = list(mean = 0.75, range = c(0.55, 1.10)),
        grain_dry   = list(mean = 0.42, range = c(0.32, 0.58)),
        grain_wet   = list(mean = 0.32, range = c(0.26, 0.42)),
        ration      = list(mean = 0.65, range = c(0.45, 0.85)),
        byproducts  = list(mean = 0.18, range = c(0.12, 0.28)),
        proteins    = list(mean = 2.20, range = c(1.60, 2.90)),
        corn        = list(mean = 0.48, range = c(0.38, 0.65)),
        soy         = list(mean = 2.60, range = c(2.10, 3.20)),
        wheat       = list(mean = 0.51, range = c(0.42, 0.68))
      ),
      plastic = list(
        mixed = list(mean = 2.3, range = c(1.9, 3.1)),
        LDPE  = list(mean = 2.6, range = c(2.1, 3.3)),
        HDPE  = list(mean = 2.1, range = c(1.8, 2.7)),
        PP    = list(mean = 1.9, range = c(1.5, 2.5))
      )
    ),
    US = list(
      fertilizer = list(
        mixed = list(mean = 6.4, range = c(5.3, 7.6)),
        urea = list(mean = 6.9, range = c(5.8, 8.1)),
        ammonium_nitrate = list(mean = 5.9, range = c(5.0, 6.9)),
        organic = list(mean = 0.7, range = c(0.4, 1.0))
      ),
      feeds = list(
        concentrate = list(mean = 0.65, range = c(0.48, 0.95)),
        grain_dry   = list(mean = 0.35, range = c(0.28, 0.48)),
        grain_wet   = list(mean = 0.28, range = c(0.22, 0.38)),
        ration      = list(mean = 0.55, range = c(0.38, 0.75)),
        byproducts  = list(mean = 0.12, range = c(0.08, 0.18)),
        proteins    = list(mean = 1.50, range = c(1.10, 2.10)),
        corn        = list(mean = 0.38, range = c(0.31, 0.52)),
        soy         = list(mean = 1.60, range = c(1.20, 2.20)),
        wheat       = list(mean = 0.45, range = c(0.35, 0.61))
      ),
      plastic = list(
        mixed = list(mean = 2.4, range = c(1.7, 3.4)),
        LDPE  = list(mean = 2.7, range = c(2.0, 3.5)),
        HDPE  = list(mean = 2.2, range = c(1.7, 2.8)),
        PP    = list(mean = 2.0, range = c(1.5, 2.7))
      )
    ),
    Brazil = list(
      fertilizer = list(
        mixed = list(mean = 7.1, range = c(6.0, 8.3)),
        urea = list(mean = 7.8, range = c(6.6, 9.2)),
        ammonium_nitrate = list(mean = 6.5, range = c(5.5, 7.6)),
        organic = list(mean = 0.6, range = c(0.3, 0.9))
      ),
      feeds = list(
        concentrate = list(mean = 0.68, range = c(0.51, 0.98)),
        grain_dry   = list(mean = 0.36, range = c(0.29, 0.49)),
        grain_wet   = list(mean = 0.29, range = c(0.23, 0.39)),
        ration      = list(mean = 0.58, range = c(0.41, 0.78)),
        byproducts  = list(mean = 0.13, range = c(0.09, 0.19)),
        proteins    = list(mean = 1.40, range = c(1.00, 1.90)),
        corn        = list(mean = 0.32, range = c(0.26, 0.44)),
        soy         = list(mean = 1.20, range = c(0.90, 1.60)),
        wheat       = list(mean = 0.58, range = c(0.45, 0.78))
      ),
      plastic = list(
        mixed = list(mean = 2.7, range = c(2.1, 3.6)),
        LDPE  = list(mean = 3.0, range = c(2.4, 3.8)),
        HDPE  = list(mean = 2.5, range = c(2.0, 3.2)),
        PP    = list(mean = 2.3, range = c(1.8, 3.0))
      )
    ),
    Argentina = list(
      fertilizer = list(
        mixed = list(mean = 6.9, range = c(5.8, 8.1)),
        urea = list(mean = 7.6, range = c(6.4, 8.9)),
        ammonium_nitrate = list(mean = 6.3, range = c(5.3, 7.4)),
        organic = list(mean = 0.5, range = c(0.3, 0.8))
      ),
      feeds = list(
        concentrate = list(mean = 0.62, range = c(0.46, 0.89)),
        grain_dry   = list(mean = 0.34, range = c(0.27, 0.46)),
        grain_wet   = list(mean = 0.27, range = c(0.21, 0.37)),
        ration      = list(mean = 0.56, range = c(0.39, 0.76)),
        byproducts  = list(mean = 0.11, range = c(0.07, 0.17)),
        proteins    = list(mean = 1.30, range = c(0.90, 1.80)),
        corn        = list(mean = 0.31, range = c(0.25, 0.42)),
        soy         = list(mean = 1.10, range = c(0.80, 1.50)),
        wheat       = list(mean = 0.41, range = c(0.32, 0.56))
      ),
      plastic = list(
        mixed = list(mean = 2.8, range = c(2.2, 3.7)),
        LDPE  = list(mean = 3.1, range = c(2.5, 3.9)),
        HDPE  = list(mean = 2.6, range = c(2.1, 3.3)),
        PP    = list(mean = 2.4, range = c(1.9, 3.1))
      )
    ),
    Australia = list(
      fertilizer = list(
        mixed = list(mean = 6.5, range = c(5.4, 7.7)),
        urea = list(mean = 7.0, range = c(5.9, 8.2)),
        ammonium_nitrate = list(mean = 6.0, range = c(5.1, 7.0)),
        organic = list(mean = 0.8, range = c(0.5, 1.1))
      ),
      feeds = list(
        concentrate = list(mean = 0.72, range = c(0.53, 1.05)),
        grain_dry   = list(mean = 0.41, range = c(0.33, 0.56)),
        grain_wet   = list(mean = 0.31, range = c(0.25, 0.41)),
        ration      = list(mean = 0.63, range = c(0.44, 0.84)),
        byproducts  = list(mean = 0.16, range = c(0.11, 0.24)),
        proteins    = list(mean = 1.90, range = c(1.40, 2.60)),
        corn        = list(mean = 0.46, range = c(0.37, 0.62)),
        soy         = list(mean = 2.30, range = c(1.80, 3.00)),
        wheat       = list(mean = 0.44, range = c(0.35, 0.59))
      ),
      plastic = list(
        mixed = list(mean = 2.6, range = c(2.0, 3.5)),
        LDPE  = list(mean = 2.9, range = c(2.3, 3.7)),
        HDPE  = list(mean = 2.4, range = c(1.9, 3.1)),
        PP    = list(mean = 2.2, range = c(1.7, 2.9))
      )
    )
  )
}


# Internal helper: uncertainty propagation for purchased inputs
# Not exported; used by calc_emissions_inputs()
calculate_input_uncertainties <- function(quantities, factors) {
  # Simple Monte Carlo on uniform ranges
  n <- 1000L

  sample_factor <- function(info) {
    if (is.null(info$range)) {
      return(rep(info$mean, n))
    }
    stats::runif(n, min = info$range[1], max = info$range[2])
  }

  conc_s  <- sample_factor(factors$conc)
  fert_s  <- sample_factor(factors$fert)
  plast_s <- sample_factor(factors$plastic)
  feed_s  <- lapply(factors$feeds, sample_factor)

  total <- numeric(n)
  total <- total + quantities$conc_kg    * conc_s
  total <- total + quantities$fert_n_kg  * fert_s
  total <- total + quantities$plastic_kg * plast_s

  for (nm in names(quantities$feeds)) {
    q <- quantities$feeds[[nm]]
    if (is.numeric(q) && length(q) == 1L && is.finite(q) && q > 0) {
      total <- total + q * feed_s[[nm]]
    }
  }

  list(
    mean = round(mean(total), 2),
    median = round(stats::median(total), 2),
    sd = round(stats::sd(total), 2),
    cv_percent = round(stats::sd(total) / mean(total) * 100, 1),
    percentiles = list(
      p5  = round(as.numeric(stats::quantile(total, 0.05)), 2),
      p25 = round(as.numeric(stats::quantile(total, 0.25)), 2),
      p75 = round(as.numeric(stats::quantile(total, 0.75)), 2),
      p95 = round(as.numeric(stats::quantile(total, 0.95)), 2)
    ),
    confidence_interval_95 = list(
      lower = round(as.numeric(stats::quantile(total, 0.025)), 2),
      upper = round(as.numeric(stats::quantile(total, 0.975)), 2)
    )
  )
}
