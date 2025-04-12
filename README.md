# EuroCast: Causal Modeling of Retail Sales for Clothing & Footwear

## Project Lead

**Ian Hargreaves**  
Bayesian Modeling • Marketing Analytics • Decision Science  
[GitHub Profile »](https://github.com/ianhargreaves80/EuroCast_clothing_footware)

---

## Overview

**EuroCast** is a forward-looking, causally grounded forecasting framework for clothing and footwear retail across European markets. By integrating macroeconomic indicators with Bayesian modeling and causal DAG theory, this project shifts analytics from descriptive hindsight to actionable foresight.

Built using:
- Bayesian multivariate modeling (`brms`)
- Causal inference using DAGs
- Macro-to-micro marketing strategy logic

This work aims to empower strategic planning across pricing, sentiment-based messaging, and demand stabilization — even in uncertain economic conditions.

---

## Objectives

- Quantify the causal impact of macro drivers (e.g., unemployment, income, sentiment) on retail demand.
- Translate macro trends into proactive marketing & pricing actions.
- Enable early-warning systems using explainable Bayesian models for campaign and pricing strategy.

---

## Data Sources

All macroeconomic indicators are sourced from [Eurostat](https://ec.europa.eu/eurostat).

| Indicator                  | Dataset Name         | Description                                 |
|---------------------------|----------------------|---------------------------------------------|
| HICP (Clothing & Footwear)| `prc_hicp_midx`      | Harmonized price index, 2015 = 100          |
| Retail Volume Index        | `sts_trtu_m`         | Seasonally adjusted retail volume           |
| Consumer Sentiment         | `ei_bsco_m`          | Composite confidence index                  |
| Unemployment Rate          | `une_rt_m`           | Age 25–74, seasonally adjusted              |
| Household Income Proxy     | `nasq_10_nf_tr`      | Gross income received (sector S14_S15)      |

**Important Note:**  
The Eurostat R API (`eurostat` package) is frequently outdated by several months, while manually downloaded CSV files reflect the most current data.  
Future model iterations will rely on locally downloaded CSVs only for up-to-date analysis.

---

## Methodology

### 1. Data Ingestion & Cleaning (`01_ingest_eurostat.R`)
- Aggregates monthly data to quarterly resolution.
- Applies country filters and imputes missing values via MICE.
- Produces `combined_q_trimmed.rds` for modeling.

### 2. Causal Exploration (`03_dag_exploration.html`)
- Binary comparisons of lagged effects build an initial DAG.
- Assesses candidate confounders and structural assumptions.

### 3. Bayesian Modeling (`04_bayesian_model.R`)
- Pooled and multilevel (`brms`) models:
  - Volume: ~ lag(volume) + sentiment + unemployment + price  
  - Sentiment: ~ lag(income) + lag(unemployment)  
  - Price: ~ lag(income) + lag(unemployment) + lag(volume)
- Posterior predictive checks and full diagnostics included.

---

## Key Business Insights

- Consumer sentiment is a real-time positive sales driver, and is itself predictable from lagged income and unemployment.
- Last quarter's unemployment has a negative relationship with sales volume, i.e., when unemployment rises one quarter' next querter's sales volume significantly drops.
- Real-time price has a small, context-sensitive effect on volume. Its impact is often confounded by income and prior volume, indicating the need for causal adjustment.
- Retail sales momentum (lagged volume) is a dominant predictor, emphasizing the value of sustaining demand after strong quarters.
- Macro signals can forecast competitor competitor price moves and consumer sentiment, enabling more informed pricing strategies.
  
![image](https://github.com/user-attachments/assets/50e101cc-8c35-43a4-8200-f38103248c4d)


---

## Output

- `combined_q_trimmed.rds`: Cleaned & imputed dataset  
- `fit_bayes.rds`: Pooled Bayesian model  
- `fit_bayes_hier.rds`: Hierarchical multilevel model  
- `/diagnostics`: Posterior predictive check plots  
- `executive_summary.Rmd`: Business-facing insights report  

---

## Strategic Applications

- Preemptive campaign planning triggered by predicted sentiment downturns  
- Localized price strategy tuned to country-level macro context  
- Scenario modeling for simulated shocks using causal `do()` logic  
- Elasticity-informed pricing moves based on market conditioning

---

## Next Steps

- **Integrate trade and supply-side shocks:**  
  Given recent global disruptions (e.g., U.S. tariffs, shifting trade blocs), the current model should be extended to capture:
  - Imported inflation risks via producer prices and trade volumes
  - Sudden supply chain disruptions influencing price and sentiment
  - Macro volatility propagation from external shocks to consumer behavior
  - Parts of the hierachical model could not converge at 1,000 iterations (running on local machine). Rerun this in GCE in a high compute engine (16-32 CPUs, 16GB)

- **Upgrade to most recent data:**  
  Replace API-sourced data with live Eurostat CSV downloads to reduce lag and enhance scenario accuracy.

- **Future Modeling Directions:**
  - Incorporate Bayesian networks for flexible multi-node inference  
  - Add business sentiment or trade indicators as upstream drivers  
  - Extend to real-time scenario dashboards with probabilistic forecasting

---

> This project demonstrates how causal modeling, macro data, and Bayesian forecasting can come together to help marketers and strategists anticipate, adapt, and act — rather than react — in volatile economic landscapes.
