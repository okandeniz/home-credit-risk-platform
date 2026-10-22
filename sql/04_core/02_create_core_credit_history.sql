USE HomeCreditRisk;
GO


/* ============================================================
   CORE BUREAU
   One row = one bureau credit record
   ============================================================ */

DROP TABLE IF EXISTS core.bureau;
GO


CREATE TABLE core.bureau
(
    SK_ID_BUREAU INT NOT NULL,
    SK_ID_CURR INT NOT NULL,

    CREDIT_ACTIVE VARCHAR(20) NULL,
    CREDIT_CURRENCY VARCHAR(20) NULL,

    DAYS_CREDIT INT NULL,
    CREDIT_DAY_OVERDUE INT NULL,

    DAYS_CREDIT_ENDDATE FLOAT NULL,
    DAYS_ENDDATE_FACT FLOAT NULL,

    AMT_CREDIT_MAX_OVERDUE DECIMAL(19,3) NULL,
    CNT_CREDIT_PROLONG INT NULL,

    AMT_CREDIT_SUM DECIMAL(19,3) NULL,
    AMT_CREDIT_SUM_DEBT DECIMAL(19,3) NULL,
    AMT_CREDIT_SUM_LIMIT DECIMAL(19,3) NULL,
    AMT_CREDIT_SUM_OVERDUE DECIMAL(19,3) NULL,

    CREDIT_TYPE VARCHAR(50) NULL,

    DAYS_CREDIT_UPDATE INT NULL,
    AMT_ANNUITY DECIMAL(19,3) NULL,

    CONSTRAINT PK_core_bureau
        PRIMARY KEY (SK_ID_BUREAU),

    CONSTRAINT FK_core_bureau_application
        FOREIGN KEY (SK_ID_CURR)
        REFERENCES core.applications(SK_ID_CURR)
);
GO

INSERT INTO core.bureau
(
    SK_ID_BUREAU,
    SK_ID_CURR,
    CREDIT_ACTIVE,
    CREDIT_CURRENCY,
    DAYS_CREDIT,
    CREDIT_DAY_OVERDUE,
    DAYS_CREDIT_ENDDATE,
    DAYS_ENDDATE_FACT,
    AMT_CREDIT_MAX_OVERDUE,
    CNT_CREDIT_PROLONG,
    AMT_CREDIT_SUM,
    AMT_CREDIT_SUM_DEBT,
    AMT_CREDIT_SUM_LIMIT,
    AMT_CREDIT_SUM_OVERDUE,
    CREDIT_TYPE,
    DAYS_CREDIT_UPDATE,
    AMT_ANNUITY
)
SELECT
    SK_ID_BUREAU,
    SK_ID_CURR,
    CREDIT_ACTIVE,
    CREDIT_CURRENCY,
    CAST(DAYS_CREDIT AS INT),
    CAST(CREDIT_DAY_OVERDUE AS INT),
    DAYS_CREDIT_ENDDATE,
    DAYS_ENDDATE_FACT,
    AMT_CREDIT_MAX_OVERDUE,
    CAST(CNT_CREDIT_PROLONG AS INT),
    AMT_CREDIT_SUM,
    AMT_CREDIT_SUM_DEBT,
    AMT_CREDIT_SUM_LIMIT,
    AMT_CREDIT_SUM_OVERDUE,
    CREDIT_TYPE,
    CAST(DAYS_CREDIT_UPDATE AS INT),
    AMT_ANNUITY
FROM raw.bureau;
GO


/* ============================================================
   CORE BUREAU BALANCE
   Only records with a valid bureau parent
   ============================================================ */

DROP TABLE IF EXISTS core.bureau_balance;
GO


CREATE TABLE core.bureau_balance
(
    SK_ID_BUREAU INT NOT NULL,
    MONTHS_BALANCE INT NOT NULL,
    STATUS VARCHAR(10) NULL,

    CONSTRAINT PK_core_bureau_balance
        PRIMARY KEY
        (
            SK_ID_BUREAU,
            MONTHS_BALANCE
        ),

    CONSTRAINT FK_core_bureau_balance_bureau
        FOREIGN KEY (SK_ID_BUREAU)
        REFERENCES core.bureau(SK_ID_BUREAU)
);
GO


INSERT INTO core.bureau_balance
(
    SK_ID_BUREAU,
    MONTHS_BALANCE,
    STATUS
)
SELECT
    bb.SK_ID_BUREAU,
    bb.MONTHS_BALANCE,
    bb.STATUS

FROM raw.bureau_balance AS bb

INNER JOIN core.bureau AS b
    ON bb.SK_ID_BUREAU = b.SK_ID_BUREAU;
GO

