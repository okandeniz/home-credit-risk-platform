/* ============================================================
   Project: Home Credit Risk Platform
   File: 01_validate_application_train.sql

   Purpose:
       Validate the raw.application_train table after ingestion.

   Important:
       This script does not modify the data.
       It only checks data quality.
   ============================================================ */

USE HomeCreditRisk;
GO

/* ============================================================
   1. ROW COUNT
   ============================================================ */

SELECT
    COUNT_BIG(*) AS row_count
FROM raw.application_train;

/* ============================================================
   2. SK_ID_CURR UNIQUENESS
   ============================================================ */

SELECT
    COUNT_BIG(*) AS total_rows,
    COUNT_BIG(DISTINCT SK_ID_CURR) AS unique_customer_ids,
    COUNT_BIG(*) - COUNT_BIG(DISTINCT SK_ID_CURR)
        AS duplicate_id_count
FROM raw.application_train;

SELECT
    SK_ID_CURR,
    COUNT_BIG(*) AS occurrence_count
FROM raw.application_train
GROUP BY SK_ID_CURR
HAVING COUNT_BIG(*) > 1
ORDER BY occurrence_count DESC;

/* ============================================================
   3. CRITICAL NULL CHECK
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN SK_ID_CURR IS NULL THEN 1
            ELSE 0
        END
    ) AS null_customer_id_count,

    SUM(
        CASE
            WHEN TARGET IS NULL THEN 1
            ELSE 0
        END
    ) AS null_target_count

FROM raw.application_train;

/* ============================================================
   4. TARGET DOMAIN
   ============================================================ */

SELECT
    TARGET,
    COUNT_BIG(*) AS customer_count,
    CAST(
        100.0 * COUNT_BIG(*)
        / SUM(COUNT_BIG(*)) OVER()
        AS DECIMAL(10,2)
    ) AS percentage
FROM raw.application_train
GROUP BY TARGET
ORDER BY TARGET;

/* ============================================================
   5. FINANCIAL VALUE CHECKS
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN AMT_INCOME_TOTAL <= 0
            THEN 1
            ELSE 0
        END
    ) AS invalid_income_count,

    SUM(
        CASE
            WHEN AMT_CREDIT <= 0
            THEN 1
            ELSE 0
        END
    ) AS invalid_credit_count,

    SUM(
        CASE
            WHEN AMT_ANNUITY <= 0
            THEN 1
            ELSE 0
        END
    ) AS invalid_annuity_count,

    SUM(
        CASE
            WHEN AMT_GOODS_PRICE <= 0
            THEN 1
            ELSE 0
        END
    ) AS invalid_goods_price_count

FROM raw.application_train;


SELECT
    MIN(AMT_INCOME_TOTAL) AS min_income,
    AVG(AMT_INCOME_TOTAL) AS avg_income,
    MAX(AMT_INCOME_TOTAL) AS max_income,

    MIN(AMT_CREDIT) AS min_credit,
    AVG(AMT_CREDIT) AS avg_credit,
    MAX(AMT_CREDIT) AS max_credit,

    MIN(AMT_ANNUITY) AS min_annuity,
    AVG(AMT_ANNUITY) AS avg_annuity,
    MAX(AMT_ANNUITY) AS max_annuity

FROM raw.application_train;

/* ============================================================
   6. AGE CHECK
   ============================================================ */

SELECT
    MIN(DAYS_BIRTH) AS min_days_birth,
    MAX(DAYS_BIRTH) AS max_days_birth,

    MIN(
        ABS(DAYS_BIRTH) / 365.25
    ) AS min_age,

    MAX(
        ABS(DAYS_BIRTH) / 365.25
    ) AS max_age

FROM raw.application_train;

/* ============================================================
   7. DAYS_EMPLOYED SENTINEL
   ============================================================ */

SELECT
    COUNT_BIG(*) AS sentinel_count,

    CAST(
        100.0 * COUNT_BIG(*)
        / (
            SELECT COUNT_BIG(*)
            FROM raw.application_train
        )
        AS DECIMAL(10,2)
    ) AS sentinel_percentage

FROM raw.application_train
WHERE DAYS_EMPLOYED = 365243;

SELECT
    CODE_GENDER,
    COUNT_BIG(*) AS customer_count
FROM raw.application_train
GROUP BY CODE_GENDER
ORDER BY customer_count DESC;

SELECT
    NAME_CONTRACT_TYPE,
    COUNT_BIG(*) AS customer_count
FROM raw.application_train
GROUP BY NAME_CONTRACT_TYPE
ORDER BY customer_count DESC;

SELECT
    NAME_INCOME_TYPE,
    COUNT_BIG(*) AS customer_count
FROM raw.application_train
GROUP BY NAME_INCOME_TYPE
ORDER BY customer_count DESC;


SELECT
    load_id,
    source_file,
    target_schema,
    target_table,
    source_row_count,
    loaded_row_count,
    duration_seconds,
    load_status,
    error_message
FROM etl.raw_load_audit
ORDER BY load_id DESC;