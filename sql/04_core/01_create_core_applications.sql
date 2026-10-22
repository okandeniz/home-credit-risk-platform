USE HomeCreditRisk;
GO


DROP TABLE IF EXISTS core.applications;
GO


CREATE TABLE core.applications
(
    SK_ID_CURR INT NOT NULL,

    DATASET_TYPE VARCHAR(10) NOT NULL,

    TARGET TINYINT NULL,

    NAME_CONTRACT_TYPE VARCHAR(20) NULL,

    CODE_GENDER VARCHAR(10) NULL,

    FLAG_OWN_CAR VARCHAR(10) NULL,

    FLAG_OWN_REALTY VARCHAR(10) NULL,

    CNT_CHILDREN INT NULL,

    AMT_INCOME_TOTAL DECIMAL(19,3) NULL,

    AMT_CREDIT DECIMAL(19,3) NULL,

    AMT_ANNUITY DECIMAL(19,3) NULL,

    AMT_GOODS_PRICE DECIMAL(19,3) NULL,

    DAYS_BIRTH INT NULL,

    DAYS_EMPLOYED INT NULL,

    DAYS_EMPLOYED_ANOMALY TINYINT NOT NULL,

    AGE_YEARS DECIMAL(10,2) NULL,

    CREDIT_INCOME_RATIO DECIMAL(19,6) NULL,

    ANNUITY_INCOME_RATIO DECIMAL(19,6) NULL,

    ANNUITY_CREDIT_RATIO DECIMAL(19,6) NULL

    CONSTRAINT PK_core_applications
        PRIMARY KEY (SK_ID_CURR),

    CONSTRAINT CK_core_applications_dataset
        CHECK (
            DATASET_TYPE IN ('TRAIN', 'TEST')
        ),

    CONSTRAINT CK_core_applications_target
        CHECK (
            TARGET IN (0, 1)
            OR TARGET IS NULL
        )
);
GO

INSERT INTO core.applications
(
    SK_ID_CURR,
    DATASET_TYPE,
    TARGET,
    NAME_CONTRACT_TYPE,
    CODE_GENDER,
    FLAG_OWN_CAR,
    FLAG_OWN_REALTY,
    CNT_CHILDREN,
    AMT_INCOME_TOTAL,
    AMT_CREDIT,
    AMT_ANNUITY,
    AMT_GOODS_PRICE,
    DAYS_BIRTH,
    DAYS_EMPLOYED,
    DAYS_EMPLOYED_ANOMALY,
    AGE_YEARS,
    CREDIT_INCOME_RATIO,
    ANNUITY_INCOME_RATIO,
    ANNUITY_CREDIT_RATIO
)
SELECT
    SK_ID_CURR,

    'TRAIN',

    TARGET,

    NAME_CONTRACT_TYPE,

    CASE
        WHEN CODE_GENDER = 'XNA'
            THEN 'Unknown'
        ELSE CODE_GENDER
    END,

    FLAG_OWN_CAR,

    FLAG_OWN_REALTY,

    CNT_CHILDREN,

    AMT_INCOME_TOTAL,

    AMT_CREDIT,

    AMT_ANNUITY,

    AMT_GOODS_PRICE,

    DAYS_BIRTH,

    CASE
        WHEN DAYS_EMPLOYED = 365243
            THEN NULL
        ELSE CAST(DAYS_EMPLOYED AS INT)
    END,

    CASE
        WHEN DAYS_EMPLOYED = 365243
            THEN 1
        ELSE 0
    END,

    CAST(
        ABS(DAYS_BIRTH) / 365.25
        AS DECIMAL(10,2)
    ),

    CAST(
        AMT_CREDIT
        / NULLIF(
            AMT_INCOME_TOTAL,
            0
        )
        AS DECIMAL(19,6)
    ),

    CAST(
        AMT_ANNUITY
        / NULLIF(
            AMT_INCOME_TOTAL,
            0
        )
        AS DECIMAL(19,6)
    ),

    CAST(
        AMT_ANNUITY
        / NULLIF(
            AMT_CREDIT,
            0
        )
        AS DECIMAL(19,6)
    )

FROM raw.application_train;
GO


INSERT INTO core.applications
(
    SK_ID_CURR,
    DATASET_TYPE,
    TARGET,
    NAME_CONTRACT_TYPE,
    CODE_GENDER,
    FLAG_OWN_CAR,
    FLAG_OWN_REALTY,
    CNT_CHILDREN,
    AMT_INCOME_TOTAL,
    AMT_CREDIT,
    AMT_ANNUITY,
    AMT_GOODS_PRICE,
    DAYS_BIRTH,
    DAYS_EMPLOYED,
    DAYS_EMPLOYED_ANOMALY,
    AGE_YEARS,
    CREDIT_INCOME_RATIO,
    ANNUITY_INCOME_RATIO,
    ANNUITY_CREDIT_RATIO
)
SELECT
    SK_ID_CURR,

    'TEST',

    NULL,

    NAME_CONTRACT_TYPE,

    CASE
        WHEN CODE_GENDER = 'XNA'
            THEN 'Unknown'
        ELSE CODE_GENDER
    END,

    FLAG_OWN_CAR,

    FLAG_OWN_REALTY,

    CNT_CHILDREN,

    AMT_INCOME_TOTAL,

    AMT_CREDIT,

    AMT_ANNUITY,

    AMT_GOODS_PRICE,

    DAYS_BIRTH,

    CASE
        WHEN DAYS_EMPLOYED = 365243
            THEN NULL
        ELSE CAST(DAYS_EMPLOYED AS INT)
    END,

    CASE
        WHEN DAYS_EMPLOYED = 365243
            THEN 1
        ELSE 0
    END,

    CAST(
        ABS(DAYS_BIRTH) / 365.25
        AS DECIMAL(10,2)
    ),

    CAST(
        AMT_CREDIT
        / NULLIF(
            AMT_INCOME_TOTAL,
            0
        )
        AS DECIMAL(19,6)
    ),

    CAST(
        AMT_ANNUITY
        / NULLIF(
            AMT_INCOME_TOTAL,
            0
        )
        AS DECIMAL(19,6)
    ),

    CAST(
        AMT_ANNUITY
        / NULLIF(
            AMT_CREDIT,
            0
        )
        AS DECIMAL(19,6)
    )

FROM raw.application_test;
GO

SELECT
    COUNT_BIG(*) AS total_rows
FROM core.applications;

SELECT
    DATASET_TYPE,
    COUNT_BIG(*) AS application_count
FROM core.applications
GROUP BY DATASET_TYPE;

SELECT
    DATASET_TYPE,

    COUNT_BIG(*) AS total_rows,

    SUM(
        CASE
            WHEN TARGET IS NULL THEN 1
            ELSE 0
        END
    ) AS null_target_count

FROM core.applications

GROUP BY DATASET_TYPE;


SELECT
    DAYS_EMPLOYED_ANOMALY,
    COUNT_BIG(*) AS application_count
FROM core.applications
GROUP BY DAYS_EMPLOYED_ANOMALY;

SELECT COUNT_BIG(*) AS invalid_remaining_count
FROM core.applications
WHERE DAYS_EMPLOYED = 365243;

SELECT
    MIN(AGE_YEARS) AS min_age,
    AVG(AGE_YEARS) AS avg_age,
    MAX(AGE_YEARS) AS max_age
FROM core.applications;

SELECT TOP (20)
    SK_ID_CURR,
    DATASET_TYPE,
    TARGET,
    AGE_YEARS,
    AMT_INCOME_TOTAL,
    AMT_CREDIT,
    AMT_ANNUITY,
    CREDIT_INCOME_RATIO,
    ANNUITY_INCOME_RATIO,
    ANNUITY_CREDIT_RATIO,
    DAYS_EMPLOYED_ANOMALY
FROM core.applications
ORDER BY SK_ID_CURR;