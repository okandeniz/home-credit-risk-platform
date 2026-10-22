/* ============================================================
   Project: Home Credit Risk Platform
   File: 02_profile_application_train_anomalies.sql

   Purpose:
       Explore important anomalies and unusual values
       in raw.application_train.

   Note:
       This script does not change the source data.
   ============================================================ */

USE HomeCreditRisk;
GO

SELECT TOP 10 *
FROM raw.application_train;

/* ============================================================
   1. FINANCIAL VALUE QUALITY
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN AMT_INCOME_TOTAL <= 0 THEN 1
            ELSE 0
        END
    ) AS invalid_income_count,

    SUM(
        CASE
            WHEN AMT_CREDIT <= 0 THEN 1
            ELSE 0
        END
    ) AS invalid_credit_count,

    SUM(
        CASE
            WHEN AMT_ANNUITY <= 0 THEN 1
            ELSE 0
        END
    ) AS invalid_annuity_count,

    SUM(
        CASE
            WHEN AMT_GOODS_PRICE <= 0 THEN 1
            ELSE 0
        END
    ) AS invalid_goods_price_count,

    SUM(
        CASE
            WHEN AMT_INCOME_TOTAL IS NULL THEN 1
            ELSE 0
        END
    ) AS null_income_count,

    SUM(
        CASE
            WHEN AMT_CREDIT IS NULL THEN 1
            ELSE 0
        END
    ) AS null_credit_count,

    SUM(
        CASE
            WHEN AMT_ANNUITY IS NULL THEN 1
            ELSE 0
        END
    ) AS null_annuity_count,

    SUM(
        CASE
            WHEN AMT_GOODS_PRICE IS NULL THEN 1
            ELSE 0
        END
    ) AS null_goods_price_count

FROM raw.application_train;
GO

/* ============================================================
   2. FINANCIAL DISTRIBUTION
   ============================================================ */

SELECT TOP(1)

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (
            ORDER BY AMT_INCOME_TOTAL
        ) OVER() AS income_p50,

    PERCENTILE_CONT(0.95)
        WITHIN GROUP (
            ORDER BY AMT_INCOME_TOTAL
        ) OVER () AS income_p95,

    PERCENTILE_CONT(0.99)
        WITHIN GROUP (
            ORDER BY AMT_INCOME_TOTAL
        ) OVER () AS income_p99,

    PERCENTILE_CONT(0.999)
        WITHIN GROUP (
            ORDER BY AMT_INCOME_TOTAL
        ) OVER () AS income_p999,

    MAX(AMT_INCOME_TOTAL)
        OVER () AS income_max

FROM raw.application_train;
GO

/* ============================================================
   3. TOP 10 INCOME VALUES
   ============================================================ */

SELECT TOP (10)
    SK_ID_CURR,
    TARGET,
    AMT_INCOME_TOTAL,
    AMT_CREDIT,
    AMT_ANNUITY
FROM raw.application_train
ORDER BY AMT_INCOME_TOTAL DESC;
GO

/* ============================================================
   4. AGE QUALITY
   ============================================================ */

SELECT
    MIN(DAYS_BIRTH) AS min_days_birth,

    MAX(DAYS_BIRTH) AS max_days_birth,

    CAST(
        MIN(
            ABS(DAYS_BIRTH) / 365.25
        )
        AS DECIMAL(10,2)
    ) AS min_age,

    CAST(
        MAX(
            ABS(DAYS_BIRTH) / 365.25
        )
        AS DECIMAL(10,2)
    ) AS max_age,

    SUM(
        CASE
            WHEN DAYS_BIRTH >= 0 THEN 1
            ELSE 0
        END
    ) AS invalid_days_birth_count

FROM raw.application_train;
GO

/* ============================================================
   5. DAYS EMPLOYED QUALITY
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN DAYS_EMPLOYED = 365243
                THEN 1
            ELSE 0
        END
    ) AS sentinel_count,

    SUM(
        CASE
            WHEN DAYS_EMPLOYED > 0
                 AND DAYS_EMPLOYED <> 365243
                THEN 1
            ELSE 0
        END
    ) AS unexpected_positive_count,

    MIN(
        CASE
            WHEN DAYS_EMPLOYED <> 365243
                THEN DAYS_EMPLOYED
        END
    ) AS min_valid_days_employed,

    MAX(
        CASE
            WHEN DAYS_EMPLOYED <> 365243
                THEN DAYS_EMPLOYED
        END
    ) AS max_valid_days_employed

FROM raw.application_train;
GO

/* ============================================================
   6. CREDIT / INCOME RATIO
   ============================================================ */

SELECT
    MIN(
        AMT_CREDIT
        / NULLIF(AMT_INCOME_TOTAL, 0)
    ) AS min_credit_income_ratio,

    AVG(
        AMT_CREDIT
        / NULLIF(AMT_INCOME_TOTAL, 0)
    ) AS avg_credit_income_ratio,

    MAX(
        AMT_CREDIT
        / NULLIF(AMT_INCOME_TOTAL, 0)
    ) AS max_credit_income_ratio

FROM raw.application_train;
GO