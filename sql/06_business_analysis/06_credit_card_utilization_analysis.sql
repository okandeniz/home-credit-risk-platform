/* ============================================================
   Project: Home Credit Risk Platform
   Analysis: Credit Card Utilization

   Business Question:
       Does payment difficulty change across
       credit card utilization segments?
   ============================================================ */

USE HomeCreditRisk;
GO

-- Create utilization segments

WITH card_segments AS
(
    SELECT
        a.SK_ID_CURR,
        a.TARGET,

        cc.CREDIT_CARD_MONTH_COUNT,
        cc.AVG_CREDIT_UTILIZATION,

        CASE
            WHEN cc.SK_ID_CURR IS NULL
                THEN 'No History'

            WHEN cc.AVG_CREDIT_UTILIZATION IS NULL
                THEN 'Unknown Utilization'

            WHEN cc.AVG_CREDIT_UTILIZATION < 0
                THEN 'Negative'

            WHEN cc.AVG_CREDIT_UTILIZATION = 0
                THEN '0%'

            WHEN cc.AVG_CREDIT_UTILIZATION <= 0.25
                THEN '>0% - 25%'

            WHEN cc.AVG_CREDIT_UTILIZATION <= 0.50
                THEN '>25% - 50%'

            WHEN cc.AVG_CREDIT_UTILIZATION <= 0.75
                THEN '>50% - 75%'

            WHEN cc.AVG_CREDIT_UTILIZATION <= 1.00
                THEN '>75% - 100%'

            ELSE '>100%'
        END AS UTILIZATION_BAND,

        CASE
            WHEN cc.SK_ID_CURR IS NULL THEN 1
            WHEN cc.AVG_CREDIT_UTILIZATION IS NULL THEN 2
            WHEN cc.AVG_CREDIT_UTILIZATION < 0 THEN 3
            WHEN cc.AVG_CREDIT_UTILIZATION = 0 THEN 4
            WHEN cc.AVG_CREDIT_UTILIZATION <= 0.25 THEN 5
            WHEN cc.AVG_CREDIT_UTILIZATION <= 0.50 THEN 6
            WHEN cc.AVG_CREDIT_UTILIZATION <= 0.75 THEN 7
            WHEN cc.AVG_CREDIT_UTILIZATION <= 1.00 THEN 8
            ELSE 9
        END AS BAND_ORDER

    FROM core.applications AS a

    LEFT JOIN bi.vw_credit_card_summary AS cc
        ON a.SK_ID_CURR = cc.SK_ID_CURR

    WHERE a.DATASET_TYPE = 'TRAIN'
)

-- Payment difficulty by utilization band

SELECT
    UTILIZATION_BAND,

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
    ) AS PAYMENT_DIFFICULTY_RATE_PCT,

    CAST(
        AVG(
            CAST(CREDIT_CARD_MONTH_COUNT AS FLOAT)
        )
        AS DECIMAL(12,2)
    ) AS AVG_CREDIT_CARD_MONTH_COUNT

FROM card_segments

GROUP BY
    UTILIZATION_BAND,
    BAND_ORDER

ORDER BY BAND_ORDER;
GO