from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"
REPORT_DIR = PROJECT_ROOT / "reports"

CHUNK_SIZE = 500_000


def load_parent_ids(
    file_names: list[str],
    key_column: str,
) -> pd.Index:
    series_list = []

    for file_name in file_names:
        file_path = RAW_DATA_DIR / file_name

        df = pd.read_csv(
            file_path,
            usecols=[key_column],
        )

        series_list.append(df[key_column])

    combined_ids = pd.concat(
        series_list,
        ignore_index=True,
    )

    unique_ids = combined_ids.dropna().unique()

    return pd.Index(unique_ids)


def profile_relationship(
    parent_files: list[str],
    parent_key: str,
    child_file: str,
    child_key: str,
    relationship_name: str,
) -> dict:
    parent_ids = load_parent_ids(
        file_names=parent_files,
        key_column=parent_key,
    )

    child_path = RAW_DATA_DIR / child_file

    total_rows = 0
    null_key_rows = 0
    orphan_rows = 0
    orphan_ids = set()

    for chunk in pd.read_csv(
        child_path,
        usecols=[child_key],
        chunksize=CHUNK_SIZE,
    ):
        total_rows += len(chunk)

        child_series = chunk[child_key]

        null_mask = child_series.isna()

        null_key_rows += null_mask.sum()

        non_null_keys = child_series[~null_mask]

        orphan_mask = ~non_null_keys.isin(parent_ids)

        orphan_values = non_null_keys[orphan_mask]

        orphan_rows += len(orphan_values)

        orphan_ids.update(orphan_values.unique().tolist())

        orphan_row_rate = orphan_rows / total_rows if total_rows > 0 else 0

    return {
        "relationship": relationship_name,
        "parent": " + ".join(parent_files),
        "parent_key": parent_key,
        "child": child_file,
        "child_key": child_key,
        "child_row_count": total_rows,
        "null_fk_rows": null_key_rows,
        "orphan_row_count": orphan_rows,
        "orphan_id_count": len(orphan_ids),
        "orphan_row_rate_pct": round(orphan_row_rate * 100, 2),
        "referential_integrity_ok": (null_key_rows == 0 and orphan_rows == 0),
    }


RELATIONSHIPS = [
    {
        "relationship_name": "applications -> bureau",
        "parent_files": [
            "application_train.csv",
            "application_test.csv",
        ],
        "parent_key": "SK_ID_CURR",
        "child_file": "bureau.csv",
        "child_key": "SK_ID_CURR",
    },
    {
        "relationship_name": "bureau -> bureau_balance",
        "parent_files": [
            "bureau.csv",
        ],
        "parent_key": "SK_ID_BUREAU",
        "child_file": "bureau_balance.csv",
        "child_key": "SK_ID_BUREAU",
    },
    {
        "relationship_name": "applications -> previous_application",
        "parent_files": [
            "application_train.csv",
            "application_test.csv",
        ],
        "parent_key": "SK_ID_CURR",
        "child_file": "previous_application.csv",
        "child_key": "SK_ID_CURR",
    },
    {
        "relationship_name": "previous_application -> POS_CASH",
        "parent_files": [
            "previous_application.csv",
        ],
        "parent_key": "SK_ID_PREV",
        "child_file": "POS_CASH_balance.csv",
        "child_key": "SK_ID_PREV",
    },
    {
        "relationship_name": "previous_application -> credit_card",
        "parent_files": [
            "previous_application.csv",
        ],
        "parent_key": "SK_ID_PREV",
        "child_file": "credit_card_balance.csv",
        "child_key": "SK_ID_PREV",
    },
    {
        "relationship_name": "previous_application -> installments",
        "parent_files": [
            "previous_application.csv",
        ],
        "parent_key": "SK_ID_PREV",
        "child_file": "installments_payments.csv",
        "child_key": "SK_ID_PREV",
    },
]


def main() -> None:
    REPORT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    results = []

    for relationship in RELATIONSHIPS:
        print(f"Checking: {relationship['relationship_name']}")

        result = profile_relationship(
            **relationship,
        )

        results.append(result)

    results_df = pd.DataFrame(results)

    output_path = REPORT_DIR / "relationship_profile.csv"

    results_df.to_csv(
        output_path,
        index=False,
    )

    display_df = results_df.copy()

    numeric_columns = [
        "child_row_count",
        "null_fk_rows",
        "orphan_row_count",
        "orphan_id_count",
    ]

    for column in numeric_columns:
        display_df[column] = display_df[column].map(lambda value: f"{value:,}")

    print()
    print(display_df.to_string(index=False))
    print()
    print(f"Report saved to: {output_path}")


if __name__ == "__main__":
    main()
