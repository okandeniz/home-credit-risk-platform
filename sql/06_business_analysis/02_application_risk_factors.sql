/* ============================================================
   Project: Home Credit Risk Platform
   Analysis: Application Risk Factors

   Purpose:
       Compare age and credit burden between
       customers with and without payment difficulties.
   ============================================================ */

USE HomeCreditRisk;
GO

SELECT TOP(5) * FROM core.applications;
GO

/* ============================================================
   1. AGE AND CREDIT BURDEN BY TARGET
   ============================================================ */

SELECT
    
    TARGET,

    COUNT_BIG(*) AS APPLICATION_COUNT,

    CAST(
        AVG(AGE_YEARS)
        AS DECIMAL(10,2)
    ) AS AVG_AGE_YEARS,

    CAST(
        AVG(CREDIT_INCOME_RATIO)
        AS DECIMAL(12,3)
    ) AS AVG_CREDIT_INCOME_RATIO,

    CAST(
        AVG(ANNUITY_INCOME_RATIO)
        AS DECIMAL(12,3)
    ) AS AVG_ANNUITY_INCOME_RATIO

FROM core.applications

WHERE DATASET_TYPE = 'TRAIN'

GROUP BY TARGET

ORDER BY TARGET;
GO


/* ============================================================
   2. MEDIAN AND PERCENTILE ANALYSIS

   Purpose:
       Compare typical values and upper distributions
       between TARGET groups.
   ============================================================ */

SELECT DISTINCT
    TARGET,

    CAST(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY AGE_YEARS)
        OVER (PARTITION BY TARGET)
        AS DECIMAL(10,2)
    ) AS MEDIAN_AGE,

    CAST(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY CREDIT_INCOME_RATIO)
        OVER (PARTITION BY TARGET)
        AS DECIMAL(12,3)
    ) AS MEDIAN_CREDIT_INCOME_RATIO,

    CAST(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY CREDIT_INCOME_RATIO)
        OVER (PARTITION BY TARGET)
        AS DECIMAL(12,3)
    ) AS P90_CREDIT_INCOME_RATIO,

    CAST(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY ANNUITY_INCOME_RATIO)
        OVER (PARTITION BY TARGET)
        AS DECIMAL(12,3)
    ) AS MEDIAN_ANNUITY_INCOME_RATIO

FROM core.applications

WHERE DATASET_TYPE = 'TRAIN'

ORDER BY TARGET;

/* ============================================================
   3. CREDIT / INCOME SEGMENTATION

   Business Question:
       Does payment difficulty increase when the
       credit-to-income ratio becomes higher?

   Population:
       TRAIN applications only.
   ============================================================ */

WITH credit_segments AS
(
    SELECT
        SK_ID_CURR,
        TARGET,
        CREDIT_INCOME_RATIO,

        CASE
            WHEN CREDIT_INCOME_RATIO IS NULL
                THEN 'Unknown'

            WHEN CREDIT_INCOME_RATIO < 2
                THEN '< 2x'

            WHEN CREDIT_INCOME_RATIO < 4
                THEN '2x - 4x'

            WHEN CREDIT_INCOME_RATIO < 6
                THEN '4x - 6x'

            ELSE '6x+'
        END AS CREDIT_INCOME_BAND,

        CASE
            WHEN CREDIT_INCOME_RATIO IS NULL THEN 5
            WHEN CREDIT_INCOME_RATIO < 2 THEN 1
            WHEN CREDIT_INCOME_RATIO < 4 THEN 2
            WHEN CREDIT_INCOME_RATIO < 6 THEN 3
            ELSE 4
        END AS BAND_ORDER

    FROM core.applications

    WHERE DATASET_TYPE = 'TRAIN'
)

SELECT
    CREDIT_INCOME_BAND,

    COUNT_BIG(*) AS APPLICATION_COUNT,

    SUM(
        CASE
            WHEN TARGET = 1 THEN 1
            ELSE 0
        END
    ) AS PAYMENT_DIFFICULTY_COUNT,

    CAST(
        100.0
        * SUM(
            CASE
                WHEN TARGET = 1 THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(10,2)
    ) AS PAYMENT_DIFFICULTY_RATE_PCT

FROM credit_segments

GROUP BY
    CREDIT_INCOME_BAND,
    BAND_ORDER

ORDER BY BAND_ORDER;
GO