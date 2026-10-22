
import joblib
import numpy as np
import pandas as pd
from sqlalchemy import text

from src.default_risk.predictor import (
    MODEL_PATH,
    PROJECT_ROOT,
    create_db_engine,
)


def predict_test_applications():
    artifact = joblib.load(MODEL_PATH)

    pipeline = artifact["pipeline"]
    features = artifact["features"]
    threshold = artifact["threshold"]

    query = text("""
        SELECT *
        FROM ml.vw_default_risk_features
        WHERE DATASET_TYPE = 'TEST';
    """)

    engine = create_db_engine()

    try:
        with engine.connect() as connection:
            test_data = pd.read_sql_query(
                query, connection
            )
    finally:
        engine.dispose()

    if test_data.empty:
        raise ValueError("No TEST applications found.")

    if not test_data["SK_ID_CURR"].is_unique:
        raise ValueError("Duplicate applicant IDs found.")

    missing_cols = [
        col for col in features
        if col not in test_data.columns
    ]

    if missing_cols:
        raise ValueError(
            f"Missing model features: {missing_cols}"
        )

    X_test = test_data[features].copy()

    probabilities = pipeline.predict_proba(
        X_test
    )[:, 1]

    if not np.isfinite(probabilities).all():
        raise ValueError("Invalid probabilities detected.")

    predictions = pd.DataFrame({
        "SK_ID_CURR": test_data["SK_ID_CURR"],
        "risk_probability": probabilities,
        "risk_flag": (
            probabilities >= threshold
        ).astype("int8"),
        "threshold": threshold,
        "model_version": artifact["model_version"],
    })

    return predictions


def main():
    predictions = predict_test_applications()

    output_path = (
        PROJECT_ROOT / "data" / "predictions"
        / "default_risk_test_predictions.csv"
    )

    output_path.parent.mkdir(
        parents=True, exist_ok=True
    )

    predictions.to_csv(
        output_path, index=False
    )

    print("Batch prediction completed.")
    print(f"Applications: {len(predictions):,}")

    print(
        "Flagged for review:",
        f"{predictions['risk_flag'].sum():,}"
    )

    print(
        "Average risk probability:",
        f"{predictions['risk_probability'].mean():.2%}"
    )

    print(f"Saved to: {output_path}")

    print("\nPrediction Sample:")
    print(predictions.head(10).to_string(index=False))


if __name__ == "__main__":
    main()
