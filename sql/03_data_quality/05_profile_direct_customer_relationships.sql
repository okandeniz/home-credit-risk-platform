USE HomeCreditRisk;
GO

SET NOCOUNT ON;


/* ============================================================
   Prepare all known application/customer IDs
   ============================================================ */

DROP TABLE IF EXISTS #application_ids;

SELECT
    SK_ID_CURR
INTO #application_ids
FROM raw.application_train

UNION ALL

SELECT
    SK_ID_CURR
FROM raw.application_test;


CREATE UNIQUE CLUSTERED INDEX IX_application_ids
    ON #application_ids(SK_ID_CURR);


/* ============================================================
   1. POS/CASH -> APPLICATIONS
   ============================================================ */

SELECT
    'pos_cash_balance' AS table_name,
    COUNT_BIG(*) AS total_rows,

    SUM(
        CASE
            WHEN a.SK_ID_CURR IS NULL THEN 1
            ELSE 0
        END
    ) AS orphan_customer_rows

FROM raw.pos_cash_balance AS p

LEFT JOIN #application_ids AS a
    ON p.SK_ID_CURR = a.SK_ID_CURR;


/* ============================================================
   2. CREDIT CARD -> APPLICATIONS
   ============================================================ */

SELECT
    'credit_card_balance' AS table_name,
    COUNT_BIG(*) AS total_rows,

    SUM(
        CASE
            WHEN a.SK_ID_CURR IS NULL THEN 1
            ELSE 0
        END
    ) AS orphan_customer_rows

FROM raw.credit_card_balance AS c

LEFT JOIN #application_ids AS a
    ON c.SK_ID_CURR = a.SK_ID_CURR;


/* ============================================================
   3. INSTALLMENTS -> APPLICATIONS
   ============================================================ */

SELECT
    'installments_payments' AS table_name,
    COUNT_BIG(*) AS total_rows,

    SUM(
        CASE
            WHEN a.SK_ID_CURR IS NULL THEN 1
            ELSE 0
        END
    ) AS orphan_customer_rows

FROM raw.installments_payments AS i

LEFT JOIN #application_ids AS a
    ON i.SK_ID_CURR = a.SK_ID_CURR;
GO