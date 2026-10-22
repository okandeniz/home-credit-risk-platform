/* ============================================================
   Project: Home Credit Risk Platform
   Analysis: Late Payment Risk

   Business Question:
       Does payment difficulty increase when customers
       have more late payments in their history?
   ============================================================ */

USE HomeCreditRisk;
GO

-- Create late payment segments

WITH payment_segments AS
(
    SELECT
        a.SK_ID_CURR,
        a.TARGET,

        i.PAYMENT_EVENT_COUNT,
        i.LATE_PAYMENT_RATE,

        CASE
            WHEN i.SK_ID_CURR IS NULL
                THEN 'No History'

            WHEN i.LATE_PAYMENT_RATE IS NULL
                THEN 'Unknown Timing'

            WHEN i.LATE_PAYMENT_RATE = 0
                THEN '0%'

            WHEN i.LATE_PAYMENT_RATE <= 0.05
                THEN '>0% - 5%'

            WHEN i.LATE_PAYMENT_RATE <= 0.15
                THEN '>5% - 15%'

            ELSE '>15%'
        END AS LATE_PAYMENT_BAND,

        CASE
            WHEN i.SK_ID_CURR IS NULL THEN 1
            WHEN i.LATE_PAYMENT_RATE IS NULL THEN 2
            WHEN i.LATE_PAYMENT_RATE = 0 THEN 3
            WHEN i.LATE_PAYMENT_RATE <= 0.05 THEN 4
            WHEN i.LATE_PAYMENT_RATE <= 0.15 THEN 5
            ELSE 6
        END AS BAND_ORDER

    FROM core.applications AS a

    LEFT JOIN bi.vw_installment_payment_summary AS i
        ON a.SK_ID_CURR = i.SK_ID_CURR

    WHERE a.DATASET_TYPE = 'TRAIN'
)

-- Calculate payment difficulty rates

SELECT
    LATE_PAYMENT_BAND,

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
    ) AS PAYMENT_DIFFICULTY_RATE_PCT,

    CAST(
        AVG(
            CAST(PAYMENT_EVENT_COUNT AS FLOAT)
        )
        AS DECIMAL(10,2)
    ) AS AVG_PAYMENT_EVENT_COUNT

FROM payment_segments

GROUP BY
    LATE_PAYMENT_BAND,
    BAND_ORDER

ORDER BY BAND_ORDER;
GO