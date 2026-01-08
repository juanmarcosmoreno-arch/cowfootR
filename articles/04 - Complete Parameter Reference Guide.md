# Complete_Parameter_Reference_Guide

## Complete Parameter Reference Guide

This vignette provides a comprehensive reference for all parameters
across cowfootR functions, including units, valid options, typical
ranges, and data sources. Use this as a technical reference when setting
up calculations or troubleshooting data issues.

### Function Overview

cowfootR includes these main calculation functions: -
[`calc_emissions_enteric()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_enteric.md) -
Enteric fermentation methane -
[`calc_emissions_manure()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_manure.md) -
Manure management CH4 and N2O  
-
[`calc_emissions_soil()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_soil.md) -
Soil N2O emissions -
[`calc_emissions_energy()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_energy.md) -
Energy-related CO2 emissions -
[`calc_emissions_inputs()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_emissions_inputs.md) -
Purchased input emissions -
[`calc_total_emissions()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_total_emissions.md) -
Aggregation function -
[`calc_intensity_litre()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_intensity_litre.md) -
Milk intensity calculations -
[`calc_intensity_area()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_intensity_area.md) -
Area intensity calculations -
[`calc_batch()`](https://juanmarcosmoreno-arch.github.io/cowfootR/reference/calc_batch.md) -
Batch processing function

------------------------------------------------------------------------

### 1. calc_emissions_enteric() Parameters

#### Required Parameters

| Parameter   | Type    | Unit | Description       | Valid Range | Example |
|-------------|---------|------|-------------------|-------------|---------|
| `n_animals` | Numeric | head | Number of animals | \> 0        | 100     |

#### Animal Characteristics

| Parameter         | Type      | Unit    | Description               | Valid Range                                | Default      | Example      |
|-------------------|-----------|---------|---------------------------|--------------------------------------------|--------------|--------------|
| `cattle_category` | Character | \-      | Type of cattle            | “dairy_cows”, “heifers”, “calves”, “bulls” | “dairy_cows” | “dairy_cows” |
| `avg_body_weight` | Numeric   | kg      | Average live weight       | 100-800                                    | 550 (cows)   | 580          |
| `avg_milk_yield`  | Numeric   | kg/year | Annual milk yield per cow | 1000-15000                                 | 6000         | 7200         |

#### Production System

| Parameter           | Type      | Unit   | Description                | Valid Options                     | Default | Notes                        |
|---------------------|-----------|--------|----------------------------|-----------------------------------|---------|------------------------------|
| `production_system` | Character | \-     | System intensity           | “intensive”, “extensive”, “mixed” | “mixed” | Affects Tier 1 factors       |
| `dry_matter_intake` | Numeric   | kg/day | Daily DM intake per animal | 8-25 (cows)                       | NULL    | Required for accurate Tier 2 |

#### Feed Parameters

| Parameter     | Type       | Unit       | Description               | Valid Range | Default | Notes                                                     |
|---------------|------------|------------|---------------------------|-------------|---------|-----------------------------------------------------------|
| `feed_inputs` | Named list | kg DM/year | Annual feed consumption   | \> 0        | NULL    | Names: grain_dry, grain_wet, ration, byproducts, proteins |
| `ym_percent`  | Numeric    | %          | Methane conversion factor | 4.0-8.0     | 6.5     | Higher = more CH4 per unit energy                         |

#### Methodology Control

| Parameter             | Type    | Unit             | Description              | Valid Options | Default | Impact                                  |
|-----------------------|---------|------------------|--------------------------|---------------|---------|-----------------------------------------|
| `tier`                | Numeric | \-               | IPCC methodology tier    | 1, 2          | 1       | Tier 2 more accurate with detailed data |
| `emission_factor_ch4` | Numeric | kg CH4/head/year | Custom CH4 factor        | 40-150        | NULL    | Overrides tier calculations             |
| `gwp_ch4`             | Numeric | kg CO2eq/kg CH4  | Global Warming Potential | 25-30         | 27.2    | IPCC AR6 value                          |

------------------------------------------------------------------------

### 2. calc_emissions_manure() Parameters

#### Required Parameters

| Parameter | Type    | Unit | Description             | Valid Range | Default | Example |
|-----------|---------|------|-------------------------|-------------|---------|---------|
| `n_cows`  | Numeric | head | Total number of animals | \> 0        | \-      | 150     |

#### Manure System

| Parameter       | Type      | Unit | Description            | Valid Options                                                      | Default     | CH4 Impact     |
|-----------------|-----------|------|------------------------|--------------------------------------------------------------------|-------------|----------------|
| `manure_system` | Character | \-   | Management system type | “pasture”, “solid_storage”, “liquid_storage”, “anaerobic_digester” | “pasture”   | High variation |
| `climate`       | Character | \-   | Climate region         | “cold”, “temperate”, “warm”                                        | “temperate” | Affects MCF    |

#### Tier 2 Specific

| Parameter            | Type    | Unit     | Description                 | Valid Range | Default | Required For          |
|----------------------|---------|----------|-----------------------------|-------------|---------|-----------------------|
| `avg_body_weight`    | Numeric | kg       | Average live weight         | 400-700     | 600     | Tier 2 VS calculation |
| `diet_digestibility` | Numeric | fraction | Diet apparent digestibility | 0.5-0.8     | 0.65    | Tier 2 VS calculation |
| `retention_days`     | Numeric | days     | Days manure in system       | 10-200      | NULL    | System optimization   |
| `system_temperature` | Numeric | °C       | Average system temperature  | 5-40        | NULL    | MCF adjustment        |

#### Nitrogen Management

| Parameter           | Type    | Unit          | Description                | Valid Range | Default | Impact              |
|---------------------|---------|---------------|----------------------------|-------------|---------|---------------------|
| `n_excreted`        | Numeric | kg N/cow/year | N excretion per cow        | 80-150      | 100     | N2O emissions       |
| `ef_n2o_direct`     | Numeric | kg N2O-N/kg N | Direct N2O emission factor | 0.005-0.03  | 0.02    | IPCC 2019           |
| `include_indirect`  | Logical | \-            | Include indirect N2O?      | TRUE/FALSE  | FALSE   | +20-30% N2O         |
| `protein_intake_kg` | Numeric | kg/day        | Daily protein intake       | 1.5-4.0     | NULL    | Refines N excretion |

------------------------------------------------------------------------

### 3. calc_emissions_soil() Parameters

#### Nitrogen Inputs

| Parameter                | Type    | Unit      | Description                 | Valid Range | Typical Values       | Source              |
|--------------------------|---------|-----------|-----------------------------|-------------|----------------------|---------------------|
| `n_fertilizer_synthetic` | Numeric | kg N/year | Synthetic fertilizer N      | 0-5000      | 50-300 kg N/ha       | Purchase records    |
| `n_fertilizer_organic`   | Numeric | kg N/year | Organic fertilizer N        | 0-3000      | 0-100 kg N/ha        | Application records |
| `n_excreta_pasture`      | Numeric | kg N/year | N deposited while grazing   | 0-20000     | 80-120 kg N/cow/year | Calculated estimate |
| `n_crop_residues`        | Numeric | kg N/year | N in returned crop residues | 0-2000      | 10-50 kg N/ha        | Crop management     |

#### Site Conditions

| Parameter   | Type      | Unit     | Description            | Valid Options                    | Default        | N2O Impact              |
|-------------|-----------|----------|------------------------|----------------------------------|----------------|-------------------------|
| `soil_type` | Character | \-       | Soil drainage          | “well_drained”, “poorly_drained” | “well_drained” | 50% difference          |
| `climate`   | Character | \-       | Climate classification | “temperate”, “tropical”          | “temperate”    | 20% difference          |
| `area_ha`   | Numeric   | hectares | Total farm area        | \> 0                             | NULL           | For per-hectare metrics |

#### Emission Factors

| Parameter          | Type    | Unit            | Description                     | Valid Range | Default | Source                    |
|--------------------|---------|-----------------|---------------------------------|-------------|---------|---------------------------|
| `ef_direct`        | Numeric | kg N2O-N/kg N   | Direct emission factor          | 0.005-0.025 | NULL    | IPCC 2019 by soil/climate |
| `include_indirect` | Logical | \-              | Include volatilization/leaching | TRUE/FALSE  | TRUE    | +30-50% total N2O         |
| `gwp_n2o`          | Numeric | kg CO2eq/kg N2O | N2O warming potential           | 265-300     | 273     | IPCC AR6                  |

------------------------------------------------------------------------

### 4. calc_emissions_energy() Parameters

#### Fuel Consumption

| Parameter         | Type    | Unit        | Description                 | Typical Range | Default | EF (kg CO2/unit)    |
|-------------------|---------|-------------|-----------------------------|---------------|---------|---------------------|
| `diesel_l`        | Numeric | litres/year | Diesel consumption          | 2000-15000    | 0       | 2.67                |
| `petrol_l`        | Numeric | litres/year | Petrol/gasoline consumption | 500-3000      | 0       | 2.31                |
| `lpg_kg`          | Numeric | kg/year     | LPG consumption             | 100-1000      | 0       | 3.0                 |
| `natural_gas_m3`  | Numeric | m³/year     | Natural gas consumption     | 0-5000        | 0       | 2.0                 |
| `electricity_kwh` | Numeric | kWh/year    | Electricity consumption     | 10000-100000  | 0       | Variable by country |

#### Location and Factors

| Parameter          | Type      | Unit       | Description               | Valid Options                                  | Default | Notes                          |
|--------------------|-----------|------------|---------------------------|------------------------------------------------|---------|--------------------------------|
| `country`          | Character | \-         | Country for grid factors  | “UY”, “AR”, “BR”, “NZ”, “US”, “AU”, “DE”, etc. | “UY”    | Major impact on electricity EF |
| `ef_electricity`   | Numeric   | kg CO2/kWh | Custom electricity factor | 0.05-1.0                                       | NULL    | Overrides country default      |
| `include_upstream` | Logical   | \-         | Include fuel production   | TRUE/FALSE                                     | FALSE   | +10-15% total                  |

#### Grid Emission Factors (Built-in)

| Country       | Code | EF (kg CO2/kWh) | Source             |
|---------------|------|-----------------|--------------------|
| Uruguay       | UY   | 0.08            | Clean grid (hydro) |
| Argentina     | AR   | 0.35            | Mixed grid         |
| Brazil        | BR   | 0.12            | Hydro + renewables |
| New Zealand   | NZ   | 0.15            | Renewable majority |
| United States | US   | 0.45            | Fossil majority    |
| Australia     | AU   | 0.75            | Coal dominant      |

------------------------------------------------------------------------

### 5. calc_emissions_inputs() Parameters

#### Feed Inputs

| Parameter            | Type    | Unit       | Description         | Typical Range | Default | EF Range (kg CO2eq/kg) |
|----------------------|---------|------------|---------------------|---------------|---------|------------------------|
| `conc_kg`            | Numeric | kg/year    | Concentrate feed    | 50000-500000  | 0       | 0.5-1.2                |
| `feed_grain_dry_kg`  | Numeric | kg DM/year | Dry grain feeds     | 20000-200000  | 0       | 0.3-0.6                |
| `feed_grain_wet_kg`  | Numeric | kg DM/year | Wet grain/silage    | 10000-100000  | 0       | 0.25-0.45              |
| `feed_ration_kg`     | Numeric | kg DM/year | Complete rations    | 30000-300000  | 0       | 0.4-0.8                |
| `feed_byproducts_kg` | Numeric | kg DM/year | Feed byproducts     | 5000-80000    | 0       | 0.1-0.25               |
| `feed_proteins_kg`   | Numeric | kg DM/year | Protein supplements | 5000-50000    | 0       | 1.2-2.8                |
| `feed_corn_kg`       | Numeric | kg DM/year | Corn grain specific | 10000-150000  | 0       | 0.35-0.65              |
| `feed_soy_kg`        | Numeric | kg DM/year | Soybean meal        | 5000-40000    | 0       | 1.5-3.2                |
| `feed_wheat_kg`      | Numeric | kg DM/year | Wheat grain         | 5000-100000   | 0       | 0.4-0.7                |

#### Other Inputs

| Parameter      | Type    | Unit      | Description                | Typical Range | Default | EF (kg CO2eq/kg)  |
|----------------|---------|-----------|----------------------------|---------------|---------|-------------------|
| `fert_n_kg`    | Numeric | kg N/year | Nitrogen fertilizer        | 500-5000      | 0       | 5.5-8.5           |
| `plastic_kg`   | Numeric | kg/year   | Agricultural plastics      | 100-1000      | 0       | 1.8-3.8           |
| `transport_km` | Numeric | km        | Average transport distance | 50-500        | NULL    | 1e-4 kg CO2/kg·km |

#### Regional Factors

| Parameter      | Type      | Unit | Description               | Valid Options                                            | Default  | Impact         |
|----------------|-----------|------|---------------------------|----------------------------------------------------------|----------|----------------|
| `region`       | Character | \-   | Regional emission factors | “global”, “EU”, “US”, “Brazil”, “Argentina”, “Australia” | “global” | ±20% variation |
| `fert_type`    | Character | \-   | Fertilizer type           | “urea”, “ammonium_nitrate”, “mixed”, “organic”           | “mixed”  | ±15% variation |
| `plastic_type` | Character | \-   | Plastic type              | “LDPE”, “HDPE”, “PP”, “mixed”                            | “mixed”  | ±20% variation |

#### Advanced Options

| Parameter             | Type    | Unit          | Description              | Valid Range | Default | Purpose                    |
|-----------------------|---------|---------------|--------------------------|-------------|---------|----------------------------|
| `include_uncertainty` | Logical | \-            | Run Monte Carlo analysis | TRUE/FALSE  | FALSE   | Uncertainty quantification |
| `ef_conc`             | Numeric | kg CO2eq/kg   | Override concentrate EF  | 0.3-1.5     | NULL    | Custom factors             |
| `ef_fert`             | Numeric | kg CO2eq/kg N | Override fertilizer EF   | 3.0-10.0    | NULL    | Local studies              |
| `ef_plastic`          | Numeric | kg CO2eq/kg   | Override plastic EF      | 1.0-5.0     | NULL    | Specific materials         |

------------------------------------------------------------------------

### 6. calc_intensity_litre() Parameters

#### Required Parameters

| Parameter         | Type                | Unit          | Description            | Valid Range | Notes                       |
|-------------------|---------------------|---------------|------------------------|-------------|-----------------------------|
| `total_emissions` | Numeric or cf_total | kg CO2eq/year | Total farm emissions   | \> 0        | From calc_total_emissions() |
| `milk_litres`     | Numeric             | litres/year   | Annual milk production | \> 0        | Farm records                |

#### Milk Composition

| Parameter      | Type    | Unit | Description             | Valid Range | Default | Source                    |
|----------------|---------|------|-------------------------|-------------|---------|---------------------------|
| `fat`          | Numeric | %    | Average fat content     | 2.5-6.0     | 4.0     | Lab analysis or processor |
| `protein`      | Numeric | %    | Average protein content | 2.5-4.5     | 3.3     | Lab analysis or processor |
| `milk_density` | Numeric | kg/L | Milk density            | 1.025-1.035 | 1.03    | Lab measurement           |

#### FPCM Calculation Formula

The Fat and Protein Corrected Milk (FPCM) formula used is:

    FPCM (kg) = milk_kg × (0.1226 × fat% + 0.0776 × protein% + 0.2534)

This standardizes milk to 4.0% fat and 3.3% protein for fair comparison.

------------------------------------------------------------------------

### 7. calc_intensity_area() Parameters

#### Required Parameters

| Parameter         | Type                | Unit          | Description          | Valid Range | Notes                       |
|-------------------|---------------------|---------------|----------------------|-------------|-----------------------------|
| `total_emissions` | Numeric or cf_total | kg CO2eq/year | Total farm emissions | \> 0        | From calc_total_emissions() |
| `area_total_ha`   | Numeric             | hectares      | Total farm area      | \> 0        | Property records            |

#### Area Breakdown

| Parameter            | Type       | Unit     | Description              | Valid Range  | Default    | Notes                              |
|----------------------|------------|----------|--------------------------|--------------|------------|------------------------------------|
| `area_productive_ha` | Numeric    | hectares | Productive/utilized area | ≤ total area | total area | Agricultural use only              |
| `area_breakdown`     | Named list | hectares | Detailed land use        | \> 0 each    | NULL       | Must sum to total if validate=TRUE |

#### Valid area_breakdown Names

| Name              | Description                  | Typical_Range |
|:------------------|:-----------------------------|:--------------|
| pasture_permanent | Permanent grassland          | 40-80%        |
| pasture_temporary | Rotational/temporary pasture | 5-20%         |
| crops_feed        | Feed crop production         | 5-15%         |
| crops_cash        | Cash crop production         | 0-10%         |
| infrastructure    | Buildings, roads, facilities | 2-5%          |
| woodland          | Forest/trees                 | 0-10%         |
| wetlands          | Water bodies, wetlands       | 0-5%          |
| other             | Other non-productive areas   | 0-5%          |

Valid area_breakdown Names and Descriptions

#### Validation

| Parameter           | Type    | Unit | Description               | Valid Options | Default | Purpose              |
|---------------------|---------|------|---------------------------|---------------|---------|----------------------|
| `validate_area_sum` | Logical | \-   | Check area breakdown sums | TRUE/FALSE    | TRUE    | Data quality control |

------------------------------------------------------------------------

### 8. calc_batch() Parameters

#### Data Input

| Parameter | Type       | Unit | Description                     | Requirements           | Example   |
|-----------|------------|------|---------------------------------|------------------------|-----------|
| `data`    | data.frame | \-   | Farm data with template columns | See template structure | farm_data |

#### Template Column Requirements

| Column_Group     | Column_Name            | Data_Type | Required |
|:-----------------|:-----------------------|:----------|:---------|
| Identification   | FarmID                 | character | Yes      |
| Identification   | Year                   | character | No       |
| Production       | Milk_litres            | numeric   | Yes      |
| Production       | Fat_percent            | numeric   | No       |
| Production       | Protein_percent        | numeric   | No       |
| Production       | Milk_density           | numeric   | No       |
| Herd_Composition | Cows_milking           | numeric   | Yes      |
| Herd_Composition | Cows_dry               | numeric   | No       |
| Herd_Composition | Heifers_total          | numeric   | No       |
| Herd_Composition | Calves_total           | numeric   | No       |
| Herd_Composition | Bulls_total            | numeric   | No       |
| Animal_Weights   | Body_weight_cows_kg    | numeric   | No       |
| Animal_Weights   | Body_weight_heifers_kg | numeric   | No       |
| Animal_Weights   | Body_weight_calves_kg  | numeric   | No       |
| Animal_Weights   | Body_weight_bulls_kg   | numeric   | No       |

Template Structure (First 15 columns)

#### Processing Options

| Parameter               | Type              | Unit | Description            | Valid Options                | Default     | Impact                        |
|-------------------------|-------------------|------|------------------------|------------------------------|-------------|-------------------------------|
| `tier`                  | Numeric           | \-   | IPCC methodology tier  | 1, 2                         | 2           | Accuracy vs data requirements |
| `boundaries`            | boundaries object | \-   | System boundaries      | From set_system_boundaries() | “farm_gate” | Scope of assessment           |
| `benchmark_region`      | Character         | \-   | Regional comparison    | “uruguay”, “argentina”, etc. | NULL        | Performance context           |
| `save_detailed_objects` | Logical           | \-   | Store detailed results | TRUE/FALSE                   | FALSE       | For debugging/analysis        |

------------------------------------------------------------------------

### 9. Parameter Validation and Quality Control

#### Automatic Validations

| Parameter_Type     | Validation_Rules                                    | Error_Actions                                   | User_Guidance                     |
|:-------------------|:----------------------------------------------------|:------------------------------------------------|:----------------------------------|
| Animal Numbers     | Must be positive integers                           | Stop execution with error message               | Check data entry and farm records |
| Production Metrics | Milk yield 1000-15000 kg/cow/year                   | Warning with guidance on typical ranges         | Verify annual vs daily units      |
| Area Data          | Area breakdown must sum to total (if validate=TRUE) | Stop or warn based on validate_area_sum setting | Review land use classification    |
| Input Quantities   | All quantities ≥ 0                                  | Stop with error message                         | Check for data entry errors       |
| Ratios             | Stocking rate 0.1-3.0 cows/ha                       | Warning about unusual values                    | Confirm farm characteristics      |

Built-in Validation Rules

#### Data Quality Indicators

| Indicator          | Formula                           | Excellent_Range | Good_Range | Poor_Range        | Unit           |
|:-------------------|:----------------------------------|:----------------|:-----------|:------------------|:---------------|
| Milk yield per cow | Milk_litres / Cows_milking / 1000 | 7000-9000       | 6000-7000  | \<5000 or \>10000 | kg/cow/year    |
| Stocking rate      | Cows_milking / Area_total_ha      | 1.2-1.8         | 0.8-1.2    | \<0.5 or \>2.5    | cows/ha        |
| Feed conversion    | Milk_litres / Concentrate_feed_kg | 3.0-5.0         | 2.0-3.0    | \<1.5 or \>6.0    | L milk/kg conc |
| Energy intensity   | Electricity_kWh / Milk_litres     | 0.04-0.06       | 0.06-0.08  | \>0.10            | kWh/L milk     |

Data Quality Assessment Indicators

### 10. Common Parameter Issues and Solutions

#### Missing Data Handling

| Missing_Parameter | Default_Used                | Accuracy_Impact | Recommended_Action                     |
|:------------------|:----------------------------|:----------------|:---------------------------------------|
| Body weights      | Species-specific defaults   | Low             | Use literature values for breed/region |
| DM intake         | Calculated from body weight | Medium          | Estimate from feeding standards        |
| Feed breakdown    | Concentrate only            | High            | Collect detailed feed records          |
| Area breakdown    | Total area only             | Medium          | Survey farm land use patterns          |
| Ym factor         | 6.5%                        | Medium          | Use regional studies or 6.0-6.8 range  |

Handling Missing Parameters

#### Unit Conversion Guide

| Parameter       | Common_Units          | cowfootR_Unit | Conversion_Factor            | Typical_Values     |
|:----------------|:----------------------|:--------------|:-----------------------------|:-------------------|
| Milk production | L, kg                 | L/year        | kg = L × density             | 1.03 kg/L          |
| Feed amounts    | kg fresh, kg DM, tons | kg DM/year    | DM = fresh × (1 - moisture%) | 35% DM corn silage |
| Fertilizer      | kg product, kg N      | kg N/year     | kg N = kg product × N%       | 46% N in urea      |
| Body weight     | kg, lbs               | kg            | kg = lbs ÷ 2.205             | 580 kg dairy cow   |
| Area            | ha, acres             | hectares      | ha = acres × 0.405           | 0.405 ha/acre      |

Unit Conversion Reference

#### Regional Parameter Adjustments

| Region    | Soy_EF_Range | Fertilizer_EF | Key_Differences              | Use_When               |
|:----------|:-------------|:--------------|:-----------------------------|:-----------------------|
| EU        | 2.1-3.2      | 5.8-7.9       | High soy transport costs     | European farms         |
| US        | 1.2-2.2      | 5.3-7.6       | Domestic grain production    | US/Canadian farms      |
| Brazil    | 0.9-1.6      | 6.0-8.3       | Local soy, high N fertilizer | Brazilian operations   |
| Argentina | 0.8-1.5      | 5.8-8.1       | Local grain/soy production   | Argentinian farms      |
| Australia | 1.8-3.0      | 5.4-7.7       | High transport distances     | Australian/NZ farms    |
| Global    | 1.5-2.8      | 5.5-7.8       | Average of all regions       | Unknown/mixed sourcing |

Regional Emission Factor Variations

### 11. Parameter Sensitivity Rankings

#### High Impact Parameters (\>15% result change)

| Parameter       | Function  | Impact_Direction | Typical_Variation | Result_Sensitivity | Data_Priority |
|:----------------|:----------|:-----------------|:------------------|:-------------------|:--------------|
| n_animals       | enteric   | Linear           | ±20%              | ±20%               | High          |
| milk_litres     | intensity | Inverse          | ±25%              | ±25%               | High          |
| conc_kg         | inputs    | Linear           | ±30%              | ±25%               | High          |
| ym_percent      | enteric   | Linear           | ±15%              | ±15%               | Medium        |
| avg_body_weight | enteric   | Linear           | ±10%              | ±8%                | Medium        |

High Impact Parameters (Priority for Accurate Data)

#### Medium Impact Parameters (5-15% result change)

| Parameter          | Impact_Range      | Collection_Difficulty | Recommendation             |
|:-------------------|:------------------|:----------------------|:---------------------------|
| n_fertilizer_kg    | 5-12%             | Easy                  | Get purchase records       |
| diet_digestibility | 8-15%             | Medium                | Estimate from feed quality |
| area_total_ha      | Area metrics only | Easy                  | Survey or property records |
| manure_system      | 10-25% manure     | Easy                  | Observe system             |
| region             | 5-20% inputs      | Easy                  | Select best match          |

Medium Impact Parameters

#### Low Impact Parameters (\<5% result change)

| Parameter    | Impact_Range | Default_Approach     | Notes                                |
|:-------------|:-------------|:---------------------|:-------------------------------------|
| plastic_kg   | \<2%         | Estimate broadly     | Small contribution unless very large |
| lpg_kg       | \<3%         | Estimate or ignore   | Often minimal in dairy               |
| gwp values   | \<5%         | Use package defaults | IPCC AR6 values recommended          |
| milk_density | \<2%         | Use 1.03             | Varies little                        |
| transport_km | \<5%         | Estimate 100-200 km  | Affects feed emissions only          |

Low Impact Parameters (Can Use Estimates)

### 12. Troubleshooting Common Issues

#### Error Messages and Solutions

| Error_Type            | Common_Cause                      | Solution                                                       | Prevention                         |
|:----------------------|:----------------------------------|:---------------------------------------------------------------|:-----------------------------------|
| Invalid region        | Typo in region name               | Check spelling: ‘EU’, ‘US’, ‘Brazil’, ‘Argentina’, ‘Australia’ | Use template dropdown lists        |
| Negative values       | Data entry error or wrong units   | Verify all quantities ≥ 0 and units are correct                | Implement data validation in Excel |
| Area sum mismatch     | Land use breakdown doesn’t add up | Review area_breakdown list or set validate_area_sum = FALSE    | Use GIS or survey data for areas   |
| Missing required data | Empty cells in required columns   | Fill required columns or use defaults                          | Document data requirements clearly |
| Unrealistic results   | Wrong units or extreme outliers   | Check units, outliers, and parameter ranges                    | Compare results with similar farms |

Common Error Messages and Solutions

#### Performance Optimization

For large batch processing:

| Aspect            | Recommendation                                               | Performance_Gain | Implementation_Effort |
|:------------------|:-------------------------------------------------------------|:-----------------|:----------------------|
| Data Preparation  | Pre-validate data, use consistent formats, remove empty rows | 50-70%           | Low                   |
| Processing Speed  | Process in chunks of 50-100 farms, use tier 1 for screening  | 30-50%           | Medium                |
| Memory Management | Set save_detailed_objects = FALSE for large batches          | 60-80%           | Low                   |
| Error Handling    | Implement robust error logging and recovery mechanisms       | Prevents crashes | High                  |
| Result Storage    | Export results incrementally, use database for \>1000 farms  | Scalable         | High                  |

Performance Optimization for Large Datasets

### 13. Advanced Parameter Combinations

#### Tier 2 Optimal Parameter Sets

| System_Type       | Key_Parameters                                            | Critical_Measurements                                | Typical_Accuracy |
|:------------------|:----------------------------------------------------------|:-----------------------------------------------------|:-----------------|
| Intensive Dairy   | High DM intake, concentrate feeds, precise body weights   | Feed composition, milk yield, system temperature     | ±10-15%          |
| Extensive Grazing | Pasture N excretion, extensive manure system, lower Ym    | Grazing management, soil conditions, climate data    | ±15-25%          |
| Mixed System      | Balanced feed inputs, moderate intensities                | Feed efficiency ratios, land use breakdown           | ±12-20%          |
| Organic System    | Organic fertilizers, lower input emissions, pasture focus | Organic input quantities, certification requirements | ±15-30%          |

Optimal Parameter Combinations by System Type

#### Parameter Interaction Effects

| Parameter_Pair                 | Interaction_Type | Effect_Magnitude | Management_Implication                            |
|:-------------------------------|:-----------------|:-----------------|:--------------------------------------------------|
| Body weight + DM intake        | Multiplicative   | Medium           | Heavier cows need proportionally more feed        |
| Ym% + Feed quality             | Exponential      | High             | Poor quality diets increase methane conversion    |
| Climate + Soil type            | Additive         | Medium           | Tropical poorly-drained soils have highest N2O    |
| Region + Feed sources          | Complex          | High             | Local feed sourcing reduces transport emissions   |
| Manure system + Retention time | Threshold        | Variable         | Short retention (\<30 days) limits CH4 conversion |

Important Parameter Interactions

### 14. Data Collection Protocols

#### Minimum Data Requirements by Objective

| Assessment_Goal      | Essential_Data                                      | Time_Investment | Accuracy_Target | Tier_Recommendation  |
|:---------------------|:----------------------------------------------------|:----------------|:----------------|:---------------------|
| Screening Assessment | Animal numbers, milk production, basic inputs       | 2-4 hours       | ±30%            | Tier 1               |
| Management Planning  | Detailed feeds, precise areas, management practices | 1-2 days        | ±15%            | Tier 2               |
| Carbon Trading       | Verified production, third-party validated inputs   | 3-5 days        | ±10%            | Tier 2 + validation  |
| Research Study       | Complete parameter set, uncertainty quantification  | 1-2 weeks       | ±5%             | Tier 2 + uncertainty |

Data Requirements by Assessment Objective

#### Data Collection Schedule

| Data_Category          | Collection_Frequency | Storage_Location   | Quality_Control             |
|:-----------------------|:---------------------|:-------------------|:----------------------------|
| Production Records     | Monthly              | Farm office        | Cross-check with processor  |
| Feed Purchases         | Each delivery        | Purchase invoices  | Verify units and quantities |
| Energy Consumption     | Monthly              | Utility bills      | Monitor seasonal patterns   |
| Land Management        | Seasonal             | Management records | Update land use changes     |
| Animal Characteristics | Annual               | Herd records       | Weigh representative sample |

Recommended Data Collection Schedule

### 15. Quality Assurance Framework

#### Validation Hierarchy

| Level                         | Validation_Type | Examples                                           | Error_Detection | Implementation    |
|:------------------------------|:----------------|:---------------------------------------------------|:----------------|:------------------|
| Level 1: Range Checks         | Automatic       | Values within expected ranges, correct units       | 90%             | Built-in cowfootR |
| Level 2: Consistency Checks   | Automatic       | Milk yield vs feed intake, stocking rate vs area   | 70%             | Built-in cowfootR |
| Level 3: Benchmark Comparison | Semi-automatic  | Results vs regional averages, peer farm comparison | 50%             | User comparison   |
| Level 4: Expert Review        | Manual          | Technical review by LCA specialist                 | 95%             | External expert   |

Quality Assurance Validation Levels

#### Red Flag Indicators

| Indicator          | Warning_Threshold             | Likely_Cause                                   | Investigation_Priority |
|:-------------------|:------------------------------|:-----------------------------------------------|:-----------------------|
| Milk intensity     | \>2.5 kg CO2eq/kg FPCM        | Poor productivity or data errors               | High                   |
| Feed efficiency    | \<1.0 L milk/kg concentrate   | Overestimated feed use or underestimated milk  | High                   |
| Energy use         | \>0.15 kWh/L milk             | Energy-intensive processes or errors           | Medium                 |
| Emission ratios    | Enteric \<30% of total        | Missing emission sources or calculation errors | High                   |
| System consistency | Intensive system + low inputs | Inconsistent system classification             | Medium                 |

Data Quality Red Flag Indicators

### Conclusion

This parameter reference guide provides comprehensive technical
specifications for all cowfootR functions. Use it as a reference when:

- Setting up new farm assessments
- Troubleshooting calculation issues  
- Validating data quality
- Understanding parameter sensitivities
- Optimizing data collection efforts

For practical applications, start with the function-specific sections,
then refer to validation and troubleshooting sections as needed. The
parameter sensitivity rankings help prioritize data collection efforts
for maximum accuracy improvement.

Remember that parameter accuracy requirements depend on the intended use
of results. Screening assessments can tolerate higher uncertainty than
management planning or carbon trading applications.

------------------------------------------------------------------------

*This reference guide covers cowfootR version 0.1.2 and follows IDF 2022
and IPCC 2019 methodological standards.*
