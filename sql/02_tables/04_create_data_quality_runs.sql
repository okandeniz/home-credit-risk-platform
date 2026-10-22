USE HomeCreditRisk;
GO


/* ============================================================
   1. DATA QUALITY RUN TABLE
   ============================================================ */

IF OBJECT_ID(
    N'etl.data_quality_runs',
    N'U'
) IS NULL
BEGIN
    CREATE TABLE etl.data_quality_runs
    (
        dq_run_id BIGINT IDENTITY(1,1) NOT NULL,

        run_name VARCHAR(255) NOT NULL,

        started_at DATETIME2(3) NOT NULL
            CONSTRAINT DF_data_quality_runs_started_at
            DEFAULT SYSDATETIME(),

        finished_at DATETIME2(3) NULL,

        run_status VARCHAR(20) NOT NULL,

        notes NVARCHAR(1000) NULL,

        CONSTRAINT PK_data_quality_runs
            PRIMARY KEY (dq_run_id)
    );
END;
GO


/* ============================================================
   2. ADD RUN ID TO RESULT TABLE
   ============================================================ */

IF COL_LENGTH(
    'etl.data_quality_results',
    'dq_run_id'
) IS NULL
BEGIN
    ALTER TABLE etl.data_quality_results
    ADD dq_run_id BIGINT NULL;
END;
GO


/* ============================================================
   3. FOREIGN KEY
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_data_quality_results_runs'
)
BEGIN
    ALTER TABLE etl.data_quality_results
    ADD CONSTRAINT FK_data_quality_results_runs
        FOREIGN KEY (dq_run_id)
        REFERENCES etl.data_quality_runs(dq_run_id);
END;
GO


/* ============================================================
   4. INDEX
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE
        name = 'IX_data_quality_results_dq_run_id'
        AND object_id = OBJECT_ID(
            'etl.data_quality_results'
        )
)
BEGIN
    CREATE INDEX IX_data_quality_results_dq_run_id
        ON etl.data_quality_results(dq_run_id);
END;
GO