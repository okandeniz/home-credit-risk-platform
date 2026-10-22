USE HomeCreditRisk;
GO

SELECT TOP(5) * FROM core.bureau;
GO

CREATE OR ALTER VIEW bi.vw_bureau_customer_summary
AS

SELECT
	SK_ID_CURR,

	COUNT_BIG(*) AS BUREAU_CREDIT_COUNT,

	SUM(
		CASE
			WHEN CREDIT_ACTIVE = 'Active' THEN 1
			ELSE 0
		END
	) AS ACTIVE_BUREAU_CREDIT_COUNT,

	SUM(
        CASE
            WHEN CREDIT_ACTIVE = 'Closed'
                THEN 1
            ELSE 0
        END
    ) AS CLOSED_BUREAU_CREDIT_COUNT,

	SUM(
		COALESCE(
			AMT_CREDIT_SUM,
			0
		)
	) AS TOTAL_BUREAU_CREDIT,

	SUM(
        COALESCE(
            AMT_CREDIT_SUM_DEBT,
            0
        )
    ) AS TOTAL_BUREAU_DEBT,

	SUM(
        COALESCE(
            AMT_CREDIT_SUM_OVERDUE,
            0
        )
    ) AS TOTAL_BUREAU_OVERDUE,

	MAX(
        CREDIT_DAY_OVERDUE
    ) AS MAX_CREDIT_DAY_OVERDUE,

	ABS(
		MAX(DAYS_CREDIT)
	) AS DAYS_SINCE_MOST_RECENT_BUREAU_CREDIT,

	CAST(
		SUM(
			COALESCE(
				AMT_CREDIT_SUM_DEBT,
				0
			)
		)
		/
		NULLIF(
			SUM(
				COALESCE(
					AMT_CREDIT_SUM,
					0
				)
			),
			0
		)
		AS DECIMAL(19,6)
	) AS BUREAU_DEBT_CREDIT_RATIO

FROM core.bureau

GROUP BY SK_ID_CURR;
GO

SELECT TOP (20) *
FROM bi.vw_bureau_customer_summary
ORDER BY SK_ID_CURR;

-- Grain Control

SELECT
	COUNT_BIG(*) AS total_rows,
	COUNT_BIG(DISTINCT SK_ID_CURR) AS unique_customers
FROM bi.vw_bureau_customer_summary;

-- General distribution among clients with a bureau history.

SELECT
    AVG(
        CAST(BUREAU_CREDIT_COUNT AS FLOAT)
    ) AS avg_bureau_credit_count,

    AVG(
        CAST(ACTIVE_BUREAU_CREDIT_COUNT AS FLOAT)
    ) AS avg_active_credit_count,

    AVG(
        TOTAL_BUREAU_DEBT
    ) AS avg_bureau_debt,

    AVG(
        BUREAU_DEBT_CREDIT_RATIO
    ) AS avg_debt_credit_ratio

FROM bi.vw_bureau_customer_summary;