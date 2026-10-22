
USE HomeCreditRisk;
GO

CREATE OR ALTER VIEW bi.vw_default_risk_predictions
AS

SELECT
    -- Applicant information
    p.SK_ID_CURR,
    p.DATASET_TYPE,

    -- Model predictions
    p.RISK_PROBABILITY,
    p.RISK_FLAG,
    p.THRESHOLD,
    p.MODEL_VERSION,
    p.PREDICTED_AT,

    CASE
        WHEN p.RISK_FLAG = 1
            THEN 'Review Recommended'
        ELSE 'Below Review Threshold'
    END AS REVIEW_STATUS,

    -- Applicant characteristics
    f.NAME_CONTRACT_TYPE,
    f.AGE_YEARS,
    f.AMT_INCOME_TOTAL,
    f.AMT_CREDIT,
    f.AMT_ANNUITY,

    -- Financial indicators
    f.CREDIT_INCOME_RATIO,
    f.ANNUITY_INCOME_RATIO,

    -- Historical behavior
    f.LATE_PAYMENT_RATE,
    f.PREVIOUS_REFUSAL_RATE,
    f.AVG_CREDIT_UTILIZATION,
    f.TOTAL_BUREAU_OVERDUE

FROM ml.default_risk_predictions AS p

INNER JOIN ml.vw_default_risk_features AS f
    ON p.SK_ID_CURR = f.SK_ID_CURR
    AND p.DATASET_TYPE = f.DATASET_TYPE

WHERE p.DATASET_TYPE = 'TEST';
GO



SELECT
    COUNT(*) AS TotalApplications,

    COUNT(DISTINCT SK_ID_CURR)
        AS UniqueApplicants,

    SUM(CAST(RISK_FLAG AS INT))
        AS FlaggedForReview,

    CAST(
        100.0 * AVG(CAST(RISK_FLAG AS FLOAT))
        AS DECIMAL(6,2)
    ) AS ReviewRatePct,

    CAST(
        100.0 * AVG(RISK_PROBABILITY)
        AS DECIMAL(6,2)
    ) AS AvgRiskProbabilityPct

FROM bi.vw_default_risk_predictions;
