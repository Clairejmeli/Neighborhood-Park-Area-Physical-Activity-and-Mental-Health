# Code for Final Paper (Sociology 75: Neighborhoods and Health)
# Claire Meli
# Fall 22

# -------------------------------------------------------------------------
### Neighborhood Park Area, Physical Activity, and Mental Health

# This script analyze the relationship between the proportion of park area 
# at the census tract level and mental health outcomes across the U.S., testing
# whether leisure time physical activity at all mediates this relationship.
#
# Data sources:
#      NaNDA Parks Dataset (2018): tract-level park area proportions
#      CDC Places: mental and physical activity measures by census tract
#      American Community Survey (ACS): SES controls (race, education, 
#             unemployment, medical household income)
#
# OLS regression models:
#      fit_1: binvariate (Park -> MentalHealth)
#      fit_2: incorporates SES controls, no mediator varaible
#      fit_3: incorporates SES controls AND phsyical activity as mediator
# -------------------------------------------------------------------------


# Initial settings --------------------------------------------------------

library(tidyverse)
library(ggthemes)
library(patchwork)
library(rvest)
library(ggpubr)

# load data ---------------------------------------------------------------

##### proportion of parks per census tract
df_park <- read_csv("data/nanda_parks_tract_2018_01P.csv")

##### census data 
df_mental_health <- read_csv("data/CDC_Mental_Health.csv")
df_physical_activity <- read_csv("data/CDC_Physical_Activity.csv")

##### demographic data
df_ses <- read_csv("data/SES_Data.csv")

# get data we need ---------------------------------------------------------

##### park data - get census tract and park area proportion

df_park_stripped <- df_park %>% 
  select(tract_fips10, prop_park_area_tract) %>% 
  rename(Park = "prop_park_area_tract") %>% 
  # turn proportion into percentage (makes regression model work better)
  mutate(Park = Park * 100) 

##### census data

### mental health - get census tract and mental health measure

df_mental_health_stripped <- df_mental_health %>% 
  filter(GeographicLevel == "Census Tract") %>% 
  # just get numeric value of census tract
  mutate(Code = str_extract(UniqueID, "\\d{11}$")) %>% 
  select(Code, Data_Value) %>% 
  rename(MentalHealth = "Data_Value")

### physical activity - get census tract and physical activity measure

df_physical_activity_stripped <- df_physical_activity %>% 
  filter(GeographicLevel == "Census Tract") %>% 
  # just get numeric value of census tract
  mutate(Code = str_extract(UniqueID, "\\d{11}$")) %>% 
  select(Code, Data_Value) %>% 
  rename(PhysicalActivity = "Data_Value") %>% 
  # subtract percentage from 100 to get leisure time physical activity instead
  #   of NO leisure time physical activity
  mutate(PhysicalActivity = 100 - PhysicalActivity)

##### demographic data (only select relevant variables)

df_ses_stripped <- df_ses %>% 
  select(FIPS, 
         `% Total Population: White Alone`, 
         `% Population 25 Years and Over: Less than High School`,
         `% Civilian Population in Labor Force 16 Years and Over: Unemployed`,
         `Median Household Income (In 2020 Inflation Adjusted Dollars)`) %>% 
  filter(FIPS != "Geo_FIPS") %>% 
  rename(pop_white = "% Total Population: White Alone",
         pop_hs = "% Population 25 Years and Over: Less than High School",
         pop_unemployed = "% Civilian Population in Labor Force 16 Years and Over: Unemployed",
         median_income = "Median Household Income (In 2020 Inflation Adjusted Dollars)") %>% 
  mutate(pop_white = as.numeric(pop_white),
         pop_hs = as.numeric(pop_hs),
         pop_unemployed = as.numeric(pop_unemployed),
         median_income = as.numeric(median_income)) %>% 
  mutate(median_income = median_income / 1000)
  
# join tables -------------------------------------------------------------

##### join all tables on census tract

df_all <- df_park_stripped %>% 
  left_join(df_mental_health_stripped,
            by = c("tract_fips10" = "Code")) %>% 
  left_join(df_physical_activity_stripped,
            by = c("tract_fips10" = "Code")) %>% 
  left_join(df_ses_stripped,
            by = c("tract_fips10" = "FIPS")) %>% 
  filter(!is.na(Park)) %>% 
  filter(!is.na(MentalHealth)) %>% 
  filter(!is.na(PhysicalActivity)) %>% 
  filter(!is.na(pop_white)) %>%
  filter(!is.na(pop_hs)) %>% 
  filter(!is.na(pop_unemployed)) %>% 
  filter(!is.na(median_income))

# descriptive statistics --------------------------------------------------

##### get the average, median, min, max and standard deviation for each measure
df_descriptive <- df_all %>%
  summarise(across(
    c(Park, MentalHealth, PhysicalActivity, pop_white, pop_hs, pop_unemployed, median_income),
    list(
      mean = ~mean(.x, na.rm = TRUE),
      median = ~median(.x, na.rm = TRUE),
      sd = ~sd(.x, na.rm = TRUE),
      min = ~min(.x, na.rm = TRUE),
      max = ~max(.x, na.rm = TRUE)
    )
  ))
# df_descriptive %>% view()

# pivot table to make the view more clear (row names of variables, columns are each of the descriptive stats)
df_descriptive <- df_descriptive %>%
  pivot_longer(everything(),
               names_to = c("variable", "stat"),
               names_sep = "_(?=[^_]+$)",
               values_to = "value") %>%
  pivot_wider(names_from = stat, values_from = value)              
# df_descriptive %>% view()

# plot the data -----------------------------------------------------------

##### park vs. mental health not good for 14+ days
ggplot(df_all, aes(x = Park,
                   y = MentalHealth)) + 
  labs(title = "Mental Health vs. Proportion of Park Area",
       x = "Proportion of park area (out of 100)",
       y = "Percentage of people with mental health not good for 14+ days") +  
  geom_smooth(method = "lm", se = FALSE) +
  scale_x_continuous(limits = c(0, 100)) +
  scale_y_continuous(limits = c(0, 20)) +
  theme_few()

# Check correlation of income, poverty, and unemployment rate  ------------

# if any are above +/-0.6, remove one of the measures
abs(cor(df_all$median_income, df_all$pop_unemployed))
# cor(df_all$pop_housing_costs, df_all$median_income)
# cor(df_all$pop_housing_costs, df_all$pop_unemployed)
# cor(df_all$pop_unemployed, df_all$pop_poverty)
# cor(df_all$median_income, df_all$pop_poverty)

# Perform regression models -----------------------------------------------

##### park data (independent var.)
fit_1 <- lm(MentalHealth ~ Park, data = df_all)
par(mfrow = c(2, 2))
plot(fit_1)

### get coefficients and statistical significance
summary(fit_1)

### plot residuals
# ggplot(fit_1, aes(fit_1$residuals)) + 
#   geom_histogram(bins = 20) +
#   theme_few()

##### control for SES variables - no mediating var.
fit_2 <- lm(MentalHealth ~ Park + pop_white + pop_hs + pop_unemployed + 
              median_income,
              data = df_all)
# par(mfrow = c(2, 2))
# plot(fit_2)

### get coefficients and statistical significance
summary(fit_2)

### plot residuals
# ggplot(fit_2, aes(fit_2$residuals)) + 
#   geom_histogram(bins = 20) +
#   theme_few()

##### control for SES variables - mediating var.

### include leisure time physical activity
fit_3 <- lm(MentalHealth ~ Park + PhysicalActivity + pop_white + pop_hs + 
              pop_unemployed + median_income,
            data = df_all)
# par(mfrow = c(2, 2))
# plot(fit_3)

### get coefficients and statistical significance
summary(fit_3)

### plot residuals
# ggplot(fit_3, aes(fit_3$residuals)) + 
#   geom_histogram(bins = 20) +
#   theme_few()