USE HomeCreditRisk;
GO

SELECT TOP(5) * FROM core.installments_payments;
GO

CREATE OR ALTER VIEW bi.vw_installment_payment_summary
AS

SELECT
	SK_ID_CURR,

	COUNT_BIG(*) AS PAYMENT_EVENT_COUNT,

	-- payment timing

	SUM(
		CASE
			WHEN DAYS_INSTALMENT IS NOT NULL
				AND DAYS_ENTRY_PAYMENT IS NOT NULL
				THEN 1
			ELSE 0
		END
	) AS PAYMENT_TIMING_OBSERVED_COUNT,

	SUM(
        CASE
            WHEN DAYS_ENTRY_PAYMENT > DAYS_INSTALMENT
                THEN 1
            ELSE 0
        END
    ) AS LATE_PAYMENT_COUNT,

	SUM(
        CASE
            WHEN DAYS_ENTRY_PAYMENT = DAYS_INSTALMENT
                THEN 1
            ELSE 0
        END
    ) AS ON_TIME_PAYMENT_COUNT,

	SUM(
        CASE
            WHEN DAYS_ENTRY_PAYMENT < DAYS_INSTALMENT
                THEN 1
            ELSE 0
        END
    ) AS EARLY_PAYMENT_COUNT,

    CAST(
        1.0
        * SUM(
            CASE
                WHEN DAYS_ENTRY_PAYMENT > DAYS_INSTALMENT
                    THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN DAYS_INSTALMENT IS NOT NULL
                         AND DAYS_ENTRY_PAYMENT IS NOT NULL
                        THEN 1
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,6)
    ) AS LATE_PAYMENT_RATE,

    AVG(
        CASE
            WHEN DAYS_ENTRY_PAYMENT > DAYS_INSTALMENT
                THEN DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT
        END
    ) AS AVG_LATE_PAYMENT_DAYS,


    MAX(
        CASE
            WHEN DAYS_ENTRY_PAYMENT > DAYS_INSTALMENT
                THEN DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT
        END
    ) AS MAX_LATE_PAYMENT_DAYS,

    -- Payment Amount

    SUM(
        CASE
            WHEN AMT_INSTALMENT IS NOT NULL
                 AND AMT_PAYMENT IS NOT NULL
                THEN 1
            ELSE 0
        END
    ) AS PAYMENT_AMOUNT_OBSERVED_COUNT,

    SUM(
        CASE
            WHEN AMT_PAYMENT < AMT_INSTALMENT
                THEN 1
            ELSE 0
        END
    ) AS UNDERPAYMENT_COUNT,

    CAST(
        1.0
        * SUM(
            CASE
                WHEN AMT_PAYMENT < AMT_INSTALMENT
                    THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN AMT_INSTALMENT IS NOT NULL
                         AND AMT_PAYMENT IS NOT NULL
                        THEN 1
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,6)
    ) AS UNDERPAYMENT_RATE,

    SUM(
        COALESCE(
            AMT_INSTALMENT,
            0
        )
    ) AS TOTAL_EXPECTED_PAYMENT,


    SUM(
        COALESCE(
            AMT_PAYMENT,
            0
        )
    ) AS TOTAL_ACTUAL_PAYMENT,

    SUM(
        CASE
            WHEN AMT_INSTALMENT > AMT_PAYMENT
                THEN AMT_INSTALMENT - AMT_PAYMENT
            ELSE 0
        END
    ) AS TOTAL_PAYMENT_SHORTFALL

FROM core.installments_payments

GROUP BY SK_ID_CURR;
GO

SELECT TOP (20) *
FROM bi.vw_installment_payment_summary
ORDER BY SK_ID_CURR;

-- Grain control

SELECT
    COUNT_BIG(*) AS total_rows,

    COUNT_BIG(
        DISTINCT SK_ID_CURR
    ) AS unique_customers

FROM bi.vw_installment_payment_summary;


SELECT
    AVG(
        CAST(
            PAYMENT_EVENT_COUNT
            AS FLOAT
        )
    ) AS avg_payment_event_count,

    AVG(
        LATE_PAYMENT_RATE
    ) AS avg_late_payment_rate,

    AVG(
        CAST(
            AVG_LATE_PAYMENT_DAYS
            AS FLOAT
        )
    ) AS avg_late_payment_days,

    AVG(
        UNDERPAYMENT_RATE
    ) AS avg_underpayment_rate,

    AVG(
        TOTAL_PAYMENT_SHORTFALL
    ) AS avg_payment_shortfall

FROM bi.vw_installment_payment_summary;