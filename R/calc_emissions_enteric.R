#' Calculate enteric methane emissions
#'
#' Estimates enteric methane (CH4) emissions from dairy cattle
#' using IPCC Tier 1 or Tier 2 methodology with IDF-specific factors.
#'
#' @param n_animals Numeric. Number of animals.
#' @param cattle_category Character. Type of cattle. Options: "dairy_cows",
#'   "heifers", "calves", "bulls". Default = "dairy_cows".
#' @param production_system Character. Production system type. Options:
#'   "intensive", "extensive", "mixed". Default = "mixed".
#' @param avg_milk_yield Numeric. Average annual milk yield per cow (kg/year).
#'   Default = 6000. Used for Tier 2 calculations.
#' @param avg_body_weight Numeric. Average live weight (kg).
#'   Default = 550 for dairy cows.
#' @param dry_matter_intake Numeric. Dry matter intake (kg/animal/day). Optional.
#'   If provided, overrides body weight-based calculation in Tier 2.
#' @param feed_inputs Named vector or list with feed amounts in kg DM/year
#'   (grain_dry, grain_wet, ration, byproducts, proteins). Optional.
#' @param ym_percent Numeric. Methane conversion factor Ym (% of gross energy to CH4).
#'   Default = 6.5%.
#' @param emission_factor_ch4 Numeric. Emission factor (kg CH4 per head per year).
#'   If NULL, uses category and system-specific defaults.
#' @param tier Numeric. IPCC methodology tier (1 or 2). Default = 1.
#' @param gwp_ch4 Numeric. Global Warming Potential of CH4.
#'   Default = 27.2 (100-year horizon, IPCC AR6).
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'
#' @return A list with detailed emission calculations and metadata.
#' @export
#'
#' @examples
#' # Basic Tier 1 calculation
#' calc_emissions_enteric(n_animals = 100)
#'
#' # Tier 2 with detailed inputs
#' calc_emissions_enteric(
#'   n_animals = 120,
#'   tier = 2,
#'   avg_milk_yield = 7500,
#'   dry_matter_intake = 18
#' )
#'
#' # With system boundaries
#' boundaries <- set_system_boundaries("farm_gate")
#' calc_emissions_enteric(n_animals = 100, boundaries = boundaries)
calc_emissions_enteric <- function(n_animals,
                                   cattle_category = "dairy_cows",
                                   production_system = "mixed",
                                   avg_milk_yield = 6000,
                                   avg_body_weight = NULL,
                                   dry_matter_intake = NULL,
                                   feed_inputs = NULL,
                                   ym_percent = 6.5,
                                   emission_factor_ch4 = NULL,
                                   tier = 1,
                                   gwp_ch4 = 27.2,
                                   boundaries = NULL) {

  # === INPUT VALIDATION ===
  valid_categories <- c("dairy_cows", "heifers", "calves", "bulls")
  valid_systems   <- c("intensive", "extensive", "mixed")
  valid_tiers     <- c(1, 2)

  if (!cattle_category %in% valid_categories) {
    stop("Invalid cattle_category. Use: ", paste(valid_categories, collapse = ", "))
  }
  if (!production_system %in% valid_systems) {
    stop("Invalid production_system. Use: ", paste(valid_systems, collapse = ", "))
  }
  if (!tier %in% valid_tiers) {
    stop("Invalid tier. Use 1 or 2.")
  }
  if (n_animals < 0) {
    stop("Number of animals must be positive.")
  }
  if (avg_milk_yield < 0) {
    stop("Average milk yield must be positive.")
  }

  # Exclude if boundaries do not include enteric emissions
  if (!is.null(boundaries) && !"enteric" %in% boundaries$include) {
    return(list(
      source = "enteric",
      category = cattle_category,
      ch4_kg = 0,
      co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # Default body weights by category
  if (is.null(avg_body_weight)) {
    default_weights <- list(
      dairy_cows = 550,
      heifers    = 350,
      calves     = 150,
      bulls      = 700
    )
    avg_body_weight <- default_weights[[cattle_category]]
  }

  # === DETERMINE DRY MATTER INTAKE ===
  # If user didn't provide dry_matter_intake but did provide feed_inputs -> estimate
  if (is.null(dry_matter_intake) && !is.null(feed_inputs) && length(feed_inputs) > 0) {
    total_feed_kg <- sum(unlist(feed_inputs), na.rm = TRUE)
    dry_matter_intake <- total_feed_kg / (n_animals * 365)
  }

  # === CALCULATE EMISSION FACTOR ===
  if (is.null(emission_factor_ch4)) {
    if (tier == 1) {
      # Tier 1: Fixed factors based on category and system
      tier1_factors <- list(
        dairy_cows = list(intensive = 120, extensive = 100, mixed = 115),
        heifers    = list(intensive = 85,  extensive = 75,  mixed = 80),
        calves     = list(intensive = 45,  extensive = 40,  mixed = 42),
        bulls      = list(intensive = 110, extensive = 95,  mixed = 105)
      )
      emission_factor_ch4 <- tier1_factors[[cattle_category]][[production_system]]

    } else if (tier == 2) {
      if (!is.null(dry_matter_intake)) {
        # Tier 2 preferred method: based on dry matter intake
        gross_energy <- dry_matter_intake * 18.45 * 365 / 1000  # GJ/year
        emission_factor_ch4 <- (gross_energy * ym_percent/100) / 55.65 * 1000  # kg CH4/year/head
      } else if (cattle_category == "dairy_cows") {
        # Alternative approach using energy requirements
        maintenance_energy <- 0.335 * (avg_body_weight^0.75)
        lactation_energy   <- avg_milk_yield * 5.15 / 365
        pregnancy_energy   <- 10
        total_energy <- (maintenance_energy + lactation_energy + pregnancy_energy) * 365 / 1000
        gross_energy <- total_energy / 0.6
        emission_factor_ch4 <- (gross_energy * 1000 * ym_percent/100) / 55.65
      } else {
        # Simple estimation for non-dairy categories
        emission_factor_ch4 <- avg_body_weight * 0.022 * 365
      }
    }
  }

  # Fallback to Tier 1 if calculation resulted in invalid value
  if (is.null(emission_factor_ch4) || emission_factor_ch4 <= 0) {
    warning("Tier 2 calculation produced invalid result; falling back to Tier 1 defaults.")
    tier <- 1
    emission_factor_ch4 <- switch(cattle_category,
                                  dairy_cows = 115,
                                  heifers    = 80,
                                  calves     = 42,
                                  bulls      = 105)
  }

  # === CALCULATE EMISSIONS ===
  ch4_annual   <- n_animals * emission_factor_ch4
  co2eq_annual <- ch4_annual * gwp_ch4

  # === RETURN RESULTS ===
  list(
    source = "enteric",
    category = cattle_category,
    production_system = production_system,
    ch4_kg = round(ch4_annual, 2),
    co2eq_kg = round(co2eq_annual, 2),
    emission_factors = list(
      emission_factor_ch4 = round(emission_factor_ch4, 1),
      gwp_ch4 = gwp_ch4,
      method_used = paste0("Tier ", tier)
    ),
    inputs = list(
      n_animals = n_animals,
      avg_body_weight = avg_body_weight,
      avg_milk_yield = avg_milk_yield,
      dry_matter_intake = dry_matter_intake,
      ym_percent = ym_percent,
      feed_inputs = feed_inputs,
      tier = tier
    ),
    methodology = paste0("IPCC Tier ", tier,
                         ifelse(tier == 2, " (energy-based)", " (default factors)")),
    standards = "IPCC 2019 Refinement, IDF 2022",
    date = Sys.Date(),
    per_animal = list(
      ch4_kg = round(emission_factor_ch4, 1),
      co2eq_kg = round(emission_factor_ch4 * gwp_ch4, 2),
      milk_intensity = ifelse(
        cattle_category == "dairy_cows" & avg_milk_yield > 0,
        round((emission_factor_ch4 * gwp_ch4) / avg_milk_yield * 1000, 2),
        NA
      )
    )
  )
}
