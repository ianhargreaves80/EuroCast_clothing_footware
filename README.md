#  EuroCast: Causal Modeling of Retail Sales for Clothing & Footwear

## Overview

This project develops a causal forecasting framework for clothing and footwear retail sales across European markets using macroeconomic indicators from **Eurostat**. The aim is to move beyond simple associations and deliver **actionable causal insights** that support proactive pricing strategies and campaign planning in volatile consumer environments.

It integrates:
- **Bayesian multivariate modeling (via `brms`)**
- **Causal inference using DAG theory**
- **Macro-to-micro marketing strategy translation**

---

## Objectives

- Quantify the **causal impact** of macroeconomic variables (e.g., unemployment, income, sentiment) on retail sales.
- Understand **price and sentiment dynamics** to enable **proactive** planning, not reactive firefighting.
- Create early-warning and campaign optimization tools using **explainable Bayesian models**.

---

## Data Sources

All data is sourced directly from [Eurostat](https://ec.europa.eu/eurostat). Key indicators:

| Indicator                  | Dataset Name         | Description                                 |
|----------------------------|----------------------|---------------------------------------------|
| HICP (Clothing & Footwear) | `prc_hicp_midx`      | Price index, 2015=100                       |
| Retail Volume Index        | `sts_trtu_m`         | Clothing + general retail volume (adjusted) |
| Consumer Sentiment         | `ei_bsco_m`          | Composite consumer confidence index         |
| Unemployment Rate          | `une_rt_m`           | Ages 25–74, seasonally adjusted             |
| Household Income Proxy     | `nasq_10_nf_tr`      | Gross domestic income (received, S14_S15)   |

---

## Methodology

### 1. Data Ingestion & Cleaning (`01_ingest_eurostat.R`)
- Pulls and aggregates macroeconomic indicators by country and quarter.
- Applies filters for reporting quality and imputes missing values via MICE.
- Outputs a cleaned dataset: `combined_q_trimmed.rds`

### 2. Causal Exploration & DAG Construction (`03_dag_exploration.html`)
- Binary comparisons of conditional probabilities help structure a DAG.
- Identifies key confounders and candidates for adjustment in modeling.

### 3. Bayesian Modeling (`04_bayesian_model.R`)
- Uses **`brms`** to estimate a pooled and hierarchical Bayesian model with:
  - Retail volume predicted by lagged volume, sentiment, unemployment, and price.
  - Sentiment modeled by income and unemployment.
  - Prices explained by income, unemployment, and lagged sales volume.

- Output includes full posterior summaries and posterior predictive checks.

---

## Key Business Insights

- **Sentiment is a direct driver of retail sales**, and is itself predictable from macroeconomic variables. This enables **pre-campaign planning** when public mood is expected to shift.
- **Price has a small but non-trivial effect** on volume. Its impact is often confounded by other drivers like income or prior demand.
- **Sales volume is strongly autoregressive**, reinforcing the importance of loyalty and retention after successful quarters.
- **Predicting competitors' pricing** becomes feasible through lagged indicators.

---

## Output

- `combined_q_trimmed.rds`: Cleaned and imputed macroeconomic dataset
- `fit_bayes.rds`: Pooled model object
- `fit_bayes_hier.rds`: Hierarchical model object
- `/diagnostics`: Model diagnostics and predictive check plots
- `executive_summary.Rmd`: Manager-facing summary of findings and implications

---

## Strategic Applications

- **Campaign timing** based on predicted sentiment drops.
- **Localized pricing recommendations** grounded in causal estimates.
- **Scenario planning** using simulated interventions via `do()` calculus.
- **Competitive price tracking** via inferred macro-signal reactions.

---

## Next Steps

- Deploy interactive dashboards for country-specific scenario exploration.
- Integrate granular retail data (if available) for micro-level validation.
- Test uplift modeling frameworks that integrate forecasted sentiment trajectories.

---

## Project Lead

**Ian Hargreaves**  
Bayesian Modeling • Marketing Analytics • Decision Science   [GitHub Profile]([https://github.com/YOUR_USERNAME](https://github.com/ianhargreaves80/EuroCast_clothing_footware/new/main?filename=README.md))

---
      
> This repository demonstrates the potential of combining causal inference, macroeconomic data, and Bayesian statistics to inform smarter pricing, better marketing, and proactive retail planning.
