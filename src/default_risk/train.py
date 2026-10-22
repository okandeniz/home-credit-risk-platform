import json
import os
from pathlib import Path

import joblib
import pandas as pd
from dotenv import load_dotenv
from lightgbm import LGBMClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import FunctionTransformer
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

from src.default_risk.preprocessing import prepare_lgbm_features

PROJECT_ROOT = Path(__file__).resolve().parents[2]

load_dotenv(PROJECT_ROOT / ".env")

def main():
    # Load model configuration
    config_path = (
        PROJECT_ROOT / "src" / "default_risk" / "model_config.json"
    )

    config = json.loads(
        config_path.read_text(encoding="utf-8")
    )

    features = config["features"]

     # Load the original development applicant IDs
    ids_path = (
        PROJECT_ROOT / "data" / "processed"
        / "default_risk_development_ids.csv"
    )

    development_ids = pd.read_csv(
        ids_path
    )["SK_ID_CURR"]

    assert development_ids.is_unique
    assert len(development_ids) == 246_008

    # Create SQL Server connection
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

    engine = create_engine(connection_url)

    # Load training applications from SQL Server
    query = text("""
        SELECT *
        FROM ml.vw_default_risk_features
        WHERE DATASET_TYPE = 'TRAIN';
    """)

    with engine.connect() as connection:
        data = pd.read_sql_query(query, connection)

    engine.dispose()

    assert data["SK_ID_CURR"].is_unique

    # Restore the original development dataset and row order
    data = (
        data.set_index("SK_ID_CURR")
        .loc[development_ids.to_numpy()]
    )

    X = data[features].copy()
    y = data["TARGET"].astype("int8")

    assert X.shape == (246_008, 35)
    assert y.notna().all()

    # Use the selected LightGBM parameters
    params = {
        "n_estimators": 250,
        "learning_rate": 0.05,
        "num_leaves": 31,
        "min_child_samples": 50,
        "colsample_bytree": 0.8,
        "verbosity": -1,
        "n_jobs": 4,
        "random_state": 42,
        "class_weight": None,
    }

    params.update(config["best_params"])

    pipeline = Pipeline([
        (
            "prepare",
            FunctionTransformer(
                prepare_lgbm_features,
                validate=False,
            ),
        ),
        ("model", LGBMClassifier(**params)),
    ])

    # Train the model
    pipeline.fit(X, y)

    # Save without overwriting the validated notebook model
    artifact = {
        "pipeline": pipeline,
        "features": features,
        "threshold": config["threshold"],
        "model_name": "LightGBM",
        "model_version": config["model_version"],
    }

    model_path = (
        PROJECT_ROOT / "models"
        / "default_risk_lgbm_retrained.joblib"
    )

    model_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(artifact, model_path, compress=3)

    print("Training completed successfully.")
    print(f"Training applications: {len(X):,}")
    print(f"Selected features: {len(features)}")
    print(f"Model saved: {model_path.name}")


if __name__ == "__main__":
    main()