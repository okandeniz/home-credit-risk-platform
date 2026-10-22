USE HomeCreditRisk;
GO


IF OBJECT_ID(
    N'etl.data_quality_results',
    N'U'
) IS NULL
BEGIN
    CREATE TABLE etl.data_quality_results
    (
        dq_result_id BIGINT IDENTITY(1,1) NOT NULL,

        check_time DATETIME2(3) NOT NULL
            CONSTRAINT DF_dq_check_time
            DEFAULT SYSDATETIME(),

        schema_name VARCHAR(50) NOT NULL,

        table_name VARCHAR(255) NOT NULL,

        check_name VARCHAR(255) NOT NULL,

        check_type VARCHAR(100) NOT NULL,

        metric_value DECIMAL(19,4) NULL,

        threshold_value DECIMAL(19,4) NULL,

        status VARCHAR(20) NOT NULL,

        details NVARCHAR(1000) NULL,

        CONSTRAINT PK_data_quality_results
            PRIMARY KEY (dq_result_id)
    );
END;
GO

SELECT *
FROM etl.data_quality_results;