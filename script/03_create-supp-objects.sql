/* 
 * Make sure all the variables below are the same as per what's in 01_setup.sql
 */

-- set the variables for the github repo, as per 01_setup.sql
SET MY_DATABASE = 'USERSPACE_IGNATIUS_SOPUTRO';
SET MY_SCHEMA = $MY_DATABASE || '.X2';

USE SCHEMA IDENTIFIER($MY_SCHEMA);

-- Create revenue target table for each region
CREATE OR REPLACE TABLE "TARGET_REVENUE_AU/NZ" AS
SELECT "MONTH", TARGET_REVENUE
FROM DEMO_DATA
WHERE GROSS_SALE IS NULL AND SALES_COST IS NULL
    AND TARGET_REVENUE IS NOT NULL
    AND REGION = 'AU/NZ';

CREATE OR REPLACE TABLE "TARGET_REVENUE_US" AS
SELECT "MONTH", TARGET_REVENUE
FROM DEMO_DATA
WHERE GROSS_SALE IS NULL AND SALES_COST IS NULL
    AND TARGET_REVENUE IS NOT NULL
    AND REGION = 'US';

CREATE OR REPLACE TABLE "TARGET_REVENUE_UK" AS
SELECT "MONTH", TARGET_REVENUE
FROM DEMO_DATA
WHERE GROSS_SALE IS NULL AND SALES_COST IS NULL
    AND TARGET_REVENUE IS NOT NULL
    AND REGION = 'UK';

-- Create a new view to produce sales forecast
CREATE OR REPLACE VIEW REVENUE AS
SELECT CAST("MONTH" AS TIMESTAMP_NTZ) AS "MONTH", REGION, GROSS_SALE - SALES_COST AS REVENUE
FROM DEMO_DATA
WHERE GROSS_SALE IS NOT NULL AND SALES_COST IS NOT NULL;

-- Create a forecast model using Snowflake Cortex
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST FORECAST_MODEL(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'REVENUE'),
    SERIES_COLNAME => 'REGION',
    TIMESTAMP_COLNAME => 'MONTH',
    TARGET_COLNAME => 'REVENUE'
);

-- Test run forecast model
CALL FORECAST_MODEL!FORECAST(FORECASTING_PERIODS => 4);

-- Visualise quickly
WITH CTE_TARGET AS (
    SELECT MONTH, REGION, TARGET_REVENUE
    FROM DEMO_DATA
), CTE_SALES AS (
    SELECT MONTH, REGION, REVENUE AS ACTUAL_REVENUE, NULL AS FORECAST, NULL AS LOWER_BOUND, NULL AS UPPER_BOUND
    FROM REVENUE
    UNION ALL
    SELECT ts, series, NULL, forecast, lower_bound, upper_bound
      FROM TABLE(RESULT_SCAN(-1))
)
SELECT s.REGION, s.MONTH, t.TARGET_REVENUE, s.ACTUAL_REVENUE, s.FORECAST, s.LOWER_BOUND, s.UPPER_BOUND
FROM CTE_SALES s
LEFT JOIN CTE_TARGET t
    ON s.MONTH = t.MONTH
        AND s.REGION = t.REGION
ORDER BY REGION, MONTH;
