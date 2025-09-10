#' Calculate energy-related emissions
#'
#' Estimates CO2 emissions from fossil fuel use and electricity consumption
#' on dairy farms following IDF/IPCC methodology.
#'
#' @param diesel_l Numeric. Diesel consumption (liters/year). Default = 0.
#' @param petrol_l Numeric. Petrol/gasoline consumption (liters/year). Default = 0.
#' @param lpg_kg Numeric. LPG/propane consumption (kg/year). Default = 0.
#' @param natural_gas_m3 Numeric. Natural gas consumption (m³/year). Default = 0.
#' @param electricity_kwh Numeric. Electricity consumption (kWh/year). Default = 0.
#' @param country Character. Country code for electricity grid factors.
#'   Default = "UY" (Uruguay). Options include "UY", "AR", "BR", "NZ", "US", etc.
#' @param ef_diesel Numeric. Emission factor for diesel (kg CO2/liter).
#'   Default = 2.67 (IPCC 2019, combustion).
#' @param ef_petrol Numeric. Emission factor for petrol (kg CO2/liter).
#'   Default = 2.31 (IPCC 2019).
#' @param ef_lpg Numeric. Emission factor for LPG (kg CO2/kg).
#'   Default = 3.0 (IPCC 2019).
#' @param ef_natural_gas Numeric. Emission factor for natural gas (kg CO2/m³).
#'   Default = 2.0 (IPCC 2019).
#' @param ef_electricity Numeric. Emission factor for electricity (kg CO2/kWh).
#'   If NULL, uses country-specific grid factors.
#' @param include_upstream Logical. Include upstream emissions from fuel production?
#'   Default = FALSE (combustion only).
#' @param energy_breakdown Optional. Detailed breakdown by equipment/use (list or data.frame).
#'   If list, each element can include diesel_l, petrol_l, lpg_kg, natural_gas_m3, electricity_kwh.
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'   If "energy" is not included, returns an excluded record.
#'
#' @return A list with detailed emissions by fuel type, total (co2eq_kg), metadata,
#'   and (if provided) breakdown by use. Compatible with \code{calc_total_emissions()}.
#' @export
#' @examples
#' # Minimal, fast example (<<1s)
#' res <- calc_emissions_energy(
#'   diesel_l = 10,
#'   electricity_kwh = 100,
#'   country = "UY"
#' )
#' print(res$co2eq_kg)
calc_emissions_energy <- function(diesel_l = 0,
                                  petrol_l = 0,
                                  lpg_kg = 0,
                                  natural_gas_m3 = 0,
                                  electricity_kwh = 0,
                                  country = "UY",
                                  ef_diesel = 2.67,
                                  ef_petrol = 2.31,
                                  ef_lpg = 3.0,
                                  ef_natural_gas = 2.0,
                                  ef_electricity = NULL,
                                  include_upstream = FALSE,
                                  energy_breakdown = NULL,
                                  boundaries = NULL) {

  # --- helpers ---------------------------------------------------------------
  `%||%` <- function(x, y) if (is.null(x)) y else x

  # Extract scalar numeric from x[[field]]; NULL -> 0
  .get_num <- function(x, field) {
    val <- x[[field]]
    if (is.null(val)) return(0)
    as.numeric(val)
  }
  # ---------------------------------------------------------------------------

  # 1) System boundaries gate -------------------------------------------------
  if (is.list(boundaries) && !is.null(boundaries$include) &&
      !("energy" %in% boundaries$include)) {
    return(list(
      source = "energy",
      co2eq_kg = 0,
      methodology = "excluded_by_boundaries",
      excluded = TRUE
    ))
  }

  # 2) Input validation -------------------------------------------------------
  cons <- c(diesel_l, petrol_l, lpg_kg, natural_gas_m3, electricity_kwh)
  if (any(!is.finite(cons))) {
    stop("Energy consumption values must be finite numeric scalars")
  }
  if (any(cons < 0, na.rm = TRUE)) {
    stop("Energy consumption values must be non-negative")
  }

  # 3) Electricity grid emission factors -------------------------------------
  grid_factors <- list(
    UY = 0.08, AR = 0.35, BR = 0.12, NZ = 0.15,
    US = 0.45, AU = 0.75, DE = 0.40, DK = 0.25,
    NL = 0.35, IE = 0.30
  )
  if (is.null(ef_electricity)) {
    ef_electricity <- grid_factors[[country]]
    if (is.null(ef_electricity)) {
      warning(paste("Unknown country code:", country,
                    ". Using default 0.35 kg CO2/kWh"))
      ef_electricity <- 0.35
    }
  }

  # 4) If energy_breakdown is given, aggregate consumption by use -------------
  breakdown_emissions <- NULL
  if (!is.null(energy_breakdown)) {
    if (is.data.frame(energy_breakdown)) {
      diesel_l        <- sum(as.numeric(energy_breakdown$diesel_l        %||% 0), na.rm = TRUE)
      petrol_l        <- sum(as.numeric(energy_breakdown$petrol_l        %||% 0), na.rm = TRUE)
      lpg_kg          <- sum(as.numeric(energy_breakdown$lpg_kg          %||% 0), na.rm = TRUE)
      natural_gas_m3  <- sum(as.numeric(energy_breakdown$natural_gas_m3  %||% 0), na.rm = TRUE)
      electricity_kwh <- sum(as.numeric(energy_breakdown$electricity_kwh %||% 0), na.rm = TRUE)

      nm_uses <- rownames(energy_breakdown) %||% as.character(seq_len(nrow(energy_breakdown)))
      breakdown_emissions <- setNames(vector("list", length(nm_uses)), nm_uses)
      for (i in seq_along(nm_uses)) {
        use_diesel <- (as.numeric(energy_breakdown$diesel_l[i])        %||% 0) * ef_diesel
        use_petrol <- (as.numeric(energy_breakdown$petrol_l[i])        %||% 0) * ef_petrol
        use_lpg    <- (as.numeric(energy_breakdown$lpg_kg[i])          %||% 0) * ef_lpg
        use_gas    <- (as.numeric(energy_breakdown$natural_gas_m3[i])  %||% 0) * ef_natural_gas
        use_elec   <- (as.numeric(energy_breakdown$electricity_kwh[i]) %||% 0) * ef_electricity
        breakdown_emissions[[nm_uses[i]]] <- list(
          diesel_co2      = round(use_diesel, 2),
          petrol_co2      = round(use_petrol, 2),
          lpg_co2         = round(use_lpg, 2),
          natural_gas_co2 = round(use_gas, 2),
          electricity_co2 = round(use_elec, 2),
          total_co2       = round(use_diesel + use_petrol + use_lpg + use_gas + use_elec, 2)
        )
      }
    } else {
      # list-of-uses path (strictly typed with vapply)
      diesel_l        <- sum(vapply(energy_breakdown, .get_num, numeric(1), "diesel_l"),       na.rm = TRUE)
      petrol_l        <- sum(vapply(energy_breakdown, .get_num, numeric(1), "petrol_l"),       na.rm = TRUE)
      lpg_kg          <- sum(vapply(energy_breakdown, .get_num, numeric(1), "lpg_kg"),         na.rm = TRUE)
      natural_gas_m3  <- sum(vapply(energy_breakdown, .get_num, numeric(1), "natural_gas_m3"), na.rm = TRUE)
      electricity_kwh <- sum(vapply(energy_breakdown, .get_num, numeric(1), "electricity_kwh"),na.rm = TRUE)

      breakdown_emissions <- list()
      for (use_name in names(energy_breakdown)) {
        use_data <- energy_breakdown[[use_name]]
        use_diesel <- .get_num(use_data, "diesel_l")        * ef_diesel
        use_petrol <- .get_num(use_data, "petrol_l")        * ef_petrol
        use_lpg    <- .get_num(use_data, "lpg_kg")          * ef_lpg
        use_gas    <- .get_num(use_data, "natural_gas_m3")  * ef_natural_gas
        use_elec   <- .get_num(use_data, "electricity_kwh") * ef_electricity

        breakdown_emissions[[use_name]] <- list(
          diesel_co2      = round(use_diesel, 2),
          petrol_co2      = round(use_petrol, 2),
          lpg_co2         = round(use_lpg, 2),
          natural_gas_co2 = round(use_gas, 2),
          electricity_co2 = round(use_elec, 2),
          total_co2       = round(use_diesel + use_petrol + use_lpg + use_gas + use_elec, 2)
        )
      }
    }
  }

  # 5) Direct emissions -------------------------------------------------------
  diesel_co2      <- diesel_l * ef_diesel
  petrol_co2      <- petrol_l * ef_petrol
  lpg_co2         <- lpg_kg * ef_lpg
  natural_gas_co2 <- natural_gas_m3 * ef_natural_gas
  electricity_co2 <- electricity_kwh * ef_electricity
  total_direct    <- diesel_co2 + petrol_co2 + lpg_co2 + natural_gas_co2 + electricity_co2

  # 6) Upstream emissions (optional simple factors) --------------------------
  upstream_emissions <- 0
  if (isTRUE(include_upstream)) {
    upstream_factors <- list(diesel = 0.15, petrol = 0.12, lpg = 0.08,
                             natural_gas = 0.10, electricity = 0.05)
    upstream_emissions <-
      diesel_co2 * upstream_factors$diesel +
      petrol_co2 * upstream_factors$petrol +
      lpg_co2 * upstream_factors$lpg +
      natural_gas_co2 * upstream_factors$natural_gas +
      electricity_co2 * upstream_factors$electricity
  }

  total_emissions <- total_direct + upstream_emissions

  # 7) Result object ----------------------------------------------------------
  result <- list(
    source = "energy",
    fuel_emissions = list(
      diesel_co2_kg      = round(diesel_co2, 2),
      petrol_co2_kg      = round(petrol_co2, 2),
      lpg_co2_kg         = round(lpg_co2, 2),
      natural_gas_co2_kg = round(natural_gas_co2, 2),
      electricity_co2_kg = round(electricity_co2, 2)
    ),
    direct_co2eq_kg   = round(total_direct, 2),
    upstream_co2eq_kg = round(upstream_emissions, 2),
    co2eq_kg          = round(total_emissions, 2),
    emission_factors  = list(
      diesel_kg_co2_per_l        = ef_diesel,
      petrol_kg_co2_per_l        = ef_petrol,
      lpg_kg_co2_per_kg          = ef_lpg,
      natural_gas_kg_co2_per_m3  = ef_natural_gas,
      electricity_kg_co2_per_kwh = ef_electricity,
      electricity_country        = country
    ),
    inputs = list(
      diesel_l = diesel_l, petrol_l = petrol_l, lpg_kg = lpg_kg,
      natural_gas_m3 = natural_gas_m3, electricity_kwh = electricity_kwh,
      include_upstream = include_upstream
    ),
    methodology = paste0("IPCC 2019 emission factors",
                         if (include_upstream) " + upstream" else ""),
    standards = "IPCC 2019 Refinement, IDF 2022",
    date = Sys.Date()
  )

  if (!is.null(breakdown_emissions)) result$breakdown_by_use <- breakdown_emissions

  if (is.finite(total_direct) && total_direct > 0) {
    result$energy_metrics <- list(
      electricity_share_pct    = round(100 * electricity_co2 / total_direct, 1),
      fossil_fuel_share_pct    = round(100 * (total_direct - electricity_co2) / total_direct, 1),
      co2_intensity_kg_per_mwh = if (electricity_kwh > 0)
        round(electricity_co2 / (electricity_kwh/1000), 2) else NA_real_
    )
  }

  return(result)
}
