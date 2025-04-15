# ────────────────────────────────────────────────────────────────
# File: 01_ingest_eurostat.R
# Purpose: Download and prepare quarterly macroeconomic indicators 
#          for clothing/footwear retail analysis using Eurostat data
# ────────────────────────────────────────────────────────────────

# Load required packages
library(eurostat)     # Access to Eurostat datasets
library(lubridate)    # Date manipulation (e.g., flooring to quarters)
library(tidyverse)    # Core data manipulation and piping (dplyr, ggplot2, etc.)

# ────────────────────────────────────────────────────────────────
# Configuration: Define analysis window
# ────────────────────────────────────────────────────────────────

start_date <- as.Date("2005-01-01")
end_date   <- as.Date("2020-01-01")

# ────────────────────────────────────────────────────────────────
# 1. HICP: Clothing & Footwear Price Index (CP03)
# Unit: Index (2015 = 100); Frequency: Monthly
# Aggregated to quarterly average by geo
# ────────────────────────────────────────────────────────────────

hicp <- get_eurostat("prc_hicp_midx", time_format = "date") %>%
  filter(
    coicop == "CP03",      # Clothing & Footwear
    unit == "I05",         # Index, 2015 = 100
    freq == "M"            # Monthly data
  ) %>%
  mutate(time = floor_date(TIME_PERIOD, unit = "quarter")) %>%
  group_by(geo, time) %>%
  summarise(price_index = mean(values, na.rm = TRUE), .groups = "drop")

# ────────────────────────────────────────────────────────────────
# 2. Retail Trade Volume Index for Clothing & General Retail
# Categories: G47 (Retail), G47.7 (Clothing)
# Aggregated to quarterly average
# ────────────────────────────────────────────────────────────────

retail <- get_eurostat("sts_trtu_m", time_format = "date") %>%
  filter(
    nace_r2 %in% c("G47.7", "G47"), # Clothing retail + general retail
    s_adj == "SCA",                 # Seasonally and calendar adjusted
    unit %in% c("I15+", "I15")      # Volume index
  ) %>%
  mutate(time = floor_date(TIME_PERIOD, unit = "quarter")) %>%
  group_by(geo, time) %>%
  summarise(volume_index = mean(values, na.rm = TRUE), .groups = "drop")

# ────────────────────────────────────────────────────────────────
# 3. Consumer Sentiment Index (BS-CSMCI)
# Indicator of household confidence; Seasonally adjusted
# Aggregated to quarterly average
# ────────────────────────────────────────────────────────────────

sentiment <- get_eurostat("ei_bsco_m", time_format = "date") %>%
  filter(
    s_adj == "SA",               # Seasonally adjusted
    indic == "BS-CSMCI"         # Composite Consumer Sentiment Index
  ) %>%
  mutate(time = floor_date(TIME_PERIOD, unit = "quarter")) %>%
  group_by(geo, time) %>%
  summarise(sentiment = mean(values, na.rm = TRUE), .groups = "drop")

# ────────────────────────────────────────────────────────────────
# 4. Unemployment Rate (% of active population)
# Age group: 25–74; Seasonally adjusted
# Aggregated to quarterly average
# ────────────────────────────────────────────────────────────────

unemp <- get_eurostat("une_rt_m", time_format = "date") %>%
  filter(
    sex == "T",                    # Total (male + female)
    age == "Y25-74",               # Core working age
    s_adj == "SA",                 # Seasonally adjusted
    unit == "PC_ACT"               # Percentage of active population
  ) %>%
  mutate(time = floor_date(TIME_PERIOD, unit = "quarter")) %>%
  group_by(geo, time) %>%
  summarise(unemployment_rate = mean(values, na.rm = TRUE), .groups = "drop")

# ────────────────────────────────────────────────────────────────
# 5. Disposable Household Income (Proxy)
# Gross Domestic Income (D1, received) for sector S14_S15 (Households)
# ────────────────────────────────────────────────────────────────

gdi_raw <- get_eurostat("nasq_10_nf_tr", time_format = "date")

gdi_proxy <- gdi_raw %>%
  filter(
    sector == "S14_S15",     # Households and NPISHs
    na_item == "D1",         # Compensation of employees (gross income)
    direct == "RECV"         # Received income
  ) %>%
  rename(household_income = values) %>%
  select(geo, time = TIME_PERIOD, household_income)

# ────────────────────────────────────────────────────────────────
# 6. Combine All Indicators into a Single Quarterly Dataset
# ────────────────────────────────────────────────────────────────

combined_q <- hicp %>%
  left_join(retail,    by = c("geo", "time")) %>%
  left_join(sentiment, by = c("geo", "time")) %>%
  left_join(unemp,     by = c("geo", "time")) %>%
  left_join(gdi_proxy, by = c("geo", "time")) %>%
  arrange(geo, time)

# ────────────────────────────────────────────────────────────────
# 7. Filter Dataset to Analysis Time Range
# ────────────────────────────────────────────────────────────────

combined_q_trimmed <- combined_q %>%
  filter(time >= start_date, time <= end_date)

# ────────────────────────────────────────────────────────────────
# Output: `combined_q_trimmed` contains all prepared macro indicators
# ────────────────────────────────────────────────────────────────
# Save the cleaned dataset
