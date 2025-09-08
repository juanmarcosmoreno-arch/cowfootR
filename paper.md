---
title: 'cowfootR: An R Package for Dairy Farm Carbon Footprint Assessment'
tags:
  - R
  - carbon footprint
  - dairy farming
  - greenhouse gas emissions
  - sustainability
authors:
  - name: Juan M. Moreno
    orcid: 0009-0002-8116-2871
    corresponding: true #
    affiliation: "1"
affiliations:
 - name: Conaprole, Uruguay
   index: 1
date: 06 September 2025
bibliography: paper.bib

# Summary

The cowfootR package is an open-source R package designed for comprehensive 
carbon footprint assessment of dairy farms, implementing internationally 
recognized methodologies including Intergovernmental Panel on Climate Change 
(IPCC) Guidelines and International Dairy Federation (IDF) standards. The 
package enables transparent and reproducible estimation of carbon emissions 
from dairy production systems through modular functions that estimate emissions 
from five key sources: enteric fermentation, manure management, soil nitrogen 
dynamics, energy consumption, and purchased inputs, supporting both Tier 1 and 
Tier 2 IPCC methodologies. Key features include standardized intensity metrics 
(kg CO₂eq per kg of fat-protein corrected milk, per hectare), batch processing 
capabilities for multiple farms, and regional benchmarking tools. By 
transforming complex carbon accounting into accessible workflows, cowfootR 
empowers researchers, agricultural consultants, and policymakers to evaluate 
mitigation strategies, monitor environmental progress, and enhance the 
sustainability of dairy operations while addressing the critical need for 
standardized, reproducible carbon assessment in agricultural systems.

# Statement of need

The environmental impact of milk production is a subject of growing global 
concern due to the sector's share of anthropogenic greenhouse gas (GHG) 
emissions. One of the key indicators in an environmental impact assessment is 
the carbon footprint (CF), which determines the total greenhouse gas emissions 
attributed to a particular product or process, expressed in terms of the carbon 
dioxide equivalent (CO₂e or CO₂eq). As far as milk production is concerned, the 
carbon footprint includes emissions from, e.g., enteric fermentation, fertiliser 
management, feed production, use of outside inputs, and energy consumption 
(Stolarski et al., 2025).
The dairy industry contributes approximately 4% of global greenhouse gas 
emissions, with carbon footprint values ranging from 0.78 to 3.20 kg CO₂eq kg⁻¹ 
of milk across different production systems (Flysjö et al., 2011; 
Stolarski et al., 2025). The Intergovernmental Panel on Climate Change 
emphasizes that livestock production systems require accurate quantification 
methods to support effective mitigation strategies and policy development 
(IPCC, 2019). Similarly, the International Dairy Federation has established 
comprehensive guidelines for standardized carbon footprint assessment, 
recognizing the critical need for consistent methodologies that enable fair 
comparison across different dairy systems while accounting for regional 
variations (IDF, 2022).
With increasing regulatory pressure from initiatives like the EU Green Deal and 
Corporate Sustainability Reporting Directive, there is urgent need for 
standardized, accessible tools to quantify dairy farm carbon footprints 
(The European Parliament and of the Council, 2022). Current life cycle 
assessment (LCA) software solutions have significant limitations: most are 
expensive commercial packages requiring specialized training, methodological 
inconsistencies limit result comparability (Pirlo, 2012), and many lack 
transparency or regional adaptation capabilities. These barriers prevent 
widespread adoption of standardized practices, particularly among smaller farms 
and developing regions.
The cowfootR package addresses these gaps by providing an open-source, 
standardized toolkit implementing IPCC Guidelines and IDF standards. The package 
features modular emission calculations covering the five key sources identified 
in dairy systems, flexible system boundaries, multiple calculation tiers following 
IPCC methodology, batch processing capabilities, and regional adaptation with 
location-specific emission factors. By ensuring methodological consistency while 
remaining accessible to researchers, consultants, policymakers, and farmers, 
cowfootR fills a critical gap in agricultural LCA software and enables broader 
adoption of standardized carbon assessment practices.


# Usage
With cowfootR, users can estimate emissions for dairy farms using a systematic, 
modular approach. The package follows a standard workflow \autoref{fig:wf}: defining system 
boundaries, calculating emissions by source, aggregating total emissions, 
and computing intensity metrics.

# Workflow

![Fig.1 Workflow\label{fig:wf}](man/figures/cowfoot_workflow.png)

# Availability

cowfootR package is available on CRAN 
(https://CRAN.R-project.org/package=cowfootR) and GitHub 
(https://github.com/juanmarcosmoreno/cowfootR). Documentation, including 
vignettes and examples, is provided to facilitate adoption.

# Acknowledgements

The author would like to thank the Sustainability Team at CONAPROLE for their 
valuable input and collaboration in the development and validation of this 
software. Their expertise in dairy farm operations and environmental assessment 
has been instrumental in ensuring the practical applicability and accuracy of 
the cowfootR package.

# References
