# Changelog

## cowfootR 0.1.3

CRAN release: 2026-01-13

### Major changes

- **Clarified and standardized emission units across the package**. All
  emission calculation functions now consistently return **annual
  emissions** expressed as `kg CO2eq yr-1` (farm-level totals). This
  applies to:
  - [`calc_emissions_enteric()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_enteric.md)
  - [`calc_emissions_manure()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_manure.md)
  - [`calc_emissions_soil()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_soil.md)
  - [`calc_emissions_energy()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_energy.md)
  - [`calc_emissions_inputs()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_inputs.md)
  - aggregated results from
    [`calc_total_emissions()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_total_emissions.md)
- Updated returned objects and documentation to ensure that temporal
  definitions of emission units are explicit and unambiguous, addressing
  reviewer feedback.

### Documentation

- Updated the **README** to explicitly state that absolute emissions are
  reported as annual values (`kg CO2eq yr-1`), and that intensity
  metrics are derived from annual data.
- Updated the *Get started* and *IPCC Methodology Tiers* vignettes to
  clarify:
  - system boundaries,
  - unit definitions,
  - aggregation logic.
- Improved function documentation (`@return` sections) for clarity and
  consistency.

### Internal structure

- Refactored helper logic for purchased inputs into a dedicated helper
  file (`inputs_helpers.R`) to improve modularity and testability.
- Improved internal consistency of boundary handling across emission
  modules.

### Tests

- Extended and updated unit tests to reflect clarified unit conventions.
- Ensured integration tests cover full farm-level workflows using annual
  emissions.

### Minor improvements

- Improved error messages and validation for emission factor inputs.
- Minor code clean-up and formatting improvements.

------------------------------------------------------------------------
