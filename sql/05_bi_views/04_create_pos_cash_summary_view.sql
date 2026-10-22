USE HomeCreditRisk;
GO

SELECT TOP(5) * FROM core.pos_cash_balance;
GO

CREATE OR ALTER VIEW bi.vw_pos_cash_summary
AS

SELECT
	SK_ID_CURR,

	-- General activity

	COUNT_BIG(*) POS_MONTH_COUNT,

	COUNT(
        DISTINCT SK_ID_PREV
    ) AS POS_CONTRACT_COUNT,

	-- DPD observations

	SUM(
        CASE
            WHEN SK_DPD IS NOT NULL
                THEN 1
            ELSE 0
        END
    ) AS POS_DPD_OBSERVED_MONTH_COUNT,

    -- Delinquency

    SUM(
        CASE
            WHEN SK_DPD > 0
                THEN 1
            ELSE 0
        END
    ) AS POS_DELINQUENT_MONTH_COUNT,

    CAST(
        1.0
        * SUM(
            CASE
                WHEN SK_DPD > 0
                    THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN SK_DPD IS NOT NULL
                        THEN 1
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,6)
    ) AS POS_DELINQUENT_MONTH_RATE,

    MAX(
        SK_DPD
    ) AS MAX_POS_DPD,

    AVG(
        CASE
            WHEN SK_DPD > 0
                THEN CAST(SK_DPD AS FLOAT)
        END
    ) AS AVG_POS_DPD_WHEN_DELINQUENT,

    -- Default-style delinquency

    SUM(
        CASE
            WHEN SK_DPD_DEF > 0
                THEN 1
            ELSE 0
        END
    ) AS POS_DEFAULT_DELINQUENT_MONTH_COUNT,

    -- Installment position

    AVG(
        CNT_INSTALMENT
    ) AS AVG_POS_INSTALLMENT_COUNT,

    AVG(
        CNT_INSTALMENT_FUTURE
    ) AS AVG_POS_FUTURE_INSTALLMENTS

FROM core.pos_cash_balance

GROUP BY SK_ID_CURR;
GO

SELECT TOP (20) *
FROM bi.vw_pos_cash_summary
ORDER BY SK_ID_CURR;

-- Grain control

SELECT
    COUNT_BIG(*) AS total_rows,

    COUNT_BIG(
        DISTINCT SK_ID_CURR
    ) AS unique_customers

FROM bi.vw_pos_cash_summary;

SELECT
    AVG(
        CAST(
            POS_CONTRACT_COUNT
            AS FLOAT
        )
    ) AS avg_pos_contract_count,

    AVG(
        CAST(
            POS_MONTH_COUNT
            AS FLOAT
        )
    ) AS avg_pos_month_count,

    AVG(
        POS_DELINQUENT_MONTH_RATE
    ) AS avg_pos_delinquent_month_rate,

    AVG(
        AVG_POS_DPD_WHEN_DELINQUENT
    ) AS avg_pos_dpd_when_delinquent,

    AVG(
        CAST(
            MAX_POS_DPD
            AS FLOAT
        )
    ) AS avg_customer_max_pos_dpd

FROM bi.vw_pos_cash_summary;