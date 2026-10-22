/* ============================================================
   Project: Home Credit Risk Platform
   Analysis: Credit Card Delinquency Risk

   Business Question:
       Does payment difficulty increase when customers
       have more delinquent credit card months?
   ============================================================ */

USE HomeCreditRisk;
GO

-- Create delinquency segments

WITH card_segments AS
(
    SELECT
        a.SK_ID_CURR,
        a.TARGET,

        cc.CREDIT_CARD_MONTH_COUNT,
        cc.CREDIT_CARD_DELINQUENT_MONTH_RATE,

        CASE
            WHEN cc.SK_ID_CURR IS NULL
                THEN 'No History'

            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE IS NULL
                THEN 'Unknown DPD'

            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE = 0
                THEN '0%'

            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE <= 0.02
                THEN '>0% - 2%'

            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE <= 0.10
                THEN '>2% - 10%'

            ELSE '>10%'
        END AS DELINQUENCY_BAND,

        CASE
            WHEN cc.SK_ID_CURR IS NULL THEN 1
            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE IS NULL THEN 2
            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE = 0 THEN 3
            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE <= 0.02 THEN 4
            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE <= 0.10 THEN 5
            ELSE 6
        END AS BAND_ORDER

    FROM core.applications AS a

    LEFT JOIN bi.vw_credit_card_summary AS cc
        ON a.SK_ID_CURR = cc.SK_ID_CURR

    WHERE a.DATASET_TYPE = 'TRAIN'
)

-- Payment difficultly by delinquency band

SELECT
    DELINQUENCY_BAND,

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
            CAST(CREDIT_CARD_MONTH_COUNT AS FLOAT)
        )
        AS DECIMAL(12,2)
    ) AS AVG_CREDIT_CARD_MONTH_COUNT


FROM card_segments

GROUP BY
    DELINQUENCY_BAND,
    BAND_ORDER

ORDER BY BAND_ORDER;
GO