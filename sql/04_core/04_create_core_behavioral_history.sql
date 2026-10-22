USE HomeCreditRisk;
GO

/* ============================================================
   CORE POS / CASH BALANCE

   Grain:
       One row = one previous loan + one month

   Relationship strategy:
       SK_ID_CURR -> trusted FK to core.applications
       SK_ID_PREV -> kept, but no FK constraint because
                     some previous applications are missing
   ============================================================ */

DROP TABLE IF EXISTS core.pos_cash_balance;
GO


CREATE TABLE core.pos_cash_balance
(
    SK_ID_PREV INT NOT NULL,
    SK_ID_CURR INT NOT NULL,
    MONTHS_BALANCE INT NOT NULL,

    CNT_INSTALMENT FLOAT NULL,
    CNT_INSTALMENT_FUTURE FLOAT NULL,

    NAME_CONTRACT_STATUS VARCHAR(50) NULL,

    SK_DPD INT NULL,
    SK_DPD_DEF INT NULL,

    PREVIOUS_APPLICATION_MATCHED TINYINT NOT NULL,

    CONSTRAINT PK_core_pos_cash_balance
        PRIMARY KEY
        (
            SK_ID_PREV,
            MONTHS_BALANCE
        ),

    CONSTRAINT FK_core_pos_cash_application
        FOREIGN KEY (SK_ID_CURR)
        REFERENCES core.applications(SK_ID_CURR),

    CONSTRAINT CK_core_pos_cash_prev_match
        CHECK (
            PREVIOUS_APPLICATION_MATCHED IN (0, 1)
        )
);
GO

INSERT INTO core.pos_cash_balance
(
    SK_ID_PREV,
    SK_ID_CURR,
    MONTHS_BALANCE,
    CNT_INSTALMENT,
    CNT_INSTALMENT_FUTURE,
    NAME_CONTRACT_STATUS,
    SK_DPD,
    SK_DPD_DEF,
    PREVIOUS_APPLICATION_MATCHED
)
SELECT
    p.SK_ID_PREV,
    p.SK_ID_CURR,
    p.MONTHS_BALANCE,
    p.CNT_INSTALMENT,
    p.CNT_INSTALMENT_FUTURE,
    p.NAME_CONTRACT_STATUS,
    CAST(p.SK_DPD AS INT),
    CAST(p.SK_DPD_DEF AS INT),

    CASE
        WHEN pa.SK_ID_PREV IS NULL THEN 0
        ELSE 1
    END

FROM raw.pos_cash_balance AS p

LEFT JOIN core.previous_applications AS pa
    ON p.SK_ID_PREV = pa.SK_ID_PREV;
GO

/* ============================================================
   CORE CREDIT CARD BALANCE

   Grain:
       One row = one previous credit card account + one month
   ============================================================ */

DROP TABLE IF EXISTS core.credit_card_balance;
GO


CREATE TABLE core.credit_card_balance
(
    SK_ID_PREV INT NOT NULL,
    SK_ID_CURR INT NOT NULL,
    MONTHS_BALANCE INT NOT NULL,

    AMT_BALANCE DECIMAL(19,3) NULL,
    AMT_CREDIT_LIMIT_ACTUAL DECIMAL(19,3) NULL,

    AMT_DRAWINGS_ATM_CURRENT DECIMAL(19,3) NULL,
    AMT_DRAWINGS_CURRENT DECIMAL(19,3) NULL,
    AMT_DRAWINGS_OTHER_CURRENT DECIMAL(19,3) NULL,
    AMT_DRAWINGS_POS_CURRENT DECIMAL(19,3) NULL,

    AMT_INST_MIN_REGULARITY DECIMAL(19,3) NULL,

    AMT_PAYMENT_CURRENT DECIMAL(19,3) NULL,
    AMT_PAYMENT_TOTAL_CURRENT DECIMAL(19,3) NULL,

    AMT_RECEIVABLE_PRINCIPAL DECIMAL(19,3) NULL,
    AMT_RECIVABLE DECIMAL(19,3) NULL,
    AMT_TOTAL_RECEIVABLE DECIMAL(19,3) NULL,

    CNT_DRAWINGS_ATM_CURRENT FLOAT NULL,
    CNT_DRAWINGS_CURRENT FLOAT NULL,
    CNT_DRAWINGS_OTHER_CURRENT FLOAT NULL,
    CNT_DRAWINGS_POS_CURRENT FLOAT NULL,
    CNT_INSTALMENT_MATURE_CUM FLOAT NULL,

    NAME_CONTRACT_STATUS VARCHAR(50) NULL,

    SK_DPD INT NULL,
    SK_DPD_DEF INT NULL,

    PREVIOUS_APPLICATION_MATCHED TINYINT NOT NULL,

    CONSTRAINT PK_core_credit_card_balance
        PRIMARY KEY
        (
            SK_ID_PREV,
            MONTHS_BALANCE
        ),

    CONSTRAINT FK_core_credit_card_application
        FOREIGN KEY (SK_ID_CURR)
        REFERENCES core.applications(SK_ID_CURR),

    CONSTRAINT CK_core_credit_card_prev_match
        CHECK (
            PREVIOUS_APPLICATION_MATCHED IN (0, 1)
        )
);
GO

INSERT INTO core.credit_card_balance
(
    SK_ID_PREV,
    SK_ID_CURR,
    MONTHS_BALANCE,

    AMT_BALANCE,
    AMT_CREDIT_LIMIT_ACTUAL,

    AMT_DRAWINGS_ATM_CURRENT,
    AMT_DRAWINGS_CURRENT,
    AMT_DRAWINGS_OTHER_CURRENT,
    AMT_DRAWINGS_POS_CURRENT,

    AMT_INST_MIN_REGULARITY,

    AMT_PAYMENT_CURRENT,
    AMT_PAYMENT_TOTAL_CURRENT,

    AMT_RECEIVABLE_PRINCIPAL,
    AMT_RECIVABLE,
    AMT_TOTAL_RECEIVABLE,

    CNT_DRAWINGS_ATM_CURRENT,
    CNT_DRAWINGS_CURRENT,
    CNT_DRAWINGS_OTHER_CURRENT,
    CNT_DRAWINGS_POS_CURRENT,
    CNT_INSTALMENT_MATURE_CUM,

    NAME_CONTRACT_STATUS,

    SK_DPD,
    SK_DPD_DEF,

    PREVIOUS_APPLICATION_MATCHED
)
SELECT
    c.SK_ID_PREV,
    c.SK_ID_CURR,
    c.MONTHS_BALANCE,

    c.AMT_BALANCE,
    c.AMT_CREDIT_LIMIT_ACTUAL,

    c.AMT_DRAWINGS_ATM_CURRENT,
    c.AMT_DRAWINGS_CURRENT,
    c.AMT_DRAWINGS_OTHER_CURRENT,
    c.AMT_DRAWINGS_POS_CURRENT,

    c.AMT_INST_MIN_REGULARITY,

    c.AMT_PAYMENT_CURRENT,
    c.AMT_PAYMENT_TOTAL_CURRENT,

    c.AMT_RECEIVABLE_PRINCIPAL,
    c.AMT_RECIVABLE,
    c.AMT_TOTAL_RECEIVABLE,

    c.CNT_DRAWINGS_ATM_CURRENT,
    c.CNT_DRAWINGS_CURRENT,
    c.CNT_DRAWINGS_OTHER_CURRENT,
    c.CNT_DRAWINGS_POS_CURRENT,
    c.CNT_INSTALMENT_MATURE_CUM,

    c.NAME_CONTRACT_STATUS,

    CAST(c.SK_DPD AS INT),
    CAST(c.SK_DPD_DEF AS INT),

    CASE
        WHEN pa.SK_ID_PREV IS NULL THEN 0
        ELSE 1
    END

FROM raw.credit_card_balance AS c

LEFT JOIN core.previous_applications AS pa
    ON c.SK_ID_PREV = pa.SK_ID_PREV;
GO

/* ============================================================
   CORE INSTALLMENT PAYMENTS

   Grain:
       One row = one recorded installment payment event

   There is no reliable natural unique key.
   PAYMENT_ID is therefore a surrogate key.
   ============================================================ */

DROP TABLE IF EXISTS core.installments_payments;
GO


CREATE TABLE core.installments_payments
(
    PAYMENT_ID BIGINT IDENTITY(1,1) NOT NULL,

    SK_ID_PREV INT NOT NULL,
    SK_ID_CURR INT NOT NULL,

    NUM_INSTALMENT_VERSION FLOAT NULL,
    NUM_INSTALMENT_NUMBER FLOAT NULL,

    DAYS_INSTALMENT FLOAT NULL,
    DAYS_ENTRY_PAYMENT FLOAT NULL,

    AMT_INSTALMENT DECIMAL(19,3) NULL,
    AMT_PAYMENT DECIMAL(19,3) NULL,

    PREVIOUS_APPLICATION_MATCHED TINYINT NOT NULL,

    CONSTRAINT PK_core_installments_payments
        PRIMARY KEY (PAYMENT_ID),

    CONSTRAINT FK_core_installments_application
        FOREIGN KEY (SK_ID_CURR)
        REFERENCES core.applications(SK_ID_CURR),

    CONSTRAINT CK_core_installments_prev_match
        CHECK (
            PREVIOUS_APPLICATION_MATCHED IN (0, 1)
        )
);
GO

INSERT INTO core.installments_payments
(
    SK_ID_PREV,
    SK_ID_CURR,

    NUM_INSTALMENT_VERSION,
    NUM_INSTALMENT_NUMBER,

    DAYS_INSTALMENT,
    DAYS_ENTRY_PAYMENT,

    AMT_INSTALMENT,
    AMT_PAYMENT,

    PREVIOUS_APPLICATION_MATCHED
)
SELECT
    i.SK_ID_PREV,
    i.SK_ID_CURR,

    i.NUM_INSTALMENT_VERSION,
    i.NUM_INSTALMENT_NUMBER,

    i.DAYS_INSTALMENT,
    i.DAYS_ENTRY_PAYMENT,

    i.AMT_INSTALMENT,
    i.AMT_PAYMENT,

    CASE
        WHEN pa.SK_ID_PREV IS NULL THEN 0
        ELSE 1
    END

FROM raw.installments_payments AS i

LEFT JOIN core.previous_applications AS pa
    ON i.SK_ID_PREV = pa.SK_ID_PREV;
GO

/* ============================================================
   ANALYTICAL INDEXES
   ============================================================ */

CREATE INDEX IX_core_pos_cash_SK_ID_CURR
    ON core.pos_cash_balance(SK_ID_CURR);
GO


CREATE INDEX IX_core_credit_card_SK_ID_CURR
    ON core.credit_card_balance(SK_ID_CURR);
GO


CREATE INDEX IX_core_installments_SK_ID_CURR
    ON core.installments_payments(SK_ID_CURR);
GO


CREATE INDEX IX_core_installments_SK_ID_PREV
    ON core.installments_payments(SK_ID_PREV);
GO