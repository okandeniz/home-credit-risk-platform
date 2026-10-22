
import numpy as np
import pandas as pd
from sqlalchemy import text

from src.default_risk.predictor import (
    PROJECT_ROOT,
    create_db_engine,
)


def main():
    csv_path = (
        PROJECT_ROOT
        / "data"
        / "predictions"
        / "default_risk_test_predictions.csv"
    )

    predictions = pd.read_csv(csv_path)

    predictions = predictions.rename(columns={
        "risk_probability": "RISK_PROBABILITY",
        "risk_flag": "RISK_FLAG",
        "threshold": "THRESHOLD",
        "model_version": "MODEL_VERSION",
    })

    predictions["DATASET_TYPE"] = "TEST"

    columns = [
        "SK_ID_CURR",
        "DATASET_TYPE",
        "RISK_PROBABILITY",
        "RISK_FLAG",
        "THRESHOLD",
        "MODEL_VERSION",
    ]

    predictions = predictions[columns]

    # Validate before writing to SQL Server
    if predictions.isna().any().any():
        raise ValueError("Missing prediction values found.")

    if not predictions["SK_ID_CURR"].is_unique:
        raise ValueError("Duplicate applicant IDs found.")

    if predictions["MODEL_VERSION"].nunique() != 1:
        raise ValueError("Expected one model version.")

    probabilities = predictions["RISK_PROBABILITY"]

    if not np.isfinite(probabilities).all():
        raise ValueError("Invalid probability values.")

    if not probabilities.between(0, 1).all():
        raise ValueError("Probabilities outside [0, 1].")

    expected_flags = (
        probabilities >= predictions["THRESHOLD"]
    ).astype(int)

    if not np.array_equal(
        expected_flags.to_numpy(),
        predictions["RISK_FLAG"].to_numpy(),
    ):
        raise ValueError("Risk flags do not match threshold.")

    version = predictions["MODEL_VERSION"].iloc[0]

    engine = create_db_engine()

    try:
        # Delete and insert within one transaction
        with engine.begin() as connection:
            connection.execute(
                text("""
                    DELETE FROM ml.default_risk_predictions
                    WHERE DATASET_TYPE = 'TEST'
                      AND MODEL_VERSION = :version;
                """),
                {"version": version},
            )

            predictions.to_sql(
                name="default_risk_predictions",
                con=connection,
                schema="ml",
                if_exists="append",
                index=False,
                chunksize=200,
            )

            result = connection.execute(
                text("""
                    SELECT
                        COUNT(*) AS total_applications,
                        SUM(CAST(RISK_FLAG AS INT))
                            AS flagged_applications,
                        AVG(RISK_PROBABILITY)
                            AS average_probability
                    FROM ml.default_risk_predictions
                    WHERE DATASET_TYPE = 'TEST'
                      AND MODEL_VERSION = :version;
                """),
                {"version": version},
            ).one()

        print("Predictions saved successfully.")
        print(f"Applications: {result.total_applications:,}")
        print(f"Flagged for review: {result.flagged_applications:,}")
        print(
            "Average risk probability:",
            f"{result.average_probability:.2%}",
        )

    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
