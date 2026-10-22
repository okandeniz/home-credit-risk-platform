USE HomeCreditRisk;
GO

SELECT TOP(5) * FROM core.applications;

CREATE OR ALTER VIEW bi.vw_applicant_overview
AS

SELECT
    a.SK_ID_CURR,

    a.DATASET_TYPE,
    a.TARGET,

    a.NAME_CONTRACT_TYPE,
    a.CODE_GENDER,

    a.FLAG_OWN_CAR,
    a.FLAG_OWN_REALTY,

    a.CNT_CHILDREN,

    a.AGE_YEARS,

    a.AMT_INCOME_TOTAL,
    a.AMT_CREDIT,
    a.AMT_ANNUITY,
    a.AMT_GOODS_PRICE,

    a.CREDIT_INCOME_RATIO,
    a.ANNUITY_INCOME_RATIO,
    a.ANNUITY_CREDIT_RATIO,

    a.DAYS_EMPLOYED,
    a.DAYS_EMPLOYED_ANOMALY,

    -- Bureau History

    COALESCE(
        b.BUREAU_CREDIT_COUNT,
        0
    ) AS BUREAU_CREDIT_COUNT,

    COALESCE(
        b.ACTIVE_BUREAU_CREDIT_COUNT,
        0
    ) AS ACTIVE_BUREAU_CREDIT_COUNT,

    COALESCE(
        b.CLOSED_BUREAU_CREDIT_COUNT,
        0
    ) AS CLOSED_BUREAU_CREDIT_COUNT,

    COALESCE(
        b.TOTAL_BUREAU_CREDIT,
        0
    ) AS TOTAL_BUREAU_CREDIT,

    COALESCE(
        b.TOTAL_BUREAU_DEBT,
        0
    ) AS TOTAL_BUREAU_DEBT,

    COALESCE(
        b.TOTAL_BUREAU_OVERDUE,
        0
    ) AS TOTAL_BUREAU_OVERDUE,

    b.MAX_CREDIT_DAY_OVERDUE,

    b.DAYS_SINCE_MOST_RECENT_BUREAU_CREDIT,

    b.BUREAU_DEBT_CREDIT_RATIO,

    -- Previous Applications

    COALESCE(
        p.PREVIOUS_APPLICATION_COUNT,
        0
    ) AS PREVIOUS_APPLICATION_COUNT,

    COALESCE(
        p.PREVIOUS_APPROVED_COUNT,
        0
    ) AS PREVIOUS_APPROVED_COUNT,

    COALESCE(
        p.PREVIOUS_REFUSED_COUNT,
        0
    ) AS PREVIOUS_REFUSED_COUNT,

    p.PREVIOUS_APPROVAL_RATE,

    p.AVG_PREVIOUS_APPLICATION_AMOUNT,

    p.AVG_PREVIOUS_CREDIT_AMOUNT,

    p.MAX_PREVIOUS_CREDIT_AMOUNT,

    p.DAYS_SINCE_LAST_PREVIOUS_APPLICATION,

    -- Installment Payment Behavior

    COALESCE(
        i.PAYMENT_EVENT_COUNT,
        0
    ) AS PAYMENT_EVENT_COUNT,

    COALESCE(
        i.LATE_PAYMENT_COUNT,
        0
    ) AS LATE_PAYMENT_COUNT,

    i.LATE_PAYMENT_RATE,

    i.AVG_LATE_PAYMENT_DAYS,

    i.MAX_LATE_PAYMENT_DAYS,

    COALESCE(
        i.UNDERPAYMENT_COUNT,
        0
    ) AS UNDERPAYMENT_COUNT,

    i.UNDERPAYMENT_RATE,

    i.TOTAL_EXPECTED_PAYMENT,

    i.TOTAL_ACTUAL_PAYMENT,

    COALESCE(
        i.TOTAL_PAYMENT_SHORTFALL,
        0
    ) AS TOTAL_PAYMENT_SHORTFALL,

    -- POS / CASH Behavior

     COALESCE(
        pc.POS_CONTRACT_COUNT,
        0
    ) AS POS_CONTRACT_COUNT,

    COALESCE(
        pc.POS_MONTH_COUNT,
        0
    ) AS POS_MONTH_COUNT,

    pc.POS_DELINQUENT_MONTH_RATE,

    pc.MAX_POS_DPD,

    pc.AVG_POS_DPD_WHEN_DELINQUENT,

    COALESCE(
        pc.POS_DELINQUENT_MONTH_COUNT,
        0
    ) AS POS_DELINQUENT_MONTH_COUNT,

    COALESCE(
        pc.POS_DEFAULT_DELINQUENT_MONTH_COUNT,
        0
    ) AS POS_DEFAULT_DELINQUENT_MONTH_COUNT,

    -- Credit Card Behavior

    COALESCE(
        cc.CREDIT_CARD_COUNT,
        0
    ) AS CREDIT_CARD_COUNT,

    COALESCE(
        cc.CREDIT_CARD_MONTH_COUNT,
        0
    ) AS CREDIT_CARD_MONTH_COUNT,

    cc.AVG_CREDIT_CARD_BALANCE,

    cc.MAX_CREDIT_CARD_BALANCE,

    cc.AVG_CREDIT_LIMIT,

    cc.AVG_CREDIT_UTILIZATION,

    cc.MAX_CREDIT_UTILIZATION,

    cc.CREDIT_CARD_DELINQUENT_MONTH_RATE,

    cc.MAX_CREDIT_CARD_DPD,

    cc.AVG_CREDIT_CARD_DPD_WHEN_DELINQUENT

FROM core.applications AS a


LEFT JOIN bi.vw_bureau_customer_summary AS b
    ON a.SK_ID_CURR = b.SK_ID_CURR


LEFT JOIN bi.vw_previous_application_summary AS p
    ON a.SK_ID_CURR = p.SK_ID_CURR


LEFT JOIN bi.vw_installment_payment_summary AS i
    ON a.SK_ID_CURR = i.SK_ID_CURR


LEFT JOIN bi.vw_pos_cash_summary AS pc
    ON a.SK_ID_CURR = pc.SK_ID_CURR


LEFT JOIN bi.vw_credit_card_summary AS cc
    ON a.SK_ID_CURR = cc.SK_ID_CURR;
GO

SELECT TOP (20) *
FROM bi.vw_applicant_overview
ORDER BY SK_ID_CURR;

-- Grain Conrol

SELECT
    COUNT_BIG(*) AS total_rows,

    COUNT_BIG(
        DISTINCT SK_ID_CURR
    ) AS unique_customers

FROM bi.vw_applicant_overview;

-- Train test conrtol

SELECT
    DATASET_TYPE,
    COUNT_BIG(*) AS application_count
FROM bi.vw_applicant_overview
GROUP BY DATASET_TYPE
ORDER BY DATASET_TYPE;

-- History coverage analysis

SELECT
    COUNT_BIG(*) AS total_applications,

    SUM(
        CASE
            WHEN BUREAU_CREDIT_COUNT > 0
                THEN 1
            ELSE 0
        END
    ) AS customers_with_bureau,

    SUM(
        CASE
            WHEN PREVIOUS_APPLICATION_COUNT > 0
                THEN 1
            ELSE 0
        END
    ) AS customers_with_previous_applications,

    SUM(
        CASE
            WHEN PAYMENT_EVENT_COUNT > 0
                THEN 1
            ELSE 0
        END
    ) AS customers_with_installments,

    SUM(
        CASE
            WHEN POS_CONTRACT_COUNT > 0
                THEN 1
            ELSE 0
        END
    ) AS customers_with_pos,

    SUM(
        CASE
            WHEN CREDIT_CARD_COUNT > 0
                THEN 1
            ELSE 0
        END
    ) AS customers_with_credit_card

FROM bi.vw_applicant_overview;