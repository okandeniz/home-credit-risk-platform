import os
from pathlib import Path

import joblib
import pandas as pd
from dotenv import load_dotenv
from sklearn.metrics import (
    average_precision_score,
    brier_score_loss,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

PROJECT_ROOT = Path(__file__).resolve().parents[2]

def evaluate_model(y_true, probabilities, threshold):
    predictions = (probabilities >= threshold).astype(int)

    tn, fp, fn, tp = confusion_matrix(
        y_true, predictions, labels=[0, 1]
    ).ravel()

    metrics = {
        "ROC-AUC": roc_auc_score(y_true, probabilities),
        "Average Precision": average_precision_score(
            y_true, probabilities
        ),
        "Brier Score": brier_score_loss(
            y_true, probabilities
        ),
        "Precision": precision_score(
            y_true, predictions, zero_division=0
        ),
        "Recall": recall_score(
            y_true, predictions, zero_division=0
        ),
        "F1-Score": f1_score(
            y_true, predictions, zero_division=0
        ),
        "Review Rate": predictions.mean(),
    }

    confusion = {
        "TN": int(tn),
        "FP": int(fp),
        "FN": int(fn),
        "TP": int(tp),
    }

    return metrics, confusion

def main():
    load_dotenv(PROJECT_ROOT / ".env")

    model_path = (
        PROJECT_ROOT / "models"
        / "default_risk_lgbm_retrained.joblib"
    )

    artifact = joblib.load(model_path)

    pipeline = artifact["pipeline"]
    features = artifact["features"]
    threshold = artifact["threshold"]

    # Load original development IDs
    ids_path = (
        PROJECT_ROOT / "data" / "processed"
        / "default_risk_development_ids.csv"
    )

    development_ids = pd.read_csv(ids_path)["SK_ID_CURR"]

    assert development_ids.is_unique
    assert len(development_ids) == 246_008

    # Connect to SQL Server
    connection_url = URL.create(
        "mssql+pyodbc",
        host=os.environ["SQL_SERVER"],
        database=os.environ["SQL_DATABASE"],
        query={
            "driver": os.environ["SQL_DRIVER"],
            "Trusted_Connection": os.environ[
                "SQL_TRUSTED_CONNECTION"
            ],
            "TrustServerCertificate": os.environ[
                "SQL_TRUST_CERTIFICATE"
            ],
        },
    )

    engine = create_engine(connection_url)

    query = text("""
        SELECT *
        FROM ml.vw_default_risk_features
        WHERE DATASET_TYPE = 'TRAIN';
    """)

    try:
        with engine.connect() as connection:
            data = pd.read_sql_query(query, connection)
    finally:
        engine.dispose()

    # Restore the original holdout dataset
    assert data["SK_ID_CURR"].is_unique
    assert len(data) == 307_511
    assert data["SK_ID_CURR"].isin(development_ids).sum() == 246_008

    holdout = data.loc[
        ~data["SK_ID_CURR"].isin(development_ids)
    ].copy()

    X_holdout = holdout[features]
    y_holdout = holdout["TARGET"].astype(int)

    assert len(holdout) == 61_503
    assert y_holdout.sum() == 4_965

    # Generate predictions
    probabilities = pipeline.predict_proba(X_holdout)[:, 1]

    metrics, confusion = evaluate_model(
        y_holdout, probabilities, threshold
    )

    print("\nMODEL EVALUATION")
    print("-" * 35)
    print(f"Model: {artifact['model_name']}")
    print(f"Version: {artifact['model_version']}")
    print(f"Applications: {len(holdout):,}")
    print(f"Features: {len(features)}")
    print(f"Threshold: {threshold:.2f}")

    print("\nPerformance Metrics")
    for name, value in metrics.items():
        print(f"{name}: {value:.4f}")

    print("\nConfusion Matrix")
    for name, value in confusion.items():
        print(f"{name}: {value:,}")


if __name__ == "__main__":
    main()