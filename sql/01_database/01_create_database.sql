/* ============================================================
   Project: Home Credit Risk Platform
   File: 01_create_database.sql
   Purpose:
       Create the main project database and required schemas.
   ============================================================ */

USE master;
GO

/* ============================================================
   1. CREATE DATABASE
   ============================================================ */

IF DB_ID('HomeCreditRisk') IS NULL
BEGIN
    CREATE DATABASE HomeCreditRisk;
END;
GO

/* ============================================================
   2. USE PROJECT DATABASE
   ============================================================ */

USE HomeCreditRisk;
GO

/* ============================================================
   3. CREATE SCHEMAS
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'raw'
)
BEGIN
    EXEC('CREATE SCHEMA raw');
END;
GO


IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'bi'
)
BEGIN
    EXEC('CREATE SCHEMA bi');
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'ml'
)
BEGIN
    EXEC('CREATE SCHEMA ml');
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'core'
)
BEGIN
    EXEC('CREATE SCHEMA core');
END;
GO

USE HomeCreditRisk;
GO



IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'etl'
)
BEGIN
    EXEC('CREATE SCHEMA etl');
END;
GO

SELECT
    name AS schema_name
FROM sys.schemas
WHERE name IN ('raw', 'bi', 'ml', 'core', 'etl')
ORDER BY name;