
import math

PYTHON_DERIVED_FEATURES = {
    "CREDIT_GOODS_RATIO",
    "BUREAU_ACTIVE_SHARE",
    "PREVIOUS_REFUSAL_RATE",
    "BUREAU_DEBT_INCOME_RATIO",
}

EXTRA_INPUT_FEATURES = [
    "BUREAU_CREDIT_COUNT",
    "PREVIOUS_REFUSED_COUNT",
    "PREVIOUS_APPLICATION_COUNT",
    "TOTAL_BUREAU_DEBT",
]


def safe_ratio(numerator, denominator):
    if numerator is None or denominator is None:
        return None

    numerator = float(numerator)
    denominator = float(denominator)

    if not math.isfinite(numerator):
        return None

    if not math.isfinite(denominator) or denominator <= 0:
        return None

    return numerator / denominator


def calculate_derived_features(raw: dict) -> dict:
    return {
        "CREDIT_GOODS_RATIO": safe_ratio(
            raw.get("AMT_CREDIT"),
            raw.get("AMT_GOODS_PRICE"),
        ),
        "BUREAU_ACTIVE_SHARE": safe_ratio(
            raw.get("ACTIVE_BUREAU_CREDIT_COUNT"),
            raw.get("BUREAU_CREDIT_COUNT"),
        ),
        "PREVIOUS_REFUSAL_RATE": safe_ratio(
            raw.get("PREVIOUS_REFUSED_COUNT"),
            raw.get("PREVIOUS_APPLICATION_COUNT"),
        ),
        "BUREAU_DEBT_INCOME_RATIO": safe_ratio(
            raw.get("TOTAL_BUREAU_DEBT"),
            raw.get("AMT_INCOME_TOTAL"),
        ),
    }

def get_manual_input_features(model_features):
    direct_features = [
        feature
        for feature in model_features
        if feature not in PYTHON_DERIVED_FEATURES
    ]

    return direct_features + EXTRA_INPUT_FEATURES

def build_manual_model_features(raw_values, model_features):
    required_inputs = get_manual_input_features(model_features)

    missing = [
        feature
        for feature in required_inputs
        if feature not in raw_values
    ]

    if missing:
        raise ValueError(f"Missing input fields: {missing}")

    derived_features = calculate_derived_features(raw_values)

    combined = {
        **raw_values,
        **derived_features,
    }

    return {
        feature: combined[feature]
        for feature in model_features
    }
