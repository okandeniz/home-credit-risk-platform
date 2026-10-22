/* ============================================================
   Project: Home Credit Risk Platform
   Analysis: Credit Card Combined Risk

   Business Question:
       How do credit utilization and delinquency
       relate to payment difficulty together?
   ============================================================ */

USE HomeCreditRisk;
GO

WITH card_segments AS
(
    SELECT
        a.SK_ID_CURR,
        a.TARGET,

        -- Credit utilization segmentation

        CASE
            WHEN cc.AVG_CREDIT_UTILIZATION = 0
                THEN '0%'

            WHEN cc.AVG_CREDIT_UTILIZATION <= 0.50
                THEN '>0% - 50%'

            WHEN cc.AVG_CREDIT_UTILIZATION <= 1.00
                THEN '>50% - 100%'

            ELSE '>100%'
        END AS UTILIZATION_BAND,

        CASE
            WHEN cc.AVG_CREDIT_UTILIZATION = 0 THEN 1
            WHEN cc.AVG_CREDIT_UTILIZATION <= 0.50 THEN 2
            WHEN cc.AVG_CREDIT_UTILIZATION <= 1.00 THEN 3
            ELSE 4
        END AS UTILIZATION_ORDER,

        -- Credit card delinquency segmentation

        CASE
            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE = 0
                THEN '0%'

            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE <= 0.10
                THEN '>0% - 10%'

            ELSE '>10%'
        END AS DELINQUENCY_BAND,

        CASE
            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE = 0 THEN 1
            WHEN cc.CREDIT_CARD_DELINQUENT_MONTH_RATE <= 0.10 THEN 2
            ELSE 3
        END AS DELINQUENCY_ORDER

    FROM core.applications AS a

    INNER JOIN bi.vw_credit_card_summary AS cc
        ON a.SK_ID_CURR = cc.SK_ID_CURR

    WHERE a.DATASET_TYPE = 'TRAIN'

      AND cc.AVG_CREDIT_UTILIZATION IS NOT NULL
      AND cc.AVG_CREDIT_UTILIZATION >= 0

      AND cc.CREDIT_CARD_DELINQUENT_MONTH_RATE IS NOT NULL
)

SELECT
    UTILIZATION_BAND,
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
    ) AS PAYMENT_DIFFICULTY_RATE_PCT

FROM card_segments

GROUP BY
    UTILIZATION_BAND,
    UTILIZATION_ORDER,
    DELINQUENCY_BAND,
    DELINQUENCY_ORDER

ORDER BY
    UTILIZATION_ORDER,
    DELINQUENCY_ORDER;
GO