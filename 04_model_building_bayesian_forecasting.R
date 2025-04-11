library(tidyverse)
library(brms)
# ======================================================
# Bayesian Modeling of Retail Sales Indicators
# ======================================================
# This script estimates causal relationships among key 
# macroeconomic indicators using theoretically informed 
# Bayesian models. The structure is based on prior DAG 
# exploration and implements both pooled and hierarchical 
# models using the `brms` package.
# ======================================================

# ======================================================
# 1. Theoretical DAG-Informed Model Structure
# ======================================================
# Derived from the DAG exploration, we assume the following
# causal relationships among key indicators:
#
# - Retail Volume (V_t) is driven by:
#     - its own lag (V_{t-1})
#     - lagged unemployment (U_{t-1})
#     - lagged household income (I_{t-1})
#     - current consumer sentiment (S_t)
#
# - Consumer Sentiment (S_t) is influenced by:
#     - lagged income (I_{t-1})
#     - lagged unemployment (U_{t-1})
#
# - Price Index (P_t) is affected by:
#     - lagged retail volume (V_{t-1})
#     - lagged unemployment (U_{t-1})
#     - current income (I_t)
#
# These assumptions guide the specification of two models:
#   1. A **Pooled Model** across all countries
#   2. A **Hierarchical Model** with country-level variation


# ======================================================
# 2. Data Preparation
# ======================================================

# --- 2.1 Trim date range to analysis window ---
combined_q_trimmed <- readRDS("/Users/ian/Desktop/Engineering/combined_q_trimmed.rds")

# --- 2.2 Normalize key indicators within each country ---
combined_q_trimmed <- combined_q_trimmed %>%
  group_by(geo) %>%
  mutate(across(
    c(volume_index, price_index, sentiment, unemployment_rate, household_income),
    ~ as.numeric(scale(.)),
    .names = "{.col}_norm"
  )) %>%
  ungroup()

# --- 2.3 Create lag variables (1- and 2-quarter lags) ---
combined_q_lags <- combined_q_trimmed %>%
  group_by(geo) %>%
  arrange(time) %>%
  mutate(
    volume_lag1       = lag(volume_index_norm, 1),
    volume_lag2       = lag(volume_index_norm, 2),
    price_index_lag1  = lag(price_index_norm, 1),
    sentiment_lag1    = lag(sentiment_norm, 1),
    sentiment_lag2    = lag(sentiment_norm, 2),
    unemployment_lag1 = lag(unemployment_rate_norm, 1),
    unemployment_lag2 = lag(unemployment_rate_norm, 2),
    income_lag1       = lag(household_income_norm, 1),
    income_lag2       = lag(household_income_norm, 2)
  ) %>%
  ungroup()

# --- 2.4 Optional: Log-transform income (not normalized) ---
combined_q_lags <- combined_q_lags %>%
  mutate(logincome = log(household_income))

# ======================================================
# 3. Prior Specification for Bayesian Models
# ======================================================

priors <- c(
  # Volume Model
  prior(normal(100, 20), class = "Intercept", resp = "volumeindex"),
  prior(normal(0, 5), class = "b", coef = "volume_lag1", resp = "volumeindex"),
  prior(normal(0, 5), class = "b", coef = "price_index", resp = "volumeindex"),
  prior(normal(0, 5), class = "b", coef = "sentiment_norm", resp = "volumeindex"),
  prior(normal(0, 5), class = "b", coef = "income_lag1", resp = "volumeindex"),
  prior(normal(0, 5), class = "b", coef = "unemployment_lag1", resp = "volumeindex"),
  prior(exponential(1), class = "sigma", resp = "volumeindex"),
  
  # Price Index Model
  prior(normal(100, 20), class = "Intercept", resp = "priceindex"),
  prior(normal(0, 5), class = "b", coef = "volume_lag1", resp = "priceindex"),
  prior(normal(0, 5), class = "b", coef = "income_lag1", resp = "priceindex"),
  prior(normal(0, 5), class = "b", coef = "unemployment_lag1", resp = "priceindex"),
  prior(exponential(1), class = "sigma", resp = "priceindex"),
  
  # Sentiment Model
  prior(normal(0, 5), class = "Intercept", resp = "sentiment"),
  prior(normal(0, 5), class = "b", coef = "income_lag1", resp = "sentiment"),
  prior(normal(0, 5), class = "b", coef = "unemployment_lag1", resp = "sentiment"),
  prior(exponential(1), class = "sigma", resp = "sentiment")
)

# ======================================================
# 4. Pooled Bayesian Model
# ======================================================
fit_bayes <- brm(
  bf(volume_index ~ volume_lag1 + price_index + sentiment_norm + income_lag1 + unemployment_lag1, family = gaussian()) +
    bf(price_index ~ volume_lag1 + income_lag1 + unemployment_lag1, family = gaussian()) +
    bf(sentiment ~ income_lag1 + unemployment_lag1, family = gaussian()) +
    set_rescor(FALSE),
  data = combined_q_lags,
  prior = priors,
  chains = 4,
  cores = 4,
  iter = 4000,
  seed = 42,
  control = list(adapt_delta = 0.99)
)
summary(fit_bayes)

# ======================================================
# 5. Hierarchical (Multilevel) Bayesian Model
# ======================================================
fit_bayes_hier <- brm(
  bf(volume_index ~ volume_lag1 + price_index + sentiment_norm + income_lag1 + unemployment_lag1 +
       (1 + volume_lag1 + price_index + sentiment_norm + income_lag1 + unemployment_lag1 | geo), family = gaussian()) +
    bf(price_index ~ volume_lag1 + income_lag1 + unemployment_lag1 +
         (1 + volume_lag1 + income_lag1 + unemployment_lag1 | geo), family = gaussian()) +
    bf(sentiment ~ income_lag1 + unemployment_lag1 +
         (1 + income_lag1 + unemployment_lag1 | geo), family = gaussian()) +
    set_rescor(FALSE),
  data = combined_q_lags,
  prior = priors,
  chains = 4,
  cores = 4,
  iter = 4000,
  seed = 42,
  control = list(adapt_delta = 0.99)
)

# --- View Hierarchical Model Summary ---
summary(fit_bayes_hier)
