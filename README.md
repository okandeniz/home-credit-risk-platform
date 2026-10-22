# Home Credit Risk Platform

An end-to-end **default risk analytics and machine learning** portfolio project using the Home Credit Default Risk dataset. It combines Microsoft SQL Server, Python, LightGBM, and Power BI, with FastAPI and Streamlit integration planned.

> **Project status:** The Default Risk Prediction model and SQL-based prediction workflow are implemented. FastAPI, Streamlit, and final Power BI reporting are in progress. This is an analytical prototype, **not** a production credit approval or rejection system.

## Project objectives

- Build and validate relational tables and analytics views in SQL Server.
- Explore applicant, bureau, and historical payment data.
- Predict the probability of payment difficulty (`TARGET = 1`) with LightGBM.
- Evaluate the model using an untouched holdout set.
- Serve single-applicant and batch predictions from SQL Server.
- Develop API and interactive reporting interfaces.

## Model and results

**Model:** LightGBM binary classifier, 35 selected features, version `1.0.0`.

| Metric | Holdout result |
|---|---:|
| Applications | 61,503 |
| ROC-AUC | 0.7350 |
| Average Precision (PR-AUC) | 0.2208 |
| Brier score | 0.0690 |
| Precision at threshold 0.12 | 0.2035 |
| Recall at threshold 0.12 | 0.4669 |
| F1-score at threshold 0.12 | 0.2834 |
| Review rate at threshold 0.12 | 18.52% |

The 0.12 threshold flags applications for **manual review**, not automatic decisions. The holdout set was not used for threshold selection.

**Unlabeled TEST predictions:** 48,744 applications; 8,972 flagged for review (18.41%); average predicted probability 7.91%. These have no known labels, so accuracy cannot be measured on them.

## Technology stack

- **Database:** Microsoft SQL Server, SQL, SQLAlchemy, pyodbc
- **Data and ML:** Python, pandas, scikit-learn, LightGBM, XGBoost, Optuna
- **Evaluation and analysis:** Jupyter Notebook, ROC-AUC, Average Precision, calibration and threshold analysis
- **BI:** Power BI (final report in progress)
- **Application (planned):** FastAPI, Streamlit

## Project structure

```text
api/                       # API application (planned / in progress)
data/                      # Local data and split manifest
models/                    # Locally generated joblib models
notebooks/                 # EDA, feature engineering, and ML experiments
powerbi/                   # Power BI reports
reports/                   # Reports and outputs
scripts/                   # Data loading / operational scripts
sql/                       # Database objects, validation, reporting views
src/default_risk/          # Preprocessing, training, evaluation, prediction
streamlit_app/             # Streamlit application (planned / in progress)
tests/                     # Tests
```

## Run locally

**Prerequisites:** Python, `uv`, Microsoft SQL Server, an ODBC Driver for SQL Server, and the Home Credit dataset loaded into the project database. The SQL views must already be created from the repository's SQL scripts.

1. Create local configuration from `.env.example` and adjust settings for your SQL Server instance. Never commit `.env`.
2. Create a virtual environment and install project dependencies:

   ```powershell
   uv venv
   uv pip install -r requirements.txt
   ```

3. Ensure `ml.vw_default_risk_features` is available in SQL Server and `data/processed/default_risk_development_ids.csv` is present (it records the fixed development split).
4. Run model training and holdout evaluation:

   ```powershell
   uv run python -m src.default_risk.train
   uv run python -m src.default_risk.evaluation
   ```

5. Predict a specific applicant or run batch inference:

   ```powershell
   uv run python -m src.default_risk.predictor --applicant-id 316058
   uv run python -m src.default_risk.batch_predict
   ```

6. After creating the destination table with the SQL script, save batch results to SQL Server:

   ```powershell
   uv run python -m src.default_risk.save_predictions
   ```

**Model artifacts:** `.joblib` files are generated locally and ignored by Git. The evaluation and prediction scripts expect `models/default_risk_lgbm_retrained.joblib`, which the training command creates. Only load joblib artifacts from trusted sources.

## Key SQL objects

- `ml.vw_default_risk_features`: the 35-feature modeling input view (plus identifiers and target).
- `ml.default_risk_predictions`: batch prediction storage table.
- `bi.vw_default_risk_predictions`: reporting view for Power BI.

## Limitations and responsible use

- Historical bureau and payment features require **as-of-application availability** checks before operational use; future-information leakage remains a risk.
- Fairness, drift, and external validation are not completed.
- The model is for portfolio research and manual-review prioritization, not automated credit decisions.
- Kaggle TEST applications are unlabeled; their outcomes and true performance are unknown.

## Next steps

1. Build and test FastAPI prediction endpoints.
2. Develop the Streamlit user interface.
3. Complete and publish the Power BI report (`.pbix`).
4. Add final integration checks and project documentation.
