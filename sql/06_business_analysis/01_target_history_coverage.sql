/* ============================================================
   Project: Home Credit Risk Platform
   File: 01_target_history_coverage.sql

   Purpose:
       Compare historical data coverage between
       non-default and default customers.

   Grain:
       One row in the source view = one customer.
   ============================================================ */

USE HomeCreditRisk;
GO

SELECT
    TOP(5) *
FROM bi.vw_applicant_overview;
GO


SELECT
    TARGET,

    COUNT_BIG(*) AS CUSTOMER_COUNT,

    CAST(
        AVG(
            CASE
                WHEN BUREAU_CREDIT_COUNT > 0
                    THEN 1.0
                ELSE 0.0
            END
        )
        AS DECIMAL(10,6)
    ) AS BUREAU_COVERAGE_RATE,

    CAST(
        AVG(
            CASE
                WHEN PREVIOUS_APPLICATION_COUNT > 0
                    THEN 1.0
                ELSE 0.0
            END
        )
        AS DECIMAL(10,6)
    ) AS PREVIOUS_APPLICATION_COVERAGE_RATE,

    CAST(
        AVG(
            CASE
                WHEN PAYMENT_EVENT_COUNT > 0
                    THEN 1.0
                ELSE 0.0
            END
        )
        AS DECIMAL(10,6)
    ) AS INSTALLMENT_COVERAGE_RATE,

    CAST(
        AVG(
            CASE
                WHEN POS_CONTRACT_COUNT > 0
                    THEN 1.0
                ELSE 0.0
            END
        )
        AS DECIMAL(10,6)
    ) AS POS_COVERAGE_RATE,

    CAST(
        AVG(
            CASE
                WHEN CREDIT_CARD_COUNT > 0
                    THEN 1.0
                ELSE 0.0
            END
        )
        AS DECIMAL(10,6)
    ) AS CREDIT_CARD_COVERAGE_RATE

FROM bi.vw_applicant_overview

WHERE DATASET_TYPE = 'TRAIN'

GROUP BY TARGET

ORDER BY TARGET;
GO