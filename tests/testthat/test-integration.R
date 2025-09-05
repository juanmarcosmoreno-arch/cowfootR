# Integration tests for complete workflows

test_that("Complete farm calculation workflow works", {
  # Set boundaries
  boundaries <- set_system_boundaries("farm_gate")

  # Calculate emissions by source
  e_enteric <- calc_emissions_enteric(
    n_animals = 100,
    tier = 2,
    avg_milk_yield = 7000,
    boundaries = boundaries
  )

  e_manure <- calc_emissions_manure(
    n_cows = 100,
    manure_system = "liquid_storage",
    include_indirect = TRUE,
    boundaries = boundaries
  )

  e_soil <- calc_emissions_soil(
    n_fertilizer_synthetic = 1500,
    area_ha = 120,
    boundaries = boundaries
  )

  e_energy <- calc_emissions_energy(
    diesel_l = 8000,
    electricity_kwh = 45000,
    country = "UY",
    boundaries = boundaries
  )

  e_inputs <- calc_emissions_inputs(
    conc_kg = 200000,
    fert_n_kg = 1500,
    region = "global",
    boundaries = boundaries
  )

  # Calculate total
  total <- calc_total_emissions(e_enteric, e_manure, e_soil, e_energy, e_inputs)

  # Calculate intensities
  milk_intensity <- calc_intensity_litre(
    total,
    milk_litres = 750000,
    fat = 3.9,
    protein = 3.2
  )

  area_intensity <- calc_intensity_area(
    total,
    area_total_ha = 120,
    area_productive_ha = 115
  )

  # Verify complete workflow
  expect_true(total$total_co2eq > 0)
  expect_true(milk_intensity$intensity_co2eq_per_kg_fpcm > 0)
  expect_true(area_intensity$intensity_per_total_ha > 0)
  expect_equal(total$n_sources, 5)
})

test_that("End-to-end batch processing workflow", {
  # Create sample data - properly formatted
  farms_data <- data.frame(
    FarmID = c("Farm1", "Farm2", "Farm3"),
    Year = c(2023, 2023, 2023),
    Milk_litres = c(600000, 800000, 450000),
    Fat_percent = c(3.8, 4.0, 3.9),
    Protein_percent = c(3.2, 3.3, 3.1),
    Cows_milking = c(90, 120, 70),
    Cows_dry = c(15, 20, 10),
    Heifers_total = c(30, 40, 20),
    Calves_total = c(45, 60, 30),
    Area_total_ha = c(100, 150, 80),
    N_fertilizer_kg = c(5000, 7000, 3000),
    Diesel_litres = c(6000, 8500, 4000),
    Electricity_kWh = c(30000, 45000, 20000),
    Concentrate_feed_kg = c(150000, 200000, 100000),
    stringsAsFactors = FALSE
  )

  # Process batch
  boundaries <- set_system_boundaries("farm_gate")
  batch_result <- suppressMessages(
    calc_batch(
      data = farms_data,
      tier = 1,
      boundaries = boundaries,
      benchmark_region = "uruguay"
    )
  )

  # Verify batch results
  expect_s3_class(batch_result, "cf_batch_complete")
  expect_equal(batch_result$summary$n_farms_processed, 3)
  expect_equal(batch_result$summary$n_farms_successful, 3)

  # Check individual farm results
  for (i in 1:3) {
    farm <- batch_result$farm_results[[i]]
    expect_true(farm$success)
    expect_true(farm$emissions_total > 0)
    expect_true(farm$intensity_milk_kg_co2eq_per_kg_fpcm > 0)
    expect_equal(farm$benchmark_region, "uruguay")
  }
})

test_that("Partial boundaries workflow", {
  # Test with only enteric and manure emissions
  boundaries <- set_system_boundaries("partial", include = c("enteric", "manure"))

  e_enteric <- calc_emissions_enteric(n_animals = 100, boundaries = boundaries)
  e_manure <- calc_emissions_manure(n_cows = 100, boundaries = boundaries)
  e_soil <- calc_emissions_soil(n_fertilizer_synthetic = 1000, boundaries = boundaries)
  e_energy <- calc_emissions_energy(diesel_l = 5000, boundaries = boundaries)

  # Only enteric and manure should have emissions
  expect_true(e_enteric$co2eq_kg > 0)
  expect_true(e_manure$co2eq_kg > 0)
  expect_equal(e_soil$co2eq_kg, 0)
  expect_equal(e_energy$co2eq_kg, 0)

  total <- calc_total_emissions(e_enteric, e_manure, e_soil, e_energy)
  expect_equal(total$total_co2eq, e_enteric$co2eq_kg + e_manure$co2eq_kg)
})

