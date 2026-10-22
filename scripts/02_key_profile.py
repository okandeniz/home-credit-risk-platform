from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"
REPORT_DIR = PROJECT_ROOT / "reports"

## Let's examine the key structure of small and medium-sized tables.


def profile_key(
    file_name: str,
    key_columns: list[str],
) -> dict:
    file_path = RAW_DATA_DIR / file_name

    df = pd.read_csv(file_path, usecols=key_columns)

    row_count = len(df)

    duplicate_count = df.duplicated(subset=key_columns).sum()

    null_count = df[key_columns].isna().any(axis=1).sum()

    unique_count = df[key_columns].drop_duplicates().shape[0]

    return {
        "file_name": file_name,
        "key_columns": " + ".join(key_columns),
        "row_count": row_count,
        "unique_key_count": unique_count,
        "duplicate_key_count": duplicate_count,
        "null_key_count": null_count,
        "is_unique": duplicate_count == 0,
    }


def profile_installment_keys() -> pd.DataFrame:
    file_path = RAW_DATA_DIR / "installments_payments.csv"

    columns = [
        "SK_ID_PREV",
        "NUM_INSTALMENT_VERSION",
        "NUM_INSTALMENT_NUMBER",
    ]

    df = pd.read_csv(
        file_path,
        usecols=columns,
    )

    key_candidates = [
        ["SK_ID_PREV"],
        [
            "SK_ID_PREV",
            "NUM_INSTALMENT_NUMBER",
        ],
        [
            "SK_ID_PREV",
            "NUM_INSTALMENT_VERSION",
            "NUM_INSTALMENT_NUMBER",
        ],
    ]

    results = []

    for key_columns in key_candidates:
        duplicate_count = df.duplicated(
            subset=key_columns,
        ).sum()

        results.append(
            {
                "key_columns": " + ".join(key_columns),
                "duplicate_count": duplicate_count,
                "is_unique": duplicate_count == 0,
            }
        )

    return pd.DataFrame(results)


def check_train_test_overlap() -> None:
    train_ids = pd.read_csv(
        RAW_DATA_DIR / "application_train.csv",
        usecols=["SK_ID_CURR"],
    )

    test_ids = pd.read_csv(
        RAW_DATA_DIR / "application_test.csv",
        usecols=["SK_ID_CURR"],
    )

    overlap = set(train_ids["SK_ID_CURR"]).intersection(set(test_ids["SK_ID_CURR"]))

    print()
    print("Train/Test ID overlap")
    print("-" * 50)

    print(f"Overlapping SK_ID_CURR count: {len(overlap):,}")


KEY_CHECKS = [
    (
        "application_train.csv",
        ["SK_ID_CURR"],
    ),
    (
        "application_test.csv",
        ["SK_ID_CURR"],
    ),
    (
        "bureau.csv",
        ["SK_ID_BUREAU"],
    ),
    (
        "bureau_balance.csv",
        ["SK_ID_BUREAU", "MONTHS_BALANCE"],
    ),
    (
        "previous_application.csv",
        ["SK_ID_PREV"],
    ),
    (
        "POS_CASH_balance.csv",
        ["SK_ID_PREV", "MONTHS_BALANCE"],
    ),
    (
        "credit_card_balance.csv",
        ["SK_ID_PREV", "MONTHS_BALANCE"],
    ),
]


def main() -> None:
    results = []

    for file_name, key_columns in KEY_CHECKS:
        print(f"Checking {file_name}: {' + '.join(key_columns)}")

        result = profile_key(
            file_name=file_name,
            key_columns=key_columns,
        )

        results.append(result)

    results_df = pd.DataFrame(results)

    output_path = REPORT_DIR / "key_profile.csv"

    results_df.to_csv(
        output_path,
        index=False,
    )

    print()
    print(results_df.to_string(index=False))
    print()
    print(f"Report saved to: {output_path}")

    print()
    print("Installments key analysis")
    print("-" * 50)

    installment_results = profile_installment_keys()

    print(
        installment_results.to_string(
            index=False,
        )
    )

    check_train_test_overlap()


if __name__ == "__main__":
    main()
