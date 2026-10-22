from pathlib import Path
from typing import Annotated

from fastapi import FastAPI, HTTPException, Path as PathParam
from pydantic import BaseModel, Field

from src.default_risk.predictor import (
    ApplicantNotFoundError,
    predict_applicant,
)

from src.default_risk.sample_data import (
    get_random_test_applicant_id,
    get_random_test_form_sample
)

from src.default_risk.feature_engineering import (
    build_manual_model_features,
    get_manual_input_features,
)
from src.default_risk.predictor import (
    load_model_artifact,
    predict_from_features,
)




# Accessing the parent project directory from api/main.py:
PROJECT_ROOT = Path(__file__).resolve().parents[1]

MODEL_PATH = (
    PROJECT_ROOT
    / "models"
    / "default_risk_lgbm_retrained.joblib"
)

# Displaying our title, description, and version information in the Swagger interface:
app = FastAPI(
    title="Home Credit Risk API",
    description="Credit default risk analysis and prediction API.",
    version="0.1.0",
)

# Binding the health_check() function to an HTTP GET request using a decorator:
@app.get("/health", tags=["System"])
def health_check():
    return {
        "status":"runing",
        "model_artifact_exists": MODEL_PATH.is_file(),
    }

# Pydantic defines and validates the structure of the JSON data that an API returns.
class PredictionResponse(BaseModel):
    applicant_id: int
    dataset_type: str
    risk_probability: float = Field(ge=0, le=1)
    risk_flag: int = Field(ge=0, le=1)
    threshold: float = Field(ge=0, le=1)
    model_version: str

class ManualPredictionRequest(BaseModel):
    values: dict[str, float | str | None]


class ManualPredictionResponse(BaseModel):
    risk_probability: float = Field(ge=0, le=1)
    risk_flag: int = Field(ge=0, le=1)
    threshold: float = Field(ge=0, le=1)
    model_version: str

# Creates an HTTP GET endpoint
@app.get(
    "/predict/{applicant_id}",
    response_model=PredictionResponse,
    tags=["Predictions"],
)
def predict_default_risk(
    applicant_id: Annotated[int, PathParam(gt=0)]
):
    try:
        # SQL Server and LightGBM execute the prediction process
        return predict_applicant(applicant_id)

    except ApplicantNotFoundError as exc:
        raise HTTPException(
            status_code=404,
            detail="Applicant not found.",
        ) from exc


@app.get(
    "/samples/random-test",
    tags=["Samples"]
)
def random_test_sample():
    applicant_id = get_random_test_applicant_id()

    return {
        "applicant_id": applicant_id,
        "dataset_type": "TEST",
    }

@app.get(
    "/samples/random-test/form",
    tags=["Samples"],
)
def random_test_form_sample():
    return get_random_test_form_sample()


@app.post(
    "/predict/manual",
    response_model=ManualPredictionResponse,
    tags=["Predictions"],
)
def predict_manual(request: ManualPredictionRequest):
    features = load_model_artifact()["features"]

    expected_inputs = set(
        get_manual_input_features(features)
    )

    provided_inputs = set(request.values)

    missing = expected_inputs - provided_inputs
    unexpected = provided_inputs - expected_inputs

    if missing or unexpected:
        raise HTTPException(
            status_code=422,
            detail={
                "missing_fields": sorted(missing),
                "unexpected_fields": sorted(unexpected),
            },
        )

    try:
        model_features = build_manual_model_features(
            raw_values=request.values,
            model_features=features,
        )

        prediction = predict_from_features(
            model_features
        )

        return prediction

    except (ValueError, TypeError) as exc:
        raise HTTPException(
            status_code=422,
            detail=str(exc),
        ) from exc