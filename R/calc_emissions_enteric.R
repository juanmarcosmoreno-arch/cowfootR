#' Calculate enteric methane emissions
#'
#' Estimates enteric methane (CH4) emissions from cattle using IPCC Tier 1 or
#' Tier 2 approaches with practical defaults for dairy systems.
#'
#' @param n_animals Numeric scalar > 0. Number of animals.
#' @param cattle_category Character. One of "dairy_cows", "heifers", "calves", "bulls".
#'   Default = "dairy_cows".
#' @param production_system Character. One of "intensive", "extensive", "mixed".
#'   Default = "mixed".
#' @param avg_milk_yield Numeric >= 0. Average annual milk yield per cow (kg/year).
#'   Default = 6000. Used in Tier 2 fallback for dairy cows.
#' @param avg_body_weight Numeric > 0. Average live weight (kg). If NULL, a
#'   category-specific default is used (e.g. 550 kg for dairy cows).
#' @param dry_matter_intake Numeric > 0. Dry matter intake (kg/animal/day).
#'   If provided (Tier 2), overrides body-weight/energy-based estimation.
#' @param feed_inputs Named numeric vector/list with feed DM amounts in kg/year
#'   per herd (e.g., grain_dry, grain_wet, byproducts, proteins). Optional.
#'   If given and \code{dry_matter_intake} is NULL, DMI is inferred as
#'   \code{sum(feed_inputs)/(n_animals*365)}.
#' @param ym_percent Numeric in (0, 100]. Methane conversion factor Ym (% of GE to CH4).
#'   Default = 6.5.
#' @param emission_factor_ch4 Numeric > 0. If provided, CH4 EF (kg CH4/head/year)
#'   is used directly; otherwise it is calculated (Tier 1 or Tier 2).
#' @param tier Integer 1 or 2. Default = 1.
#' @param gwp_ch4 Numeric. GWP for CH4 (100-yr, AR6). Default = 27.2.
#' @param boundaries Optional list from \code{set_system_boundaries()}.
#'
#' @return List with CH4 (kg), CO2eq (kg), inputs, factors, and metadata.
#'   Includes \code{co2eq_kg} for compatibility with \code{calc_total_emissions()}.
#' @export
#'
#' @examples
#' \donttest{
#' # Tier 1, mixed dairy cows
#' calc_emissions_enteric(n_animals = 100)
#'
#' # Tier 2 with explicit DMI
#' calc_emissions_enteric(
#'   n_animals = 120, tier = 2, avg_milk_yield = 7500, dry_matter_intake = 18
#' )
#'
#' # Boundary exclusion: enteric not included
#' b <- list(include = c("manure", "energy"))
#' calc_emissions_enteric(100, boundaries = b)$co2eq_kg  # NULL → excluded
#' }
calc_emissions_enteric <- function(n_animals,
                                   cattle_category = "dairy_cows",
                                   production_system = "mixed",
                                   avg_milk_yield = 6000,
                                   avg_body_weight = NULL,
                                   dry_matter_intake = NULL,
                                   feed_inputs = NULL,
                                   ym_percent = 6.5,
                                   emission_factor_ch4 = NULL,
                                   tier = 1L,
                                   gwp_ch4 = 27.2,
                                   boundaries = NULL) {

  # ------------------------------ Validation ---------------------------------
  valid_categories <- c("dairy_cows", "heifers", "calves", "bulls")
  valid_systems    <- c("intensive", "extensive", "mixed")
  valid_tiers      <- c(1L, 2L)

  if (!is.finite(n_animals) || length(n_animals) != 1L || n_animals <= 0)
    stop("n_animals must be a single positive number")
  if (!is.character(cattle_category) || !(cattle_category %in% valid_categories))
    stop("Invalid cattle_category. Use: ", paste(valid_categories, collapse = ", "))
  if (!is.character(production_system) || !(production_system %in% valid_systems))
    stop("Invalid production_system. Use: ", paste(valid_systems, collapse = ", "))
  if (!is.numeric(tier) || !(as.integer(tier) %in% valid_tiers))
    stop("Invalid tier. Use 1 or 2.")
  tier <- as.integer(tier)
  if (!is.finite(avg_milk_yield) || avg_milk_yield < 0)
    stop("avg_milk_yield must be >= 0")
  if (!is.finite(ym_percent) || ym_percent <= 0 || ym_percent > 100)
    stop("ym_percent must be in (0, 100]")

  # Boundary exclusion: clean signal for calc_total_emissions()
  if (is.list(boundaries) && !is.null(boundaries$include) &&
      !("enteric" %in% boundaries$include)) {
    return(list(
      source = "enteric",
      category = cattle_category,
      co2eq_kg = NULL,                    # explicit exclusion → treated as zero
      methodology = "excluded_by_boundaries",
      excluded = TRUE
    ))
  }

  # Category defaults for body weight (if not supplied)
  if (is.null(avg_body_weight) || !is.finite(avg_body_weight) || avg_body_weight <= 0) {
    default_weights <- c(dairy_cows = 550, heifers = 350, calves = 150, bulls = 700)
    avg_body_weight <- unname(default_weights[[cattle_category]])
  }

  # --------------------------- Infer DMI if needed ---------------------------
  # If no DMI but feed_inputs provided (annual herd totals in kg DM),
  # approximate DMI per animal per day.
  if (is.null(dry_matter_intake) && !is.null(feed_inputs) && length(feed_inputs) > 0) {
    total_feed_kg <- suppressWarnings(sum(unlist(feed_inputs), na.rm = TRUE))
    if (is.finite(total_feed_kg) && total_feed_kg > 0) {
      dmi_inferred <- total_feed_kg / (n_animals * 365)
      if (is.finite(dmi_inferred) && dmi_inferred > 0)
        dry_matter_intake <- dmi_inferred
    }
  }
  if (!is.null(dry_matter_intake) && (!is.finite(dry_matter_intake) || dry_matter_intake <= 0))
    stop("dry_matter_intake must be positive if provided")

  # ---------------------- Compute/choose emission factor ---------------------
  ef_ch4 <- emission_factor_ch4

  if (is.null(ef_ch4)) {
    if (tier == 1L) {
      # Tier 1: simple category × system fixed EFs (kg CH4/head/year)
      tier1 <- list(
        dairy_cows = c(intensive = 120, extensive = 100, mixed = 115),
        heifers    = c(intensive =  85, extensive =  75, mixed =  80),
        calves     = c(intensive =  45, extensive =  40, mixed =  42),
        bulls      = c(intensive = 110, extensive =  95, mixed = 105)
      )
      ef_ch4 <- tier1[[cattle_category]][[production_system]]

    } else {
      # Tier 2
      if (!is.null(dry_matter_intake)) {
        # Preferred Tier 2: from DMI and GE content of feed (≈ 18.45 MJ/kg DM)
        # GE (GJ/yr) = DMI (kg/d) * 18.45 (MJ/kg) * 365 / 1000
        GE_GJ <- dry_matter_intake * 18.45 * 365 / 1000
        # CH4 (kg/yr/head) = GE * Ym(%) / 55.65 (MJ/kg CH4) * 1000 (MJ/GJ)
        ef_ch4 <- (GE_GJ * 1000 * (ym_percent / 100)) / 55.65

      } else if (cattle_category == "dairy_cows") {
        # Alternative Tier 2: simple energy-balance for dairy cows
        # Maintenance energy (MJ/d) ~ 0.335 * BW^0.75
        maint_MJ_d <- 0.335 * (avg_body_weight^0.75)
        # Lactation energy (MJ/d) ~ milk_kg/d * 5.15 (approx net energy)
        lact_MJ_d  <- (avg_milk_yield / 365) * 5.15
        # Pregnancy + activity small allowance (MJ/d)
        preg_act_MJ_d <- 10
        total_MJ_d <- maint_MJ_d + lact_MJ_d + preg_act_MJ_d

        # Convert to GE and then to CH4 with Ym
        # Assume 60% efficiency to get GE (very rough, doc-note only)
        GE_GJ <- (total_MJ_d * 365 / 0.60) / 1000
        ef_ch4 <- (GE_GJ * 1000 * (ym_percent / 100)) / 55.65

      } else {
        # Simple fallback for non-dairy categories when no DMI: scale with BW
        ef_ch4 <- avg_body_weight * 0.022  # kg CH4/yr/head (coarse)
      }
    }
  }

  # Guard against invalid EF and fallback to Tier 1 baseline if needed
  if (!is.finite(ef_ch4) || ef_ch4 <= 0) {
    warning("Tier 2 calculation produced an invalid EF; falling back to Tier 1 defaults.")
    tier <- 1L
    ef_ch4 <- switch(cattle_category,
                     dairy_cows = 115, heifers = 80, calves = 42, bulls = 105)
  }

  # ----------------------------- Emissions -----------------------------------
  ch4_annual   <- n_animals * ef_ch4
  co2eq_annual <- ch4_annual * gwp_ch4

  # ----------------------------- Result object --------------------------------
  list(
    source = "enteric",
    category = cattle_category,
    production_system = production_system,

    ch4_kg  = round(ch4_annual, 2),
    co2eq_kg = round(co2eq_annual, 2),

    emission_factors = list(
      emission_factor_ch4 = round(ef_ch4, 3),
      ym_percent = ym_percent,
      gwp_ch4 = gwp_ch4,
      method_used = paste0("Tier ", tier)
    ),

    inputs = list(
      n_animals = n_animals,
      avg_body_weight = avg_body_weight,
      avg_milk_yield = avg_milk_yield,
      dry_matter_intake = dry_matter_intake,
      feed_inputs = feed_inputs,
      tier = tier
    ),

    methodology = paste0("IPCC Tier ", tier,
                         ifelse(tier == 2L, " (GE-based where possible)", " (default factors)")),
    standards = "IPCC 2019 Refinement, IDF 2022",
    date = Sys.Date(),

    per_animal = list(
      ch4_kg  = round(ef_ch4, 3),
      co2eq_kg = round(ef_ch4 * gwp_ch4, 3),
      milk_intensity_kg_co2eq_per_kg_milk = if (cattle_category == "dairy_cows" && avg_milk_yield > 0) {
        round((ef_ch4 * gwp_ch4) / avg_milk_yield, 4)
      } else NA_real_
    )
  )
}
