from pathlib import Path

import numpy as np
import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]

RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

REPORT_DIR = PROJECT_ROOT / "reports" / "column_profiles"

CHUNK_SIZE = 250_000


def profile_csv_columns(
    file_path: Path,
) -> pd.DataFrame:
    profiles = {}

    for chunk in pd.read_csv(
        file_path,
        chunksize=CHUNK_SIZE,
        low_memory=False,
    ):
        for column in chunk.columns:
            series = chunk[column]

            if column not in profiles:
                profiles[column] = {
                    "column_name": column,
                    "row_count": 0,
                    "null_count": 0,
                    "pandas_dtype": str(series.dtype),
                    "min_value": None,
                    "max_value": None,
                    "max_text_length": 0,
                    "has_fractional_values": False,
                }

            profile = profiles[column]

            profile["row_count"] += len(series)

            profile["null_count"] += series.isna().sum()

            non_null = series.dropna()

            if non_null.empty:
                continue

            if pd.api.types.is_numeric_dtype(series):
                current_min = non_null.min()
                current_max = non_null.max()

                if profile["min_value"] is None or current_min < profile["min_value"]:
                    profile["min_value"] = current_min

                if profile["max_value"] is None or current_max > profile["max_value"]:
                    profile["max_value"] = current_max

                values = non_null.to_numpy(dtype=float)

                fractional_mask = ~np.isclose(
                    values,
                    np.round(values),
                    atol=1e-9,
                )

                if fractional_mask.any():
                    profile["has_fractional_values"] = True

            else:
                current_max_length = non_null.astype(str).str.len().max()

                profile["max_text_length"] = max(
                    profile["max_text_length"],
                    int(current_max_length),
                )

    profile_df = pd.DataFrame(profiles.values())

    profile_df["null_pct"] = (
        profile_df["null_count"] / profile_df["row_count"] * 100
    ).round(2)

    profile_df["is_integer_like"] = (
        profile_df["pandas_dtype"].isin(["int64", "float64"])
        & ~profile_df["has_fractional_values"]
    )

    return profile_df


DATA_FILES = [
    "application_train.csv",
    "application_test.csv",
    "bureau.csv",
    "bureau_balance.csv",
    "previous_application.csv",
    "POS_CASH_balance.csv",
    "credit_card_balance.csv",
    "installments_payments.csv",
]


def main() -> None:
    REPORT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    for file_name in DATA_FILES:
        print(f"Profiling: {file_name}")

        file_path = RAW_DATA_DIR / file_name

        profile_df = profile_csv_columns(file_path)

        output_file = REPORT_DIR / f"{file_path.stem}_profile.csv"

        profile_df.to_csv(
            output_file,
            index=False,
        )

        print(f"Saved: {output_file}")

    print()
    print("Column profiling completed.")


if __name__ == "__main__":
    main()
