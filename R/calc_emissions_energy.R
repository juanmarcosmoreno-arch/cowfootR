#' Calculate energy-related emissions
#'
#' Estimates CO2 emissions from fossil fuel use and electricity consumption
#' on dairy farms following IDF methodology.
#'
#' @param diesel_l Numeric. Diesel consumption (liters/year). Default = 0.
#' @param petrol_l Numeric. Petrol/gasoline consumption (liters/year). Default = 0.
#' @param lpg_kg Numeric. LPG/propane consumption (kg/year). Default = 0.
#' @param natural_gas_m3 Numeric. Natural gas consumption (m³/year). Default = 0.
#' @param electricity_kwh Numeric. Electricity consumption (kWh/year). Default = 0.
#' @param country Character. Country code for electricity grid factors.
#'   Default = "UY" (Uruguay). Options include "UY", "AR", "BR", "NZ", "US", etc.
#' @param ef_diesel Numeric. Emission factor for diesel (kg CO2/liter).
#'   Default = 2.67 (IPCC 2019, includes combustion only).
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
#' @param energy_breakdown List. Optional detailed breakdown by equipment/use.
#' @param boundaries Optional. An object from \code{set_system_boundaries()}.
#'   If "energy" is not included, returns 0.
#'
#' @return A list with detailed emissions by fuel type, end use, and metadata.
#' @export
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

  # Input validation
  if (any(c(diesel_l, petrol_l, lpg_kg, natural_gas_m3, electricity_kwh) < 0)) {
    stop("Energy consumption values must be non-negative")
  }

  # Exclude if boundaries do not include "energy"
  if (!is.null(boundaries) && !"energy" %in% boundaries$include) {
    return(list(
      source = "energy",
      co2eq_kg = 0,
      note = "Excluded by system boundaries"
    ))
  }

  # Country-specific electricity grid emission factors (kg CO2/kWh)
  grid_factors <- list(
    UY = 0.08, AR = 0.35, BR = 0.12, NZ = 0.15,
    US = 0.45, AU = 0.75, DE = 0.40, DK = 0.25,
    NL = 0.35, IE = 0.30
  )

  if (is.null(ef_electricity)) {
    ef_electricity <- grid_factors[[country]]
    if (is.null(ef_electricity)) {
      warning(paste("Unknown country code:", country, ". Using default 0.35 kg CO2/kWh"))
      ef_electricity <- 0.35
    }
  }

  # Energy breakdown (si se provee)
  if (!is.null(energy_breakdown)) {
    diesel_l       <- sum(sapply(energy_breakdown, function(x) x$diesel_l %||% 0))
    petrol_l       <- sum(sapply(energy_breakdown, function(x) x$petrol_l %||% 0))
    lpg_kg         <- sum(sapply(energy_breakdown, function(x) x$lpg_kg %||% 0))
    natural_gas_m3 <- sum(sapply(energy_breakdown, function(x) x$natural_gas_m3 %||% 0))
    electricity_kwh<- sum(sapply(energy_breakdown, function(x) x$electricity_kwh %||% 0))

    breakdown_emissions <- list()
    for (use_name in names(energy_breakdown)) {
      use_data <- energy_breakdown[[use_name]]
      use_diesel <- (use_data$diesel_l %||% 0) * ef_diesel
      use_petrol <- (use_data$petrol_l %||% 0) * ef_petrol
      use_lpg    <- (use_data$lpg_kg %||% 0) * ef_lpg
      use_gas    <- (use_data$natural_gas_m3 %||% 0) * ef_natural_gas
      use_elec   <- (use_data$electricity_kwh %||% 0) * ef_electricity

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

  # Direct emissions
  diesel_co2      <- diesel_l * ef_diesel
  petrol_co2      <- petrol_l * ef_petrol
  lpg_co2         <- lpg_kg * ef_lpg
  natural_gas_co2 <- natural_gas_m3 * ef_natural_gas
  electricity_co2 <- electricity_kwh * ef_electricity
  total_direct    <- diesel_co2 + petrol_co2 + lpg_co2 + natural_gas_co2 + electricity_co2

  # Upstream emissions
  upstream_emissions <- 0
  if (include_upstream) {
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

  # Resultado final
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
    co2eq_kg          = round(total_emissions, 2),  # 👈 corregido aquí
    emission_factors  = list(
      diesel_kg_co2_per_l       = ef_diesel,
      petrol_kg_co2_per_l       = ef_petrol,
      lpg_kg_co2_per_kg         = ef_lpg,
      natural_gas_kg_co2_per_m3 = ef_natural_gas,
      electricity_kg_co2_per_kwh= ef_electricity,
      electricity_country       = country
    ),
    inputs = list(
      diesel_l = diesel_l, petrol_l = petrol_l, lpg_kg = lpg_kg,
      natural_gas_m3 = natural_gas_m3, electricity_kwh = electricity_kwh,
      include_upstream = include_upstream
    ),
    methodology = paste0("IPCC 2019 emission factors",
                         ifelse(include_upstream, " + upstream", "")),
    standards = "IPCC 2019 Refinement, IDF 2022",
    date = Sys.Date()
  )

  if (!is.null(energy_breakdown)) result$breakdown_by_use <- breakdown_emissions

  if (electricity_kwh > 0 || sum(diesel_l, petrol_l, lpg_kg, natural_gas_m3) > 0) {
    result$energy_metrics <- list(
      electricity_share_pct  = round(electricity_co2 / total_direct * 100, 1),
      fossil_fuel_share_pct  = round((total_direct - electricity_co2) / total_direct * 100, 1),
      co2_intensity_kg_per_mwh = ifelse(electricity_kwh > 0,
                                        round(electricity_co2 / (electricity_kwh/1000), 2),
                                        NA)
    )
  }

  return(result)
}

# Null-coalescing operator helper
`%||%` <- function(x, y) if (is.null(x)) y else x
