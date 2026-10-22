
import argparse
import os
from pathlib import Path

import joblib
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from functools import lru_cache


PROJECT_ROOT = Path(__file__).resolve().parents[2]

MODEL_PATH = (
    PROJECT_ROOT / "models"
    / "default_risk_lgbm_retrained.joblib"
)

class ApplicantNotFoundError(Exception):
    pass

def create_db_engine():
    load_dotenv(PROJECT_ROOT / ".env")

    connection_url = URL.create(
        "mssql+pyodbc",
        host=os.environ["SQL_SERVER"],
        database=os.environ["SQL_DATABASE"],
        query={
            "driver": os.environ["SQL_DRIVER"],
            "Trusted_Connection": os.environ[
                "SQL_TRUSTED_CONNECTION"
            ],
            "TrustServerCertificate": os.getenv(
                "SQL_TRUST_CERTIFICATE",
                os.getenv("SQL_TRUST_SERVER_CERTIFICATE", "yes"),
            ),
        },
    )

    return create_engine(connection_url)

# Thanks to @lru_cache(maxsize=1), the trained model will be loaded upon the first call within the same Python process,
# and the version already in memory will be used for subsequent calls.

@lru_cache(maxsize=1)
def load_model_artifact():
    return joblib.load(MODEL_PATH)

def predict_from_features(feature_values: dict):
    artifact = load_model_artifact()

    features = artifact["features"]
    threshold = artifact["threshold"]
    pipeline = artifact["pipeline"]

    # Validate required features
    missing_features = [
        feature
        for feature in features
        if feature not in feature_values
    ]

    if missing_features:
        raise ValueError(
            f"Missing model features: {missing_features}"
        )

    # Preserve the trained feature order
    X = pd.DataFrame(
        [{feature: feature_values[feature] for feature in features}],
        columns=features,
    )

    probability = float(
        pipeline.predict_proba(X)[0, 1]
    )

    return {
        "risk_probability": probability,
        "risk_flag": int(probability >= threshold),
        "threshold": threshold,
        "model_version": artifact["model_version"],
    }

def predict_applicant(applicant_id):
    artifact = load_model_artifact()

    pipeline = artifact["pipeline"]
    features = artifact["features"]
    threshold = artifact["threshold"]

    query = text("""
        SELECT *
        FROM ml.vw_default_risk_features
        WHERE SK_ID_CURR = :applicant_id;
    """)

    engine = create_db_engine()

    try:
        with engine.connect() as connection:
            applicant = pd.read_sql_query(
                query,
                connection,
                params={"applicant_id": applicant_id},
            )
    finally:
        engine.dispose()

    if applicant.empty:
        raise ApplicantNotFoundError(
            f"Applicant {applicant_id} was not found."
        )

    if len(applicant) != 1:
        raise ValueError(
            f"Expected one record, found {len(applicant)}."
        )

    # Validate the required model features
    missing_columns = [
        col for col in features
        if col not in applicant.columns
    ]

    if missing_columns:
        raise ValueError(
            f"Missing features: {missing_columns}"
        )

    X = applicant[features].copy()

    prediction = predict_from_features(
        applicant.iloc[0].to_dict()
    )

    return {
        "applicant_id": int(applicant_id),
        "dataset_type": str(applicant["DATASET_TYPE"].iloc[0]),
        **prediction,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Predict applicant payment difficulty."
    )

    parser.add_argument(
        "--applicant-id",
        type=int,
        required=True,
        help="Applicant SK_ID_CURR",
    )

    args = parser.parse_args()

    result = predict_applicant(args.applicant_id)

    print("\nDEFAULT RISK PREDICTION")
    print("-" * 40)

    print(f"Applicant ID: {result['applicant_id']}")
    print(f"Dataset: {result['dataset_type']}")

    print(
        f"Risk Probability: "
        f"{result['risk_probability']:.2%}"
    )

    print(f"Threshold: {result['threshold']:.2f}")
    print(f"Risk Flag: {result['risk_flag']}")

    status = (
        "Review Recommended"
        if result["risk_flag"] == 1
        else "Below Review Threshold"
    )

    print(f"Status: {status}")
    print(f"Model Version: {result['model_version']}")


if __name__ == "__main__":
    main()
