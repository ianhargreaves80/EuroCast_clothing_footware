# EuroCast: Causal Modeling of Retail Sales for Clothing & Footwear

## Project Lead

**Ian Hargreaves**  
Bayesian Modeling • Marketing Analytics • Decision Science  
[GitHub Profile »](https://github.com/ianhargreaves80/EuroCast_clothing_footware)

---

## Overview

**EuroCast** is a forward-looking, causally grounded forecasting framework for clothing and footwear retail across European markets. By integrating macroeconomic indicators with Bayesian modeling and DAG-based causal inference, this project shifts analytics from descriptive hindsight to actionable foresight.

Built with:
- Bayesian multivariate modeling (`brms`)
- Causal inference using DAGs
- Macro-to-micro marketing strategy translation

The goal is to support strategic planning in pricing, sentiment-driven messaging, and demand stabilization—even under economic uncertainty.

---

## Objectives

- Quantify the **causal impact** of macro drivers (e.g., unemployment, income, sentiment) on retail demand.
- Translate macro trends into **proactive marketing and pricing** actions.
- Enable **early-warning systems** through explainable Bayesian models.

---

## Data Sources

All macroeconomic indicators are sourced from [Eurostat](https://ec.europa.eu/eurostat).

| Indicator                   | Dataset Name        | Description                                 |
|----------------------------|---------------------|---------------------------------------------|
| HICP (Clothing & Footwear) | `prc_hicp_midx`     | Harmonized price index, 2015 = 100          |
| Retail Volume Index        | `sts_trtu_m`        | Seasonally adjusted retail volume           |
| Consumer Sentiment         | `ei_bsco_m`         | Composite confidence index                  |
| Unemployment Rate          | `une_rt_m`          | Age 25–74, seasonally adjusted              |
| Household Income Proxy     | `nasq_10_nf_tr`     | Gross income received (sector S14_S15)      |

**Note:**  
The `eurostat` R package often lags by several months. CSV downloads from the Eurostat portal provide up-to-date figures. Future iterations of this model will rely on **manually downloaded CSVs** to improve recency and scenario accuracy.

---

## Methodology

### 1. Data Ingestion & Cleaning (`01_ingest_eurostat.R`)
- Aggregates monthly data into quarterly format.
- Filters non-reporting countries and imputes missing values via MICE.
- Produces `combined_q_trimmed.rds`.

### 2. Causal Exploration (`03_dag_exploration.html`)
- Conditional probability comparisons identify key confounders.
- Outputs a DAG structure to guide model design.

### 3. Bayesian Modeling (`04_bayesian_model.R`)
- Pooled and hierarchical models built in `brms`:
  - **Volume** ~ lag(volume) + sentiment + unemployment + price  
  - **Sentiment** ~ lag(income) + lag(unemployment)  
  - **Price** ~ lag(income) + lag(unemployment) + lag(volume)
- Posterior predictive checks and model diagnostics included.

---

## Output

- `combined_q_trimmed.rds`: Cleaned and imputed dataset  
- `fit_bayes.rds`: Pooled Bayesian model  
- `fit_bayes_hier.rds`: Hierarchical multilevel model  
- `/diagnostics`: Posterior predictive check plots  
- `executive_summary.Rmd`: Business-facing insights summary  

---

## Key Business Insights

- **Sentiment is a real-time driver** of sales, and is itself predictable from lagged macro factors like income and unemployment.
- **Unemployment rises one quarter precede volume drops the next**, offering a proactive window for demand-side intervention.
- **Price shows modest, context-sensitive influence** on volume. Its effects are often confounded, highlighting the value of causal adjustment.
- **Lagged volume is the strongest volume predictor**, emphasizing the role of momentum and retention in sustaining demand.
- **Macro indicators can anticipate pricing moves and sentiment trends**, aiding competitor tracking and preemptive strategy development.

![image](https://github.com/user-attachments/assets/50e101cc-8c35-43a4-8200-f38103248c4d)

---

## Strategic Applications

- Campaign timing aligned with **predicted sentiment downturns**  
- Country-specific **price sensitivity analysis**  
- Shock scenario modeling via **causal `do()` interventions**  
- **Elasticity-informed pricing** driven by real economic signals

---

## Next Steps

### 1. Integrate Trade & Supply-Side Shocks  
Recent global disruptions (e.g. U.S. tariffs, shifting trade blocs) warrant model extension to capture:
- Imported inflation via producer prices and trade volumes  
- Supply chain disruptions impacting sentiment and prices  
- External shock transmission into retail demand patterns  

### 2. Upgrade to Real-Time Data  
- Replace R API inputs with live CSV downloads from Eurostat.  
- Explore proxies or imputation for countries lacking full reporting (e.g., Switzerland's missing sentiment).

### 3. Resolve Hierarchical Modeling Limits  
- Some convergence issues at 1,000 iterations on local hardware.  
- Re-run hierarchical models on Google Cloud Compute (16–32 CPUs, 16GB RAM) for stability.

### 4. Future Modeling Directions  
- Explore **Bayesian networks** for flexible multi-node inference  
- Introduce **non-linearity** or splines in future models  
- Add upstream **business sentiment** and trade flow indicators  
- Develop **interactive dashboards** for real-time simulation and strategic planning  

---

> This project illustrates how causal modeling, macroeconomic context, and Bayesian methods can converge to help marketers and decision-makers **anticipate, adapt, and act** in volatile environments—rather than simply react.
