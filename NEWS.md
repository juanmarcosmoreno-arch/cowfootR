# cowfootR 0.1.3

## Major changes

- **Clarified and standardized emission units across the package**.
  All emission calculation functions now consistently return **annual emissions**
  expressed as `kg CO2eq yr-1` (farm-level totals).
  This applies to:
  - `calc_emissions_enteric()`
  - `calc_emissions_manure()`
  - `calc_emissions_soil()`
  - `calc_emissions_energy()`
  - `calc_emissions_inputs()`
  - aggregated results from `calc_total_emissions()`

- Updated returned objects and documentation to ensure that temporal
  definitions of emission units are explicit and unambiguous, addressing
  reviewer feedback.

## Documentation

- Updated the **README** to explicitly state that absolute emissions are reported
  as annual values (`kg CO2eq yr-1`), and that intensity metrics are derived from
  annual data.
- Updated the *Get started* and *IPCC Methodology Tiers* vignettes to clarify:
  - system boundaries,
  - unit definitions,
  - aggregation logic.
- Improved function documentation (`@return` sections) for clarity and consistency.

## Internal structure

- Refactored helper logic for purchased inputs into a dedicated helper file
  (`inputs_helpers.R`) to improve modularity and testability.
- Improved internal consistency of boundary handling across emission modules.

## Tests

- Extended and updated unit tests to reflect clarified unit conventions.
- Ensured integration tests cover full farm-level workflows using annual emissions.

## Minor improvements

- Improved error messages and validation for emission factor inputs.
- Minor code clean-up and formatting improvements.

---
