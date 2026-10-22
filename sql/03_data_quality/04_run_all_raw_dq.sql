USE HomeCreditRisk;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;


DECLARE @dq_run_id BIGINT;


BEGIN TRY

    /* ========================================================
       START DATA QUALITY RUN
       ======================================================== */

    INSERT INTO etl.data_quality_runs
    (
        run_name,
        run_status,
        notes
    )
    VALUES
    (
        'Full RAW Data Quality Check',
        'RUNNING',
        'Structural and relational checks for all Home Credit RAW tables.'
    );

    SET @dq_run_id = SCOPE_IDENTITY();

    /* ========================================================
       1. ROW COUNT CHECKS
       ======================================================== */

    WITH expected_counts AS
    (
        SELECT *
        FROM
        (
            VALUES
                ('application_train', CAST(307511 AS BIGINT)),
                ('application_test', CAST(48744 AS BIGINT)),
                ('bureau', CAST(1716428 AS BIGINT)),
                ('bureau_balance', CAST(27299925 AS BIGINT)),
                ('previous_application', CAST(1670214 AS BIGINT)),
                ('pos_cash_balance', CAST(10001358 AS BIGINT)),
                ('credit_card_balance', CAST(3840312 AS BIGINT)),
                ('installments_payments', CAST(13605401 AS BIGINT))
        ) AS v(table_name, expected_count)
    ),
    actual_counts AS
    (
        SELECT
            'application_train' AS table_name,
            COUNT_BIG(*) AS actual_count
        FROM raw.application_train

        UNION ALL

        SELECT
            'application_test',
            COUNT_BIG(*)
        FROM raw.application_test

        UNION ALL

        SELECT
            'bureau',
            COUNT_BIG(*)
        FROM raw.bureau

        UNION ALL

        SELECT
            'bureau_balance',
            COUNT_BIG(*)
        FROM raw.bureau_balance

        UNION ALL

        SELECT
            'previous_application',
            COUNT_BIG(*)
        FROM raw.previous_application

        UNION ALL

        SELECT
            'pos_cash_balance',
            COUNT_BIG(*)
        FROM raw.pos_cash_balance

        UNION ALL

        SELECT
            'credit_card_balance',
            COUNT_BIG(*)
        FROM raw.credit_card_balance

        UNION ALL

        SELECT
            'installments_payments',
            COUNT_BIG(*)
        FROM raw.installments_payments
    )

    INSERT INTO etl.data_quality_results
    (
        dq_run_id,
        schema_name,
        table_name,
        check_name,
        check_type,
        metric_value,
        threshold_value,
        status,
        details
    )
    SELECT
        @dq_run_id,
        'raw',
        a.table_name,
        'Expected row count',
        'ROW_COUNT',
        a.actual_count,
        e.expected_count,

        CASE
            WHEN a.actual_count = e.expected_count
                THEN 'PASS'
            ELSE 'FAIL'
        END,

        'SQL row count must match the source CSV inventory.'

    FROM actual_counts AS a

    INNER JOIN expected_counts AS e
        ON a.table_name = e.table_name;

    /* ========================================================
       2. NULL KEY CHECKS
       ======================================================== */

    WITH key_nulls AS
    (
        SELECT
            'application_train' AS table_name,
            COUNT_BIG(*) AS null_count
        FROM raw.application_train
        WHERE SK_ID_CURR IS NULL

        UNION ALL

        SELECT
            'application_test',
            COUNT_BIG(*)
        FROM raw.application_test
        WHERE SK_ID_CURR IS NULL

        UNION ALL

        SELECT
            'bureau',
            COUNT_BIG(*)
        FROM raw.bureau
        WHERE SK_ID_BUREAU IS NULL

        UNION ALL

        SELECT
            'bureau_balance',
            COUNT_BIG(*)
        FROM raw.bureau_balance
        WHERE
            SK_ID_BUREAU IS NULL
            OR MONTHS_BALANCE IS NULL

        UNION ALL

        SELECT
            'previous_application',
            COUNT_BIG(*)
        FROM raw.previous_application
        WHERE SK_ID_PREV IS NULL

        UNION ALL

        SELECT
            'pos_cash_balance',
            COUNT_BIG(*)
        FROM raw.pos_cash_balance
        WHERE
            SK_ID_PREV IS NULL
            OR MONTHS_BALANCE IS NULL

        UNION ALL

        SELECT
            'credit_card_balance',
            COUNT_BIG(*)
        FROM raw.credit_card_balance
        WHERE
            SK_ID_PREV IS NULL
            OR MONTHS_BALANCE IS NULL

        UNION ALL

        SELECT
            'installments_payments',
            COUNT_BIG(*)
        FROM raw.installments_payments
        WHERE
            SK_ID_PREV IS NULL
            OR SK_ID_CURR IS NULL
    )

    INSERT INTO etl.data_quality_results
    (
        dq_run_id,
        schema_name,
        table_name,
        check_name,
        check_type,
        metric_value,
        threshold_value,
        status,
        details
    )
    SELECT
        @dq_run_id,
        'raw',
        table_name,
        'NULL key values',
        'COMPLETENESS',
        null_count,
        0,

        CASE
            WHEN null_count = 0
                THEN 'PASS'
            ELSE 'FAIL'
        END,

        'Key columns should not contain NULL values.'

    FROM key_nulls;

    /* ========================================================
       3. DUPLICATE KEY CHECKS
       ======================================================== */

    WITH duplicate_checks AS
    (
        SELECT
            'application_train' AS table_name,
            COUNT_BIG(*) AS duplicate_group_count
        FROM
        (
            SELECT SK_ID_CURR
            FROM raw.application_train
            GROUP BY SK_ID_CURR
            HAVING COUNT_BIG(*) > 1
        ) AS d

        UNION ALL

        SELECT
            'application_test',
            COUNT_BIG(*)
        FROM
        (
            SELECT SK_ID_CURR
            FROM raw.application_test
            GROUP BY SK_ID_CURR
            HAVING COUNT_BIG(*) > 1
        ) AS d

        UNION ALL

        SELECT
            'bureau',
            COUNT_BIG(*)
        FROM
        (
            SELECT SK_ID_BUREAU
            FROM raw.bureau
            GROUP BY SK_ID_BUREAU
            HAVING COUNT_BIG(*) > 1
        ) AS d

        UNION ALL

        SELECT
            'bureau_balance',
            COUNT_BIG(*)
        FROM
        (
            SELECT
                SK_ID_BUREAU,
                MONTHS_BALANCE
            FROM raw.bureau_balance
            GROUP BY
                SK_ID_BUREAU,
                MONTHS_BALANCE
            HAVING COUNT_BIG(*) > 1
        ) AS d

        UNION ALL

        SELECT
            'previous_application',
            COUNT_BIG(*)
        FROM
        (
            SELECT SK_ID_PREV
            FROM raw.previous_application
            GROUP BY SK_ID_PREV
            HAVING COUNT_BIG(*) > 1
        ) AS d

        UNION ALL

        SELECT
            'pos_cash_balance',
            COUNT_BIG(*)
        FROM
        (
            SELECT
                SK_ID_PREV,
                MONTHS_BALANCE
            FROM raw.pos_cash_balance
            GROUP BY
                SK_ID_PREV,
                MONTHS_BALANCE
            HAVING COUNT_BIG(*) > 1
        ) AS d

        UNION ALL

        SELECT
            'credit_card_balance',
            COUNT_BIG(*)
        FROM
        (
            SELECT
                SK_ID_PREV,
                MONTHS_BALANCE
            FROM raw.credit_card_balance
            GROUP BY
                SK_ID_PREV,
                MONTHS_BALANCE
            HAVING COUNT_BIG(*) > 1
        ) AS d
    )

    INSERT INTO etl.data_quality_results
    (
        dq_run_id,
        schema_name,
        table_name,
        check_name,
        check_type,
        metric_value,
        threshold_value,
        status,
        details
    )
    SELECT
        @dq_run_id,
        'raw',
        table_name,
        'Duplicate candidate key groups',
        'UNIQUENESS',
        duplicate_group_count,
        0,

        CASE
            WHEN duplicate_group_count = 0
                THEN 'PASS'
            ELSE 'FAIL'
        END,

        'Validated candidate primary or composite key.'

    FROM duplicate_checks;


    INSERT INTO etl.data_quality_results
    (
        dq_run_id,
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
        @dq_run_id,
        'raw',
        'installments_payments',
        'Natural primary key',
        'KEY_PROFILE',
        NULL,
        NULL,
        'INFO',
        'No reliable natural unique key was found. A surrogate key will be used in the core layer.'
    );

    /* ========================================================
       4. PREPARE PARENT ID TABLES
       ======================================================== */

    DROP TABLE IF EXISTS #application_ids;
    DROP TABLE IF EXISTS #bureau_ids;
    DROP TABLE IF EXISTS #previous_ids;


    SELECT SK_ID_CURR
    INTO #application_ids
    FROM raw.application_train

    UNION ALL

    SELECT SK_ID_CURR
    FROM raw.application_test;


    CREATE UNIQUE CLUSTERED INDEX
        IX_application_ids
    ON #application_ids(SK_ID_CURR);


    SELECT SK_ID_BUREAU
    INTO #bureau_ids
    FROM raw.bureau;


    CREATE UNIQUE CLUSTERED INDEX
        IX_bureau_ids
    ON #bureau_ids(SK_ID_BUREAU);


    SELECT SK_ID_PREV
    INTO #previous_ids
    FROM raw.previous_application;


    CREATE UNIQUE CLUSTERED INDEX
        IX_previous_ids
    ON #previous_ids(SK_ID_PREV);

    /* ========================================================
       5. REFERENTIAL INTEGRITY CHECKS
       ======================================================== */

    WITH orphan_checks AS
    (
        SELECT
            'bureau' AS table_name,
            'applications -> bureau'
                AS relationship_name,
            COUNT_BIG(*) AS orphan_count
        FROM raw.bureau AS b

        LEFT JOIN #application_ids AS a
            ON b.SK_ID_CURR = a.SK_ID_CURR

        WHERE a.SK_ID_CURR IS NULL


        UNION ALL


        SELECT
            'bureau_balance',
            'bureau -> bureau_balance',
            COUNT_BIG(*)
        FROM raw.bureau_balance AS bb

        LEFT JOIN #bureau_ids AS b
            ON bb.SK_ID_BUREAU = b.SK_ID_BUREAU

        WHERE b.SK_ID_BUREAU IS NULL


        UNION ALL


        SELECT
            'previous_application',
            'applications -> previous_application',
            COUNT_BIG(*)
        FROM raw.previous_application AS p

        LEFT JOIN #application_ids AS a
            ON p.SK_ID_CURR = a.SK_ID_CURR

        WHERE a.SK_ID_CURR IS NULL


        UNION ALL


        SELECT
            'pos_cash_balance',
            'previous_application -> POS_CASH',
            COUNT_BIG(*)
        FROM raw.pos_cash_balance AS p

        LEFT JOIN #previous_ids AS pa
            ON p.SK_ID_PREV = pa.SK_ID_PREV

        WHERE pa.SK_ID_PREV IS NULL


        UNION ALL


        SELECT
            'credit_card_balance',
            'previous_application -> credit_card',
            COUNT_BIG(*)
        FROM raw.credit_card_balance AS c

        LEFT JOIN #previous_ids AS pa
            ON c.SK_ID_PREV = pa.SK_ID_PREV

        WHERE pa.SK_ID_PREV IS NULL


        UNION ALL


        SELECT
            'installments_payments',
            'previous_application -> installments',
            COUNT_BIG(*)
        FROM raw.installments_payments AS i

        LEFT JOIN #previous_ids AS pa
            ON i.SK_ID_PREV = pa.SK_ID_PREV

        WHERE pa.SK_ID_PREV IS NULL
    )

    INSERT INTO etl.data_quality_results
    (
        dq_run_id,
        schema_name,
        table_name,
        check_name,
        check_type,
        metric_value,
        threshold_value,
        status,
        details
    )
    SELECT
        @dq_run_id,
        'raw',
        table_name,
        relationship_name,
        'REFERENTIAL_INTEGRITY',
        orphan_count,
        0,

        CASE
            WHEN orphan_count = 0
                THEN 'PASS'
            ELSE 'WARN'
        END,

        'WARN means the source contains child rows without a matching parent record.'

    FROM orphan_checks;

    /* ========================================================
       COMPLETE RUN
       ======================================================== */

    UPDATE etl.data_quality_runs
    SET
        finished_at = SYSDATETIME(),
        run_status = 'COMPLETED',
        notes = 'Full RAW structural and relational data quality checks completed.'
    WHERE dq_run_id = @dq_run_id;


END TRY


BEGIN CATCH

    UPDATE etl.data_quality_runs
    SET
        finished_at = SYSDATETIME(),
        run_status = 'FAILED',
        notes = ERROR_MESSAGE()
    WHERE dq_run_id = @dq_run_id;

    THROW;

END CATCH;
GO


DECLARE @latest_run_id BIGINT;

SELECT
    @latest_run_id = MAX(dq_run_id)
FROM etl.data_quality_runs;


SELECT
    dq_run_id,
    run_name,
    started_at,
    finished_at,
    run_status,
    notes
FROM etl.data_quality_runs
WHERE dq_run_id = @latest_run_id;


SELECT
    table_name,
    check_name,
    check_type,
    metric_value,
    threshold_value,
    status
FROM etl.data_quality_results
WHERE dq_run_id = @latest_run_id
ORDER BY
    table_name,
    check_type,
    check_name;


SELECT
    status,
    COUNT(*) AS check_count
FROM etl.data_quality_results
WHERE dq_run_id = @latest_run_id
GROUP BY status
ORDER BY status;