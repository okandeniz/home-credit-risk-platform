# Home Credit Risk Platform

**End-to-end credit risk analytics, machine learning, and reporting** with **SQL Server, Python, LightGBM, FastAPI, Streamlit, and Power BI**. The project uses the [Home Credit Default Risk dataset](https://www.kaggle.com/competitions/home-credit-default-risk/data) to analyze applicant profiles and estimate the probability of payment difficulty (`TARGET = 1`).

> **Project status:** The SQL analytics pipeline, LightGBM default-risk model, prediction scripts, FastAPI endpoints, two-tab Streamlit interface, and Power BI reporting have been developed and tested locally. This repository is a **portfolio/research prototype**, not a deployed public application or a production loan approval system.

## Project highlights

- **SQL Server analytics:** raw ingestion, curated core tables, integrity checks, customer-level summaries, and model/reporting views.
- **Exploratory and business analysis:** applicant risk, historical repayments, credit card behavior, and data quality.
- **Default risk classification:** one LightGBM model using **35 selected features**; preprocessing and feature selection documented in the notebook.
- **Reproducible inference:** training, holdout evaluation, prediction for one applicant, TEST batch scoring, and SQL prediction storage.
- **FastAPI:** prediction by applicant ID and prediction from manually provided feature values; validation and sample-data endpoints.
- **Streamlit:** two tabs—**Applicant ID Prediction** and **Manual Prediction**, including **Random Fill from TEST**.
- **Power BI:** business intelligence and model-performance pages, with interactive filtering and applicant-level risk exploration.

## Results

**Model:** LightGBM binary classifier · **Version:** `1.0.0` · **Features:** 35 · **Manual-review threshold:** `0.12`

### Untouched holdout evaluation

| Metric | Result |
|---|---:|
| Applications | 61,503 |
| ROC-AUC | 0.7350 |
| Average Precision (PR-AUC) | 0.2208 |
| Brier score | 0.0690 |
| Precision | 20.35% |
| Recall | 46.69% |
| F1-score | 0.2834 |
| Review rate | 18.52% |

Confusion matrix at the `0.12` threshold: **TN 47,463 · FP 9,075 · FN 2,647 · TP 2,318**. The threshold was selected during model development, before final holdout evaluation. An application above this threshold is **flagged for review**, not automatically declined.

### Unlabeled TEST scoring

| Metric | Result |
|---|---:|
| Scored applications | 48,744 |
| Flagged for review | 8,972 |
| Review rate | 18.41% |
| Mean predicted probability | 7.91% |

The TEST set has no known target labels. These figures describe **predictions, not observed default outcomes or TEST accuracy**.

## Power BI report

Download the **[Power BI Desktop dashboard (`.pbix`)](powerbi/Home_Credit_Risk_Dashboard.pbix)** or browse the [`powerbi/` folder](powerbi/). Open the file with Power BI Desktop. **There is no publicly hosted live dashboard.**

> The download link works after the final file is saved to the repository as `powerbi/Home_Credit_Risk_Dashboard.pbix`.

The report includes seven analytical pages:

| Page | What it shows |
|---|---|
| Executive Overview | Portfolio size, labeled applicant outcomes, and broad risk drivers |
| Applicant Risk | Credit burden, age, income, and applicant-level risk patterns |
| Payment Behavior | Historical installment and POS delinquency analysis |
| Credit Card Risk | Credit utilization and delinquency trends |
| ML Overview | LightGBM configuration, holdout metrics, and confusion matrix |
| Default Risk | TEST scoring, review flags, risk bands, age profiles, and applicant details |
| Data Quality | Data validation statuses and quality issues by source |

**Report palette:** `#689EB8` (primary), `#F3F4F6` (background), `#A79B94` (neutral), `#FF5A60` (risk highlight). The canvas is 1280 × 720 (16:9).

**Important:** The `.pbix` report may contain imported data and local source metadata. Review its contents and the Kaggle competition's data-use rules before publishing it in a public repository. The raw source datasets are **not** included in this repository. Local SQL Server access may be required to refresh the report.

## Architecture

```text
Kaggle Home Credit CSVs
        |
        v
SQL Server: raw -> core -> bi / ml views
        |                    |
        |                    +--> Power BI report
        v
Python notebook -> train.py -> LightGBM joblib artifact
                                   |
SQL model features ----------------+--> FastAPI prediction API
                                            |
                                            v
                                      Streamlit UI
                              (Applicant ID / Manual Input)
```

**Manual feature entry:** 31 model features are supplied directly, along with 4 additional inputs used to calculate the 4 Python-derived features automatically (`CREDIT_GOODS_RATIO`, `BUREAU_ACTIVE_SHARE`, `PREVIOUS_REFUSAL_RATE`, and `BUREAU_DEBT_INCOME_RATIO`). The other inputs can include SQL-derived aggregates; users are responsible for entering consistent values. Random Fill retrieves the inputs from an existing TEST application.

## Technology stack

| Layer | Technologies |
|---|---|
| Data warehouse and reporting views | Microsoft SQL Server, T-SQL |
| Data processing | Python, pandas, SQLAlchemy, pyodbc |
| Machine learning | scikit-learn, LightGBM, XGBoost, Optuna |
| Development and evaluation | Jupyter Notebook, `uv`, ROC-AUC, average precision, calibration, confusion matrix |
| Prediction API | FastAPI, Pydantic, Uvicorn |
| User interface | Streamlit, Requests |
| Dashboards | Microsoft Power BI, DAX |

## Repository structure

```text
api/                       # FastAPI application and endpoints
streamlit_app/             # Streamlit two-tab application
src/default_risk/          # Training, preprocessing, feature engineering, evaluation, inference
notebooks/                 # Model analysis and feature selection
sql/                       # Database setup, data quality, core, BI and ML views
scripts/                   # Data inventory, ingestion, validation and utility scripts
reports/                   # Data quality and profiling reports
powerbi/                   # Power BI Desktop report (.pbix)
data/                      # Local data; development split IDs tracked
models/                    # Local model artifacts (ignored by Git)
tests/                     # Test code when available
.env.example               # Sample local SQL Server configuration
requirements.txt           # Python dependencies
```

## Run locally

### 1. Prerequisites

- Python and [`uv`](https://docs.astral.sh/uv/)
- Microsoft SQL Server and an installed **ODBC Driver for SQL Server** (the supplied `.env.example` uses Driver 17)
- Home Credit competition data obtained separately from [Kaggle](https://www.kaggle.com/competitions/home-credit-default-risk/data)
- The project SQL objects created and source data loaded; see the numbered scripts under `sql/` and `scripts/`

The SQL Server database is named `HomeCreditRisk` in the example configuration. Your instance name may differ.

### 2. Install Python dependencies

```powershell
uv venv
uv pip install -r requirements.txt
Copy-Item .env.example .env
```

Edit `.env` with your local SQL Server settings. **Never commit `.env` or credentials.** The `requirements.txt` file should include the FastAPI, Uvicorn, Streamlit and Requests packages used by the app.

### 3. Train and evaluate

Ensure `ml.vw_default_risk_features` exists and that `data/processed/default_risk_development_ids.csv` is present. Then run:

```powershell
uv run python -m src.default_risk.train
uv run python -m src.default_risk.evaluation
```

Training saves the expected local model artifact at `models/default_risk_lgbm_retrained.joblib`.

### 4. Generate and store predictions

```powershell
uv run python -m src.default_risk.predictor --applicant-id 316058
uv run python -m src.default_risk.batch_predict
uv run python -m src.default_risk.save_predictions
```

The SQL destination table and reporting view must be created using the relevant scripts under `sql/07_ml_features/` before storing and reporting batch predictions.

### 5. Start FastAPI

```powershell
uv run python -m uvicorn api.main:app --reload --port 8000
```

Open **http://127.0.0.1:8000/docs** for interactive API documentation.

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/health` | Basic server/model-file status |
| `GET` | `/predict/{applicant_id}` | Retrieve SQL features and score an existing application |
| `GET` | `/samples/random-test` | Select a random TEST application ID |
| `GET` | `/samples/random-test/form` | Return manually editable input values for a random TEST application |
| `POST` | `/predict/manual` | Score a supplied set of manual inputs |

### 6. Start Streamlit

In a **second terminal** (keep the API running):

```powershell
uv run python -m streamlit run streamlit_app/app.py
```

Open **http://localhost:8501** and choose one of the two prediction tabs:

1. **Applicant ID Prediction:** enter an existing application ID; features are read from SQL Server.
2. **Manual Prediction:** enter/edit 35 inputs or choose **Random Fill from TEST**; the API calculates 4 additional features before scoring.

Both tabs use the **same LightGBM inference pipeline**. Random-fill parity was tested against the applicant-ID endpoint without changing the supplied values.

> FastAPI and Streamlit are **local applications**. The links above only work when both services are running on your computer; no public hosting is provided.

## Key SQL objects

- `bi.vw_applicant_overview`: customer-level business analytics.
- `ml.vw_default_risk_features`: modeling view with the selected 35 feature values and record metadata.
- `ml.default_risk_predictions`: stored TEST prediction results.
- `bi.vw_default_risk_predictions`: reporting view consumed by Power BI.

## Limitations and responsible use

- Prior bureau/payment information has not been fully verified as **available at each application's decision time**; potential temporal leakage remains.
- Fairness, generalization outside the Kaggle data, and model drift have not been established.
- The 12% threshold is a **manual-review heuristic**, not an approved financial decision policy or a proven cost-optimal threshold.
- Missing manual inputs and inconsistent user-entered aggregates can affect prediction reliability; this app is **not** intended for real lending decisions.
- A public `.pbix` may include embedded data; dataset redistribution permissions and embedded source/credential metadata must be checked before sharing.

## Data source

Home Credit Group, **[Home Credit Default Risk](https://www.kaggle.com/competitions/home-credit-default-risk/data)**, Kaggle competition. Download the original files and review the associated competition rules before use or redistribution.
