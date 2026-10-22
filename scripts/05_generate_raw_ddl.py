from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]

PROFILE_DIR = PROJECT_ROOT / "reports" / "column_profiles"

SQL_OUTPUT_PATH = PROJECT_ROOT / "sql" / "02_tables" / "01_create_raw_tables.sql"

MAPPING_OUTPUT_PATH = PROJECT_ROOT / "reports" / "sql_dtype_mapping.csv"

SQL_SCHEMA = "raw"

PROFILE_FILES = [
    "application_train_profile.csv",
    "application_test_profile.csv",
    "bureau_profile.csv",
    "bureau_balance_profile.csv",
    "previous_application_profile.csv",
    "POS_CASH_balance_profile.csv",
    "credit_card_balance_profile.csv",
    "installments_payments_profile.csv",
]


def safe_float(value):
    if pd.isna(value):
        return None

    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def safe_bool(value) -> bool:
    if isinstance(value, bool):
        return value

    if pd.isna(value):
        return False

    return str(value).strip().lower() == "true"


def choose_varchar_type(max_length: int) -> str:
    if max_length <= 10:
        return "VARCHAR(10)"

    if max_length <= 20:
        return "VARCHAR(20)"

    if max_length <= 50:
        return "VARCHAR(50)"

    if max_length <= 100:
        return "VARCHAR(100)"

    if max_length <= 255:
        return "VARCHAR(255)"

    if max_length <= 500:
        return "VARCHAR(500)"

    if max_length <= 1000:
        return "VARCHAR(1000)"

    return "VARCHAR(MAX)"


def is_amount_column(column_name: str) -> bool:
    return column_name.startswith("AMT_") and not column_name.startswith(
        "AMT_REQ_CREDIT_BUREAU_"
    )


def is_credit_bureau_count(column_name: str) -> bool:
    return column_name.startswith("AMT_REQ_CREDIT_BUREAU_")


def is_id_column(column_name: str) -> bool:
    return column_name.startswith("SK_ID_")


def is_flag_column(column_name: str) -> bool:
    return column_name.startswith(("FLAG_", "NFLAG_")) or column_name == "TARGET"


def is_text_dtype(pandas_dtype: str) -> bool:
    normalized_dtype = pandas_dtype.strip().lower()

    return normalized_dtype in {
        "object",
        "str",
        "string",
    } or normalized_dtype.startswith("string")


def infer_sql_type(row: pd.Series) -> tuple[str, str]:
    column_name = row["column_name"]

    pandas_dtype = str(row["pandas_dtype"])

    is_integer_like = safe_bool(row.get("is_integer_like"))

    min_value = safe_float(row.get("min_value"))

    max_value = safe_float(row.get("max_value"))

    max_text_length = row.get(
        "max_text_length",
        0,
    )

    if pd.isna(max_text_length):
        max_text_length = 0

    max_text_length = int(max_text_length)

    if is_text_dtype(pandas_dtype):
        sql_type = choose_varchar_type(max_text_length)

        return (
            sql_type,
            "Categorical or text column",
        )

    if is_id_column(column_name):
        return (
            "INT",
            "Identifier within SQL Server INT range",
        )

    if is_flag_column(column_name) and pandas_dtype.startswith("int"):
        return (
            "TINYINT",
            "Integer binary flag or target",
        )

    if is_credit_bureau_count(column_name):
        if pandas_dtype.startswith("float"):
            return (
                "FLOAT",
                "Nullable count stored as float in source",
            )

        return (
            "INT",
            "Credit bureau request count",
        )

    if is_amount_column(column_name):
        return (
            "DECIMAL(19,3)",
            "Monetary amount",
        )

    if is_integer_like and pandas_dtype.startswith("int"):
        if (
            min_value is not None
            and max_value is not None
            and min_value >= -2_147_483_648
            and max_value <= 2_147_483_647
        ):
            return (
                "INT",
                "Integer source column",
            )

        return (
            "BIGINT",
            "Integer source column outside INT range",
        )

    if pandas_dtype.startswith(("int", "float")):
        return (
            "FLOAT",
            "Continuous numeric value",
        )

    return (
        "VARCHAR(255)",
        "Fallback type",
    )


def get_table_name(
    profile_path: Path,
) -> str:
    return profile_path.stem.removesuffix("_profile").lower()


def generate_table_ddl(
    table_name: str,
    profile_df: pd.DataFrame,
) -> tuple[str, list[dict]]:
    column_definitions = []
    mapping_rows = []

    for _, row in profile_df.iterrows():
        column_name = row["column_name"]

        sql_type, reason = infer_sql_type(row)

        column_definitions.append(f"        [{column_name}] {sql_type} NULL")

        mapping_rows.append(
            {
                "table_name": table_name,
                "column_name": column_name,
                "pandas_dtype": row["pandas_dtype"],
                "sql_type": sql_type,
                "reason": reason,
                "null_pct": row["null_pct"],
                "min_value": row["min_value"],
                "max_value": row["max_value"],
                "max_text_length": row["max_text_length"],
            }
        )

    columns_sql = ",\n".join(column_definitions)

    ddl = f"""
    IF OBJECT_ID(
        N'[{SQL_SCHEMA}].[{table_name}]',
        N'U'
    ) IS NULL
    BEGIN
        CREATE TABLE [{SQL_SCHEMA}].[{table_name}]
        (
    {columns_sql}
        );
    END;
    GO
    """.strip()

    return ddl, mapping_rows


def main() -> None:
    SQL_OUTPUT_PATH.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    all_ddl = []
    all_mapping_rows = []

    for profile_file in PROFILE_FILES:
        profile_path = PROFILE_DIR / profile_file

        print(f"Processing: {profile_file}")

        profile_df = pd.read_csv(profile_path)

        table_name = get_table_name(profile_path)

        ddl, mapping_rows = generate_table_ddl(
            table_name=table_name,
            profile_df=profile_df,
        )

        all_ddl.append(ddl)

        all_mapping_rows.extend(mapping_rows)

    sql_script = "USE HomeCreditRisk;\nGO\n\n" + "\n\n".join(all_ddl) + "\n"

    SQL_OUTPUT_PATH.write_text(
        sql_script,
        encoding="utf-8",
    )

    mapping_df = pd.DataFrame(all_mapping_rows)

    mapping_df.to_csv(
        MAPPING_OUTPUT_PATH,
        index=False,
    )

    print()
    print(f"DDL saved to: {SQL_OUTPUT_PATH}")

    print(f"Mapping saved to: {MAPPING_OUTPUT_PATH}")


if __name__ == "__main__":
    main()
