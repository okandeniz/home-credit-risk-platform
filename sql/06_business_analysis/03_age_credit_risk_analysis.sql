/* ============================================================
   Project: Home Credit Risk Platform
   Analysis: Age and Credit-to-Income Segmentation

   Business Question:
       How does payment difficulty change across
       age groups and credit-to-income segments?
   ============================================================ */

USE HomeCreditRisk;
GO

WITH customer_segments AS
(
    SELECT
        
        SK_ID_CURR,
        TARGET,

        -- Age segmentation

        CASE
            WHEN AGE_YEARS < 30 THEN '20-29'
            WHEN AGE_YEARS < 40 THEN '30-39'
            WHEN AGE_YEARS < 50 THEN '40-49'
            ELSE '50+'
        END AS AGE_BAND,

        -- Credit-to-income segmentation

        CASE
            WHEN CREDIT_INCOME_RATIO < 2 THEN '< 2x'
            WHEN CREDIT_INCOME_RATIO < 4 THEN '2x - 4x'
            WHEN CREDIT_INCOME_RATIO < 6 THEN '4x - 6x'
            ELSE '6x+'
        END AS CREDIT_INCOME_BAND

    FROM core.applications

    WHERE DATASET_TYPE = 'TRAIN'
        AND AGE_YEARS IS NOT NULL
        AND CREDIT_INCOME_RATIO IS NOT NULL
)

SELECT
    AGE_BAND,
    CREDIT_INCOME_BAND,

    COUNT_BIG(*) AS APPLICATION_COUNT,

    SUM(
        CASE
            WHEN TARGET = 1 THEN 1
            ELSE 0
        END
    ) AS PAYMENT_DIFFICULTY_COUNT,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN TARGET = 1 THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(10,2)
    ) AS PAYMENT_DIFFICULTY_RATE_PCT

FROM customer_segments

GROUP BY
    AGE_BAND,
    CREDIT_INCOME_BAND

ORDER BY
    CASE AGE_BAND
        WHEN '20-29' THEN 1
        WHEN '30-39' THEN 2
        WHEN '40-49' THEN 3
        ELSE 4
    END,

    CASE CREDIT_INCOME_BAND
        WHEN '< 2x' THEN 1
        WHEN '2x - 4x' THEN 2
        WHEN '4x - 6x' THEN 3
        ELSE 4
    END;
GO