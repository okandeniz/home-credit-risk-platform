USE HomeCreditRisk;
GO


IF OBJECT_ID(
    N'etl.raw_load_audit',
    N'U'
) IS NULL
BEGIN
    CREATE TABLE etl.raw_load_audit
    (
        load_id BIGINT IDENTITY(1,1) NOT NULL,

        source_file VARCHAR(255) NOT NULL,

        target_schema VARCHAR(50) NOT NULL,

        target_table VARCHAR(255) NOT NULL,

        source_row_count BIGINT NULL,

        loaded_row_count BIGINT NULL,

        load_started_at DATETIME2(3) NOT NULL,

        load_finished_at DATETIME2(3) NULL,

        duration_seconds DECIMAL(18,3) NULL,

        load_status VARCHAR(20) NOT NULL,

        error_message NVARCHAR(4000) NULL,

        CONSTRAINT PK_raw_load_audit
            PRIMARY KEY (load_id)
    );
END;
GO

SELECT *
FROM etl.raw_load_audit;