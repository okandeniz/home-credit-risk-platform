from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]

MAPPING_PATH = PROJECT_ROOT / "reports" / "sql_dtype_mapping.csv"


IMPORTANT_COLUMNS = [
    "SK_ID_CURR",
    "SK_ID_PREV",
    "SK_ID_BUREAU",
    "TARGET",
    "AMT_CREDIT",
    "AMT_INCOME_TOTAL",
    "AMT_PAYMENT",
    "AMT_REQ_CREDIT_BUREAU_YEAR",
    "EXT_SOURCE_1",
    "DAYS_BIRTH",
    "CNT_CHILDREN",
    "CNT_PAYMENT",
    "NAME_CONTRACT_TYPE",
    "FLAG_OWN_CAR",
    "MONTHS_BALANCE",
    "NUM_INSTALMENT_VERSION",
    "SK_DPD",
]


def main() -> None:
    mapping_df = pd.read_csv(MAPPING_PATH)

    selected = mapping_df[mapping_df["column_name"].isin(IMPORTANT_COLUMNS)].copy()

    selected = selected[
        [
            "table_name",
            "column_name",
            "pandas_dtype",
            "sql_type",
            "reason",
            "null_pct",
        ]
    ]

    print("\nImportant datatype mappings")
    print("-" * 100)

    print(selected.sort_values(["column_name", "table_name"]).to_string(index=False))

    print("\nFallback mappings")
    print("-" * 100)

    fallback = mapping_df[mapping_df["reason"] == "Fallback type"]

    if fallback.empty:
        print("No fallback mappings found.")
    else:
        print(
            fallback[
                [
                    "table_name",
                    "column_name",
                    "pandas_dtype",
                    "sql_type",
                ]
            ].to_string(index=False)
        )


if __name__ == "__main__":
    main()
