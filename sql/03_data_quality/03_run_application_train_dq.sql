USE HomeCreditRisk;
GO


/* ============================================================
   Application Train Data Quality Checks
   ============================================================ */


/* ------------------------------------------------------------
   1. ROW COUNT
   ------------------------------------------------------------ */

DECLARE @row_count BIGINT;

SELECT
    @row_count = COUNT_BIG(*)
FROM raw.application_train;


INSERT INTO etl.data_quality_results
(
    schema_name,
    table_name,
    check_name,
    check_type,
    metric_value,
    threshold_value,
    status,
    details
)
VALUES
(
    'raw',
    'application_train',
    'Expected row count',
    'ROW_COUNT',
    @row_count,
    307511,
    CASE
        WHEN @row_count = 307511
            THEN 'PASS'
        ELSE 'FAIL'
    END,
    'Source application_train.csv contains 307,511 rows.'
);
GO

/* ------------------------------------------------------------
   2. DUPLICATE SK_ID_CURR
   ------------------------------------------------------------ */

DECLARE @duplicate_count BIGINT;

SELECT
    @duplicate_count = COUNT_BIG(*)
FROM
(
    SELECT
        SK_ID_CURR
    FROM raw.application_train
    GROUP BY SK_ID_CURR
    HAVING COUNT_BIG(*) > 1
) AS duplicates;


INSERT INTO etl.data_quality_results
(
    schema_name,
    table_name,
    check_name,
    check_type,
    metric_value,
    threshold_value,
    status,
    details
)
VALUES
(
    'raw',
    'application_train',
    'Duplicate SK_ID_CURR',
    'UNIQUENESS',
    @duplicate_count,
    0,
    CASE
        WHEN @duplicate_count = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END,
    'SK_ID_CURR should uniquely identify each application.'
);
GO

/* ------------------------------------------------------------
   3. NULL SK_ID_CURR
   ------------------------------------------------------------ */

DECLARE @null_customer_id_count BIGINT;

SELECT
    @null_customer_id_count = COUNT_BIG(*)
FROM raw.application_train
WHERE SK_ID_CURR IS NULL;


INSERT INTO etl.data_quality_results
(
    schema_name,
    table_name,
    check_name,
    check_type,
    metric_value,
    threshold_value,
    status,
    details
)
VALUES
(
    'raw',
    'application_train',
    'NULL SK_ID_CURR',
    'COMPLETENESS',
    @null_customer_id_count,
    0,
    CASE
        WHEN @null_customer_id_count = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END,
    'SK_ID_CURR cannot be NULL in the trusted application dataset.'
);
GO


/* ------------------------------------------------------------
   4. INVALID TARGET VALUES
   ------------------------------------------------------------ */

DECLARE @invalid_target_count BIGINT;

SELECT
    @invalid_target_count = COUNT_BIG(*)
FROM raw.application_train
WHERE TARGET IS NULL
   OR TARGET NOT IN (0, 1);


INSERT INTO etl.data_quality_results
(
    schema_name,
    table_name,
    check_name,
    check_type,
    metric_value,
    threshold_value,
    status,
    details
)
VALUES
(
    'raw',
    'application_train',
    'Invalid TARGET values',
    'DOMAIN',
    @invalid_target_count,
    0,
    CASE
        WHEN @invalid_target_count = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END,
    'TARGET must contain only 0 or 1.'
);
GO

/* ------------------------------------------------------------
   5. INVALID INCOME
   ------------------------------------------------------------ */

DECLARE @invalid_income_count BIGINT;

SELECT
    @invalid_income_count = COUNT_BIG(*)
FROM raw.application_train
WHERE AMT_INCOME_TOTAL IS NULL
   OR AMT_INCOME_TOTAL <= 0;


INSERT INTO etl.data_quality_results
(
    schema_name,
    table_name,
    check_name,
    check_type,
    metric_value,
    threshold_value,
    status,
    details
)
VALUES
(
    'raw',
    'application_train',
    'Invalid income values',
    'BUSINESS_RULE',
    @invalid_income_count,
    0,
    CASE
        WHEN @invalid_income_count = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END,
    'AMT_INCOME_TOTAL should be greater than zero.'
);
GO

/* ------------------------------------------------------------
   6. DAYS_EMPLOYED SENTINEL
   ------------------------------------------------------------ */

DECLARE @days_employed_sentinel_count BIGINT;

SELECT
    @days_employed_sentinel_count = COUNT_BIG(*)
FROM raw.application_train
WHERE DAYS_EMPLOYED = 365243;


INSERT INTO etl.data_quality_results
(
    schema_name,
    table_name,
    check_name,
    check_type,
    metric_value,
    threshold_value,
    status,
    details
)
VALUES
(
    'raw',
    'application_train',
    'DAYS_EMPLOYED sentinel values',
    'ANOMALY',
    @days_employed_sentinel_count,
    NULL,
    'INFO',
    '365243 is a known special value and will be handled in the core layer.'
);
GO

/* ------------------------------------------------------------
   7. CODE_GENDER XNA
   ------------------------------------------------------------ */

DECLARE @gender_xna_count BIGINT;

SELECT
    @gender_xna_count = COUNT_BIG(*)
FROM raw.application_train
WHERE CODE_GENDER = 'XNA';


INSERT INTO etl.data_quality_results
(
    schema_name,
    table_name,
    check_name,
    check_type,
    metric_value,
    threshold_value,
    status,
    details
)
VALUES
(
    'raw',
    'application_train',
    'CODE_GENDER XNA values',
    'ANOMALY',
    @gender_xna_count,
    NULL,
    'INFO',
    'XNA will be mapped to Unknown in the core layer.'
);
GO


SELECT
    dq_result_id,
    check_time,
    table_name,
    check_name,
    check_type,
    metric_value,
    threshold_value,
    status,
    details
FROM etl.data_quality_results
WHERE table_name = 'application_train'
ORDER BY dq_result_id;