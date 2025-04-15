start_time <- Sys.time()

install.packages("ragg")
install.packages("brms")
install.packages("loo")
install.packages("bayesplot")
install.packages("broom.mixed")
install.packages("googledrive")

# ================================
# 🚀 Required Libraries
# ================================
library(tidyverse)
library(brms)
library(loo)
library(bayesplot)
library(broom.mixed)
library(googledrive)

# ================================
# 📅 Date Prefix for File Names
# ================================
today_str <- format(Sys.Date(), "%Y-%m-%d")

# ================================
# 🔐 Authenticate Google Drive
# ================================
drive_auth()

# Create Drive folders (if not already existing)
drive_folder_create <- function(folder_name) {
  folder <- drive_get(folder_name)
  if (nrow(folder) == 0) {
    folder <- drive_mkdir(folder_name)
  }
  return(folder)
}

pooled_folder <- drive_folder_create("EuroCast_Pooled_Model")
hier_folder   <- drive_folder_create("EuroCast_Hierarchical_Model")

# ================================
# 📦 Load and Prepare Data
# ================================
combined_q_trimmed <- readRDS(
  url("https://github.com/ianhargreaves80/EuroCast_clothing_footware/raw/refs/heads/main/combined_q_trimmed.rds")
)

combined_q_trimmed <- combined_q_trimmed %>%
  group_by(geo) %>%
  mutate(across(
    c(volume_index, price_index, sentiment, unemployment_rate, household_income),
    ~ as.numeric(scale(.)), .names = "{.col}_norm"
  )) %>%
  ungroup()

combined_q_lags <- combined_q_trimmed %>%
  group_by(geo) %>%
  arrange(time) %>%
  mutate(
    volume_lag1       = lag(volume_index_norm, 1),
    price_index_lag1  = lag(price_index_norm, 1),
    sentiment_lag1    = lag(sentiment_norm, 1),
    unemployment_lag1 = lag(unemployment_rate_norm, 1),
    income_lag1       = lag(household_income_norm, 1),
    logincome         = log(household_income)
  ) %>%
  ungroup()

# ================================
# 🔧 Priors
# ================================
priors <- c(
  prior(normal(100, 20), class = "Intercept", resp = "volumeindex"),
  prior(normal(0, 5), class = "b", coef = "volume_lag1", resp = "volumeindex"),
  prior(normal(0, 5), class = "b", coef = "price_index", resp = "volumeindex"),
  prior(normal(0, 5), class = "b", coef = "sentiment_norm", resp = "volumeindex"),
  prior(normal(0, 5), class = "b", coef = "unemployment_lag1", resp = "volumeindex"),
  prior(exponential(1), class = "sigma", resp = "volumeindex"),
  
  prior(normal(100, 20), class = "Intercept", resp = "priceindex"),
  prior(normal(0, 5), class = "b", coef = "income_lag1", resp = "priceindex"),
  prior(normal(0, 5), class = "b", coef = "unemployment_lag1", resp = "priceindex"),
  prior(exponential(1), class = "sigma", resp = "priceindex"),
  
  prior(normal(0, 5), class = "Intercept", resp = "sentiment"),
  prior(normal(0, 5), class = "b", coef = "income_lag1", resp = "sentiment"),
  prior(normal(0, 5), class = "b", coef = "unemployment_lag1", resp = "sentiment")
)

# ================================
# 📈 Fit Pooled Model
# ================================
fit_pooled <- brm(
  bf(volume_index ~ volume_lag1 + price_index + sentiment_norm + unemployment_lag1) +
    bf(price_index ~ income_lag1 + unemployment_lag1) +
    bf(sentiment ~ income_lag1 + unemployment_lag1) +
    set_rescor(FALSE),
  data = combined_q_lags,
  prior = priors,
  chains = 4,
  cores = 4,
  iter = 4000,
  seed = 42,
  control = list(adapt_delta = 0.99)
)

# Save pooled summary
summary_pooled <- broom.mixed::tidy(fit_pooled) %>% mutate(model = "Pooled")
pooled_summary_file <- paste0("summary_pooled_", today_str, ".csv")
write_csv(summary_pooled, pooled_summary_file)
drive_upload(pooled_summary_file, path = pooled_folder)

# Save pooled diagnostics
responses <- c("volumeindex", "priceindex", "sentiment")
for (resp in responses) {
  plot_file <- paste0("ppcheck_pooled_", resp, "_", today_str, ".png")
  png(plot_file, width = 800, height = 600)
  pp_check(fit_pooled, resp = resp)
  dev.off()
  drive_upload(plot_file, path = pooled_folder)
}
# ======================================================
# 5. Hierarchical (Multilevel) Bayesian Model
# ======================================================
fit_bayes_hier <- brm(
  bf(volume_index ~ volume_lag1 + price_index + sentiment_norm + unemployment_lag1 +
       (1 + volume_lag1 + price_index + sentiment_norm + unemployment_lag1 | geo), family = gaussian()) +
    bf(price_index ~ income_lag1 + unemployment_lag1 +
         (1 + income_lag1 + unemployment_lag1 | geo), family = gaussian()) +
    bf(sentiment ~ income_lag1 + unemployment_lag1 +
         (1 + income_lag1 + unemployment_lag1 | geo), family = gaussian()) +
    set_rescor(FALSE),
  data = combined_q_lags,
  prior = priors,
  chains = 4,
  cores = 4,
  iter = 4000,
  seed = 42,
  refresh = 100,
  threads = threading(2),
  control = list(adapt_delta = 0.99)
)

# --- View Hierarchical Model Summary ---
summary(fit_bayes_hier)

# Hierachical model
# Volume Index
png("diagnostics/ppcheck_hierarchical_volume.png", width = 800, height = 600)
pp_check(fit_bayes_hier, resp = "volumeindex")
dev.off()

# Price Index
png("diagnostics/ppcheck_hierarchical_price.png", width = 800, height = 600)
pp_check(fit_bayes_hier, resp = "priceindex")
dev.off()

# Sentiment
png("diagnostics/ppcheck_hierarchical_sentiment.png", width = 800, height = 600)
pp_check(fit_bayes_hier, resp = "sentiment")
dev.off()
end_time <- Sys.time()
