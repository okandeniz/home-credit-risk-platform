from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]

RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"
REPORT_DIR = PROJECT_ROOT / "reports"

CHUNK_SIZE = 500_000


DATA_FILES = {
    "application_train.csv": "Current loan applications with target",
    "application_test.csv": "Current loan applications without target",
    "bureau.csv": "Customer credit bureau history",
    "bureau_balance.csv": "Monthly bureau credit history",
    "previous_application.csv": "Previous Home Credit applications",
    "POS_CASH_balance.csv": "Monthly POS and cash loan balances",
    "credit_card_balance.csv": "Monthly credit card balances",
    "installments_payments.csv": "Installment payment history",
}


def count_csv_rows(file_path: Path) -> int:
    row_count = 0

    for chunk in pd.read_csv(file_path, chunksize=CHUNK_SIZE, usecols=[0]):
        row_count += len(chunk)

    return row_count


def get_column_info(file_path: Path) -> tuple[int, list[str]]:
    sample = pd.read_csv(file_path, nrows=5)

    columns = sample.columns.tolist()

    return len(columns), columns


def find_id_columns(columns: list[str]) -> list[str]:
    possible_ids = [
        "SK_ID_CURR",
        "SK_ID_PREV",
        "SK_ID_BUREAU",
        "TARGET",
    ]

    return [column for column in possible_ids if column in columns]


def get_file_size_mb(file_path: Path) -> float:
    size_bytes = file_path.stat().st_size

    size_mb = size_bytes / (1024**2)

    return round(size_mb, 2)


def inspect_file(file_name: str, description: str) -> dict:
    file_path = RAW_DATA_DIR / file_name

    if not file_path.exists():
        return {
            "file_name": file_name,
            "description": description,
            "exists": False,
            "file_size_mb": None,
            "row_count": None,
            "column_count": None,
            "id_columns": None,
        }

    column_count, columns = get_column_info(file_path)

    row_count = count_csv_rows(file_path)

    return {
        "file_name": file_name,
        "description": description,
        "exists": True,
        "file_size_mb": get_file_size_mb(file_path),
        "row_count": row_count,
        "column_count": column_count,
        "id_columns": ", ".join(find_id_columns(columns)),
    }


def main() -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)

    inventory = []

    for file_name, description in DATA_FILES.items():
        print(f"Inspecting: {file_name}")

        result = inspect_file(
            file_name=file_name,
            description=description,
        )

        inventory.append(result)

    inventory_df = pd.DataFrame(inventory)

    output_path = REPORT_DIR / "raw_data_inventory.csv"

    inventory_df.to_csv(
        output_path,
        index=False,
    )

    print()
    print(inventory_df.to_string(index=False))
    print()
    print(f"Inventory saved to: {output_path}")


if __name__ == "__main__":
    main()
