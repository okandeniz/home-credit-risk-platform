/* ============================================================
   Project: Home Credit Risk Platform
   Analysis: POS/CASH Delinquency Risk

   Business Question:
       Does payment difficulty increase when customers
       have more delinquent POS/CASH monthly records?
   ============================================================ */

USE HomeCreditRisk;
GO

-- Create Delinquency segments

WITH pos_segments AS
(
    SELECT
        a.SK_ID_CURR,
        a.TARGET,

        p.POS_MONTH_COUNT,
        p.POS_DELINQUENT_MONTH_RATE,

        CASE
            WHEN p.SK_ID_CURR IS NULL
                THEN 'No History'

            WHEN p.POS_DELINQUENT_MONTH_RATE IS NULL
                THEN 'Unknown DPD'

            WHEN p.POS_DELINQUENT_MONTH_RATE = 0
                THEN '0%'

            WHEN p.POS_DELINQUENT_MONTH_RATE <= 0.02
                THEN '>0% - 2%'

            WHEN p.POS_DELINQUENT_MONTH_RATE <= 0.10
                THEN '>2% - 10%'

            ELSE '>10%'
        END AS POS_DELINQUENCY_BAND,

        CASE
            WHEN p.SK_ID_CURR IS NULL THEN 1
            WHEN p.POS_DELINQUENT_MONTH_RATE IS NULL THEN 2
            WHEN p.POS_DELINQUENT_MONTH_RATE = 0 THEN 3
            WHEN p.POS_DELINQUENT_MONTH_RATE <= 0.02 THEN 4
            WHEN p.POS_DELINQUENT_MONTH_RATE <= 0.10 THEN 5
            ELSE 6
        END AS BAND_ORDER

    FROM core.applications AS a

    LEFT JOIN bi.vw_pos_cash_summary AS p
        ON a.SK_ID_CURR = p.SK_ID_CURR

    WHERE a.DATASET_TYPE = 'TRAIN'
)

-- Calculate payment difficulty by segment
SELECT
    POS_DELINQUENCY_BAND,

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
            CAST(POS_MONTH_COUNT AS FLOAT)
        )
        AS DECIMAL(12,2)
    ) AS AVG_POS_MONTH_COUNT

FROM pos_segments

GROUP BY
    POS_DELINQUENCY_BAND,
    BAND_ORDER

ORDER BY BAND_ORDER;
GO

-- Historical payment behavior may be more useful for credit risk prediction than the credit-to-income ratio alone.