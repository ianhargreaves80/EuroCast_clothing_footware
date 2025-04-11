library(naniar)    # Visualizing and summarizing missing data
library(mice)      # Multiple Imputation via Chained Equations
library(skimr)     # Quick data summaries

combined_q_trimmed <- readRDS("filepath")

# ────────────────────────────────────────────────────────────────
# 8. Explore Structure and Missingness
# ────────────────────────────────────────────────────────────────

# Visualize missing values by variable
gg_miss_var(combined_q_filtered, show_pct = TRUE)

# Visualize missingness patterns
vis_miss(combined_q_filtered)

# ────────────────────────────────────────────────────────────────
# Explore Missingness by Country and Variable
# ────────────────────────────────────────────────────────────────

# Count NAs by country and variable
combined_q_filtered %>%
  pivot_longer(cols = c(price_index, volume_index, sentiment, 
                        unemployment_rate, household_income),
               names_to = "variable", values_to = "value") %>%
  group_by(geo, variable) %>%
  summarise(missing_pct = mean(is.na(value)) * 100, .groups = "drop") %>%
  arrange(desc(missing_pct)) %>%
  filter(missing_pct > 0) %>%
  print(n = 100)

# ────────────────────────────────────────────────────────────────
# TEMPORARY FILTER: Remove non-reporting countries
# Purpose: Improve modeling stability by excluding countries with
#          100% missing values in one or more core indicators.
#          For this testing phase only. Deeper data sourcing 
#          (e.g., alternative Eurostat proxies) may reintroduce
#          some of these countries in future iterations.
# ────────────────────────────────────────────────────────────────

non_reporting_countries <- c(
  "CH",   # Switzerland – no income/sentiment
  "EA",   # Euro Area aggregates
  "EA19", # Euro Area aggregates
  "EEA",  # European Economic Area
  "EU",   # European Union
  "EU28", # EU28 aggregate
  "HR",   # Croatia – no income
  "IS",   # Iceland – missing several indicators
  "LT",   # Lithuania – no income
  "LU",   # Luxembourg – no income
  "MK",   # North Macedonia – high missingness
  "NO",   # Norway – no sentiment
  "TR",   # Turkey – no income, partial sentiment
  "UK",   # United Kingdom – no sentiment
  "US"    # United States – non-EU benchmark, not needed
)

combined_q_trimmed <- combined_q_trimmed %>%
  filter(!geo %in% non_reporting_countries)

library(mice)

# Prepare data
mice_ready <- combined_q_filtered %>%
  mutate(geo = as.factor(geo)) %>%
  select(geo, time, price_index, volume_index, sentiment, 
         unemployment_rate, household_income)

# Run MICE imputation
imputed <- mice(mice_ready, 
                m = 1,                # Number of imputed datasets
                method = "pmm",       # Predictive Mean Matching
                maxit = 10,           # Max iterations
                seed = 123)           # For reproducibility

# Extract the first completed dataset
combined_q_trimmed <- complete(imputed, 1)
