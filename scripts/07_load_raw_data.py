import argparse
import csv
import os
import time
from pathlib import Path

import pandas as pd
import pyodbc
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[1]

RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

INVENTORY_PATH = PROJECT_ROOT / "reports" / "raw_data_inventory.csv"

ENV_PATH = PROJECT_ROOT / ".env"

SQL_BULK_DIR = PROJECT_ROOT / "data" / "interim" / "sql_bulk"

CHUNK_SIZE = 250_000


LOAD_CONFIG = {
    "application_train": {
        "file_name": "application_train.csv",
        "table_name": "application_train",
    },
    "application_test": {
        "file_name": "application_test.csv",
        "table_name": "application_test",
    },
    "bureau": {
        "file_name": "bureau.csv",
        "table_name": "bureau",
    },
    "bureau_balance": {
        "file_name": "bureau_balance.csv",
        "table_name": "bureau_balance",
    },
    "previous_application": {
        "file_name": "previous_application.csv",
        "table_name": "previous_application",
    },
    "pos_cash_balance": {
        "file_name": "POS_CASH_balance.csv",
        "table_name": "pos_cash_balance",
    },
    "credit_card_balance": {
        "file_name": "credit_card_balance.csv",
        "table_name": "credit_card_balance",
    },
    "installments_payments": {
        "file_name": "installments_payments.csv",
        "table_name": "installments_payments",
    },
}


def prepare_bulk_file(
    source_path: Path,
    table_name: str,
) -> Path:
    SQL_BULK_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    output_path = SQL_BULK_DIR / f"{table_name}.tsv"

    if output_path.exists():
        output_path.unlink()

    first_chunk = True

    print(f"Preparing SQL bulk file: {output_path.name}")

    for chunk_number, chunk in enumerate(
        pd.read_csv(
            source_path,
            dtype=str,
            keep_default_na=False,
            chunksize=CHUNK_SIZE,
        ),
        start=1,
    ):
        chunk.to_csv(
            output_path,
            sep="\t",
            index=False,
            header=False,
            mode="w" if first_chunk else "a",
            encoding="utf-8",
            lineterminator="\n",
            quoting=csv.QUOTE_NONE,
            escapechar="\\",
        )

        first_chunk = False

        print(f"Prepared chunk {chunk_number:,}")

    return output_path


def create_connection() -> pyodbc.Connection:
    load_dotenv(ENV_PATH)

    server = os.getenv("SQL_SERVER")
    database = os.getenv("SQL_DATABASE")
    driver = os.getenv("SQL_DRIVER")

    if not all([server, database, driver]):
        raise ValueError("SQL connection settings are missing from the .env file.")

    connection_string = (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )

    return pyodbc.connect(connection_string)


def get_source_row_count(file_name: str) -> int:
    inventory_df = pd.read_csv(INVENTORY_PATH)

    matching_row = inventory_df[inventory_df["file_name"] == file_name]

    if matching_row.empty:
        raise ValueError(f"{file_name} was not found in raw_data_inventory.csv.")

    return int(matching_row.iloc[0]["row_count"])


def start_audit(
    connection: pyodbc.Connection,
    source_file: str,
    target_table: str,
    source_row_count: int,
) -> int:
    cursor = connection.cursor()

    try:
        query = """
        INSERT INTO etl.raw_load_audit
        (
            source_file,
            target_schema,
            target_table,
            source_row_count,
            load_started_at,
            load_status
        )
        OUTPUT INSERTED.load_id
        VALUES
        (
            ?,
            'raw',
            ?,
            ?,
            SYSDATETIME(),
            'STARTED'
        );
        """

        cursor.execute(
            query,
            source_file,
            target_table,
            source_row_count,
        )

        load_id = cursor.fetchone()[0]

        connection.commit()

        return int(load_id)

    finally:
        cursor.close()


def finish_audit(
    connection: pyodbc.Connection,
    load_id: int,
    loaded_row_count: int | None,
    duration_seconds: float,
    status: str,
    error_message: str | None = None,
) -> None:
    cursor = connection.cursor()

    try:
        query = """
        UPDATE etl.raw_load_audit
        SET
            loaded_row_count = ?,
            load_finished_at = SYSDATETIME(),
            duration_seconds = ?,
            load_status = ?,
            error_message = ?
        WHERE load_id = ?;
        """

        cursor.execute(
            query,
            loaded_row_count,
            duration_seconds,
            status,
            error_message,
            load_id,
        )

        connection.commit()

    finally:
        cursor.close()


def get_csv_columns(file_path: Path) -> list[str]:
    with file_path.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as csv_file:
        reader = csv.reader(csv_file)

        return next(reader)


def get_sql_columns(
    connection: pyodbc.Connection,
    table_name: str,
) -> list[str]:
    cursor = connection.cursor()

    try:
        query = """
        SELECT c.name
        FROM sys.columns AS c
        WHERE c.object_id = OBJECT_ID(?)
        ORDER BY c.column_id;
        """

        cursor.execute(
            query,
            f"raw.{table_name}",
        )

        return [row[0] for row in cursor.fetchall()]

    finally:
        cursor.close()


def validate_column_structure(
    connection: pyodbc.Connection,
    file_path: Path,
    table_name: str,
) -> None:
    csv_columns = get_csv_columns(file_path)

    sql_columns = get_sql_columns(
        connection=connection,
        table_name=table_name,
    )

    print(f"CSV columns  : {len(csv_columns)}")
    print(f"SQL columns  : {len(sql_columns)}")

    if csv_columns == sql_columns:
        print("Column check : PASS")
        return

    print("Column check : FAILED")

    if len(csv_columns) != len(sql_columns):
        raise ValueError(
            "CSV and SQL column counts do not match. "
            f"CSV={len(csv_columns)}, "
            f"SQL={len(sql_columns)}"
        )

    differences = []

    for position, (
        csv_column,
        sql_column,
    ) in enumerate(
        zip(
            csv_columns,
            sql_columns,
            strict=True,
        ),
        start=1,
    ):
        if csv_column != sql_column:
            differences.append(
                (
                    position,
                    csv_column,
                    sql_column,
                )
            )

    message_lines = ["CSV and SQL column order do not match."]

    for (
        position,
        csv_column,
        sql_column,
    ) in differences[:10]:
        message_lines.append(f"Position {position}: CSV={csv_column}, SQL={sql_column}")

    raise ValueError("\n".join(message_lines))


def get_loaded_row_count(
    connection: pyodbc.Connection,
    table_name: str,
) -> int:
    cursor = connection.cursor()

    try:
        query = f"SELECT COUNT_BIG(*) FROM [raw].[{table_name}];"

        cursor.execute(query)

        row_count = cursor.fetchone()[0]

        return int(row_count)

    finally:
        cursor.close()


def bulk_insert_file(
    connection: pyodbc.Connection,
    file_path: Path,
    table_name: str,
) -> None:
    absolute_path = str(file_path.resolve())

    safe_path = absolute_path.replace(
        "'",
        "''",
    )

    cursor = connection.cursor()

    try:
        cursor.execute(
            f"""
            TRUNCATE TABLE
            [raw].[{table_name}];
            """
        )

        bulk_query = f"""
        BULK INSERT [raw].[{table_name}]
        FROM '{safe_path}'
        WITH
        (
            DATAFILETYPE = 'char',
            FIELDTERMINATOR = '\\t',
            ROWTERMINATOR = '0x0a',
            CODEPAGE = '65001',
            KEEPNULLS,
            TABLOCK
        );
        """

        cursor.execute(bulk_query)

    finally:
        cursor.close()


def load_table(table_key: str) -> None:
    config = LOAD_CONFIG[table_key]

    file_name = config["file_name"]
    table_name = config["table_name"]

    file_path = RAW_DATA_DIR / file_name

    if not file_path.exists():
        raise FileNotFoundError(f"Source file not found: {file_path}")

    source_row_count = get_source_row_count(file_name)

    connection = create_connection()

    load_id = None
    loaded_row_count = None

    start_time = time.perf_counter()

    try:
        load_id = start_audit(
            connection=connection,
            source_file=file_name,
            target_table=table_name,
            source_row_count=source_row_count,
        )

        print()
        print(f"Loading {file_name} into raw.{table_name}...")

        validate_column_structure(
            connection=connection,
            file_path=file_path,
            table_name=table_name,
        )

        bulk_file_path = prepare_bulk_file(
            source_path=file_path,
            table_name=table_name,
        )

        bulk_insert_file(
            connection=connection,
            file_path=bulk_file_path,
            table_name=table_name,
        )

        loaded_row_count = get_loaded_row_count(
            connection=connection,
            table_name=table_name,
        )

        if loaded_row_count != source_row_count:
            raise ValueError(
                "Row count mismatch. "
                f"Source={source_row_count:,}, "
                f"SQL={loaded_row_count:,}"
            )

        # Commit TRUNCATE + BULK INSERT only
        # after validation is successful.
        connection.commit()

        duration = time.perf_counter() - start_time

        finish_audit(
            connection=connection,
            load_id=load_id,
            loaded_row_count=loaded_row_count,
            duration_seconds=duration,
            status="SUCCESS",
        )

        if bulk_file_path.exists():
            bulk_file_path.unlink()

        print(f"Source rows : {source_row_count:,}")
        print(f"Loaded rows : {loaded_row_count:,}")
        print(f"Duration    : {duration:.2f} seconds")
        print("Status      : SUCCESS")

    except Exception as exc:
        # Roll back TRUNCATE and BULK INSERT.
        connection.rollback()

        duration = time.perf_counter() - start_time

        if load_id is not None:
            finish_audit(
                connection=connection,
                load_id=load_id,
                loaded_row_count=loaded_row_count,
                duration_seconds=duration,
                status="FAILED",
                error_message=str(exc)[:4000],
            )

        print()
        print("Status      : FAILED")
        print(f"Error       : {exc}")

        raise

    finally:
        connection.close()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=("Load Home Credit CSV files into SQL Server raw tables.")
    )

    parser.add_argument(
        "--table",
        required=True,
        choices=LOAD_CONFIG.keys(),
        help="Raw table to load.",
    )

    return parser.parse_args()


def main() -> None:
    args = parse_args()

    load_table(args.table)


if __name__ == "__main__":
    main()
