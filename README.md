# Neighborhood Park Access, Physical Activity, and Community Mental Health Outcomes
**Claire Meli** | Neighborhoods and Health (Sociology 75) | Dartmouth College | Fall 2022

---

## Overview

This project analyzes the relationship between census tract-level public park access and mental health outcomes across all U.S. census tracts, testing whether leisure time physical activity mediates that relationship. Three OLS regression models are estimated to isolate the direct effect of park area on mental health and assess the degree to which physical activity explains that effect.

**Key finding:** Greater neighborhood park area is negatively associated with the proportion of residents reporting poor mental health, with leisure time physical activity mediating approximately 50% of that effect — suggesting parks may benefit mental health partly by encouraging physical activity.

---

## File

| File | Description |
|---|---|
| `Park_Project_Sample_Code.R` | Full analysis script: data loading, cleaning, merging, descriptive statistics, visualization, and regression modeling |

> **Note:** Raw data files are not included in this submission. See Data Sources below for public download links.

---

## Data Sources

All data is publicly available and was downloaded directly from the sources listed below.

| Dataset | Source | Description |
|---|---|---|
| NaNDA Parks Dataset (2018) | [University of Michigan NaNDA](https://nanda.isr.umich.edu) | Census tract-level park area proportions |
| CDC PLACES | [CDC PLACES](https://www.cdc.gov/places) | Mental health and physical activity measures by census tract |
| American Community Survey (ACS) | [Census Bureau](https://data.census.gov) | SES controls: race, educational attainment, unemployment, median household income |

---

## Method

Data from three sources was merged on census tract FIPS codes. The following transformations were applied prior to analysis:

- **Park area** — converted from proportion to percentage (multiplied by 100)
- **Physical activity** — CDC PLACES reports the percentage of adults with *no* leisure time physical activity; this was subtracted from 100 to produce a measure of *active* adults
- **Median income** — divided by 1,000 for interpretability in regression output
- **Multicollinearity check** — correlation between median income and unemployment rate was assessed prior to modeling; both were retained as controls

Three OLS regression models were estimated:

| Model | Specification |
|---|---|
| `fit_1` | Bivariate: Park → MentalHealth |
| `fit_2` | Park + SES controls (race, education, unemployment, income) |
| `fit_3` | Park + PhysicalActivity (mediator) + SES controls |

---

## Requirements

**R version:** 4.0 or higher recommended

**Packages:**
```r
install.packages(c("tidyverse", "ggthemes", "patchwork", "ggpubr"))
```

---

## Running the Script

1. Download the three data files from the sources listed above
2. Place them in a `/data` subfolder in the same directory as the R script
3. Open `Park_Project_Sample_Code.R` in RStudio
4. Run the script top to bottom — sections are clearly labeled with comments
