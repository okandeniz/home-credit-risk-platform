USE HomeCreditRisk;
GO

SELECT TOP(5) * FROM core.credit_card_balance;
GO

CREATE OR ALTER VIEW bi.vw_credit_card_summary
AS

SELECT
	SK_ID_CURR,

	-- General activity

	COUNT_BIG(*) AS CREDIT_CARD_MONTH_COUNT,

	COUNT(
        DISTINCT SK_ID_PREV
    ) AS CREDIT_CARD_COUNT,

	-- Balance and credit limit

	AVG(
        AMT_BALANCE
    ) AS AVG_CREDIT_CARD_BALANCE,

	MAX(
        AMT_BALANCE
    ) AS MAX_CREDIT_CARD_BALANCE,

	AVG(
        AMT_CREDIT_LIMIT_ACTUAL
    ) AS AVG_CREDIT_LIMIT,

	-- Credit utilization

	AVG(
		CASE
			WHEN AMT_CREDIT_LIMIT_ACTUAL > 0
				AND AMT_BALANCE IS NOT NULL
			THEN
				AMT_BALANCE
                / AMT_CREDIT_LIMIT_ACTUAL
		END
	) AS AVG_CREDIT_UTILIZATION,

	MAX(
        CASE
            WHEN AMT_CREDIT_LIMIT_ACTUAL > 0
                 AND AMT_BALANCE IS NOT NULL
            THEN
                AMT_BALANCE
                / AMT_CREDIT_LIMIT_ACTUAL
        END
    ) AS MAX_CREDIT_UTILIZATION,

	-- Delinquency

	 SUM(
        CASE
            WHEN SK_DPD IS NOT NULL
                THEN 1
            ELSE 0
        END
    ) AS CREDIT_CARD_DPD_OBSERVED_MONTH_COUNT,

    SUM(
        CASE
            WHEN SK_DPD > 0
                THEN 1
            ELSE 0
        END
    ) AS CREDIT_CARD_DELINQUENT_MONTH_COUNT,

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
    ) AS CREDIT_CARD_DELINQUENT_MONTH_RATE,

    MAX(
        SK_DPD
    ) AS MAX_CREDIT_CARD_DPD,


    AVG(
        CASE
            WHEN SK_DPD > 0
            THEN CAST(
                SK_DPD AS FLOAT
            )
        END
    ) AS AVG_CREDIT_CARD_DPD_WHEN_DELINQUENT


FROM core.credit_card_balance

GROUP BY SK_ID_CURR;
GO

SELECT TOP (20) *
FROM bi.vw_credit_card_summary
ORDER BY SK_ID_CURR;

-- Grain control

SELECT
    COUNT_BIG(*) AS total_rows,

    COUNT_BIG(
        DISTINCT SK_ID_CURR
    ) AS unique_customers

FROM bi.vw_credit_card_summary;

SELECT
    AVG(
        CAST(
            CREDIT_CARD_COUNT
            AS FLOAT
        )
    ) AS avg_credit_card_count,

    AVG(
        CAST(
            CREDIT_CARD_MONTH_COUNT
            AS FLOAT
        )
    ) AS avg_credit_card_month_count,

    AVG(
        AVG_CREDIT_CARD_BALANCE
    ) AS avg_credit_card_balance,

    AVG(
        AVG_CREDIT_UTILIZATION
    ) AS avg_credit_utilization,

    AVG(
        CREDIT_CARD_DELINQUENT_MONTH_RATE
    ) AS avg_credit_card_delinquent_rate,

    AVG(
        AVG_CREDIT_CARD_DPD_WHEN_DELINQUENT
    ) AS avg_credit_card_dpd_when_delinquent

FROM bi.vw_credit_card_summary;