USE HomeCreditRisk;
GO

IF OBJECT_ID('ml.default_risk_predictions', 'U') IS NULL
BEGIN
	CREATE TABLE ml.default_risk_predictions (
        SK_ID_CURR INT NOT NULL,
        DATASET_TYPE VARCHAR(10) NOT NULL,
        RISK_PROBABILITY FLOAT NOT NULL,
        RISK_FLAG BIT NOT NULL,
        THRESHOLD FLOAT NOT NULL,
        MODEL_VERSION VARCHAR(32) NOT NULL,
        PREDICTED_AT DATETIME2(0) NOT NULL
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_default_risk_predictions
            PRIMARY KEY (SK_ID_CURR, MODEL_VERSION),

        CONSTRAINT CK_default_risk_probability
            CHECK (RISK_PROBABILITY BETWEEN 0 AND 1),

        CONSTRAINT CK_default_risk_threshold
            CHECK (THRESHOLD BETWEEN 0 AND 1)
    );
END;
GO



SELECT
    COUNT(*) AS TotalApplications,
    SUM(CAST(RISK_FLAG AS INT)) AS FlaggedForReview,
    AVG(RISK_PROBABILITY) AS AverageRiskProbability,
    MIN(PREDICTED_AT) AS FirstPredictionTime,
    MAX(PREDICTED_AT) AS LastPredictionTime
FROM ml.default_risk_predictions
WHERE DATASET_TYPE = 'TEST'
  AND MODEL_VERSION = '1.0.0';

	