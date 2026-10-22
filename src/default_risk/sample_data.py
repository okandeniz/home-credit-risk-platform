import pandas as pd
from sqlalchemy import text

from src.default_risk.feature_engineering import (
    get_manual_input_features,
)
from src.default_risk.predictor import (
    create_db_engine,
    load_model_artifact,
)

def get_random_test_applicant_id():
    query = text("""
        SELECT TOP (1)
            SK_ID_CURR
        FROM ml.default_risk_predictions
        WHERE DATASET_TYPE = 'TEST'
          AND MODEL_VERSION = '1.0.0'
        ORDER BY NEWID();
    """)

    engine = create_db_engine()

    try:
        with engine.connect() as connection:
            applicant_id = connection.execute(
                query
            ).scalar_one_or_none()
    finally:
        engine.dispose()

    if applicant_id is None:
        raise ValueError("No TEST applications found.")

    return int(applicant_id)

def get_random_test_form_sample():
    applicant_id = get_random_test_applicant_id()

    model_features = load_model_artifact()["features"]

    manual_inputs = get_manual_input_features(
        model_features
    )

    query = text("""
        SELECT
            f.*,
            a.BUREAU_CREDIT_COUNT,
            a.PREVIOUS_REFUSED_COUNT,
            a.PREVIOUS_APPLICATION_COUNT,
            a.TOTAL_BUREAU_DEBT
        FROM ml.vw_default_risk_features AS f
        INNER JOIN bi.vw_applicant_overview AS a
            ON f.SK_ID_CURR = a.SK_ID_CURR
           AND f.DATASET_TYPE = a.DATASET_TYPE
        WHERE f.SK_ID_CURR = :applicant_id
          AND f.DATASET_TYPE = 'TEST';
    """)

    engine = create_db_engine()

    try:
        with engine.connect() as connection:
            row = connection.execute(
                query,
                {"applicant_id": applicant_id},
            ).mappings().one_or_none()
    finally:
        engine.dispose()

    if row is None:
        raise ValueError("TEST applicant not found.")

    values = {}

    for feature in manual_inputs:
        if feature not in row:
            raise ValueError(
                f"Missing SQL feature: {feature}"
            )

        value = row[feature]

        if pd.isna(value):
            values[feature] = None

        elif feature == "NAME_CONTRACT_TYPE":
            values[feature] = str(value)

        else:
            values[feature] = float(value)

    return {
        "applicant_id": applicant_id,
        "dataset_type": "TEST",
        "values": values,
    }
