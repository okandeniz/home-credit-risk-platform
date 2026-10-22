USE HomeCreditRisk;
GO

SELECT TOP(5) * FROM core.previous_applications;
GO

CREATE OR ALTER VIEW bi.vw_previous_application_summary
AS

SELECT
	SK_ID_CURR,

	COUNT_BIG(*) AS PREVIOUS_APPLICATION_COUNT,

	SUM(
        CASE
            WHEN NAME_CONTRACT_STATUS = 'Approved'
                THEN 1
            ELSE 0
        END
    ) AS PREVIOUS_APPROVED_COUNT,

    SUM(
        CASE
            WHEN NAME_CONTRACT_STATUS = 'Refused'
                THEN 1
            ELSE 0
        END
    ) AS PREVIOUS_REFUSED_COUNT,

    CAST(
        1.0
        * SUM(
            CASE
                WHEN NAME_CONTRACT_STATUS = 'Approved'
                    THEN 1
                ELSE 0
            END
        )
        / NULLIF(
            COUNT_BIG(*),
            0
        )
        AS DECIMAL(10,6)
    ) AS PREVIOUS_APPROVAL_RATE,

    AVG(
        AMT_APPLICATION
    ) AS AVG_PREVIOUS_APPLICATION_AMOUNT,

    AVG(
        AMT_CREDIT
    ) AS AVG_PREVIOUS_CREDIT_AMOUNT,

    MAX(
        AMT_CREDIT
    ) AS MAX_PREVIOUS_CREDIT_AMOUNT,

    ABS(
        MAX(DAYS_DECISION)
    ) AS DAYS_SINCE_LAST_PREVIOUS_APPLICATION

FROM core.previous_applications

GROUP BY SK_ID_CURR;
GO

SELECT
    COUNT_BIG(*) AS total_rows,

    COUNT_BIG(
        DISTINCT SK_ID_CURR
    ) AS unique_customers

FROM bi.vw_previous_application_summary;

SELECT
    AVG(
        CAST(
            PREVIOUS_APPLICATION_COUNT
            AS FLOAT
        )
    ) AS avg_previous_application_count,

    AVG(
        CAST(
            PREVIOUS_APPROVED_COUNT
            AS FLOAT
        )
    ) AS avg_previous_approved_count,

    AVG(
        CAST(
            PREVIOUS_REFUSED_COUNT
            AS FLOAT
        )
    ) AS avg_previous_refused_count,

    AVG(
        PREVIOUS_APPROVAL_RATE
    ) AS avg_previous_approval_rate,

    AVG(
        AVG_PREVIOUS_CREDIT_AMOUNT
    ) AS avg_previous_credit_amount

FROM bi.vw_previous_application_summary;