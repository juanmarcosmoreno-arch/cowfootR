# Helper functions and utilities for tests

# Create a minimal valid farm dataset
create_test_farm <- function(farm_id = "TestFarm",
                            milk_litres = 600000,
                            cows_milking = 100) {
  data.frame(
    FarmID = farm_id,
    Milk_litres = milk_litres,
    Cows_milking = cows_milking,
    Area_total_ha = 120,
    stringsAsFactors = FALSE
  )
}

# Create emissions objects for testing
create_test_emissions <- function() {
  list(
    enteric = list(source = "enteric", co2eq_kg = 50000),
    manure = list(source = "manure", co2eq_kg = 20000),
    soil = list(source = "soil", co2eq_kg = 15000),
    energy = list(source = "energy", co2eq_kg = 10000),
    inputs = list(source = "inputs", co2eq_kg = 25000)
  )
}

# Compare two numeric values with tolerance
expect_equal_tolerance <- function(actual, expected, tolerance = 0.01) {
  diff <- abs(actual - expected)
  expect_true(diff < tolerance,
              info = paste("Expected", expected, "but got", actual))
}
