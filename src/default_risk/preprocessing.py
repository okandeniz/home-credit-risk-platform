
import pandas as pd


CATEGORICAL_FEATURES = ("NAME_CONTRACT_TYPE",)


def prepare_lgbm_features(dataframe):
    data = dataframe.copy()

    for col in data.columns:
        if col in CATEGORICAL_FEATURES:
            data[col] = data[col].astype("category")
        elif not pd.api.types.is_numeric_dtype(data[col]):
            data[col] = pd.to_numeric(data[col], errors="raise")

    return data
