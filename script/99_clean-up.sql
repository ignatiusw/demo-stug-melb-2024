/* 
 * Make sure all the variables below are the same as per what's in 01_setup.sql
 */

-- set the variables for the github repo, as per 01_setup.sql
SET MY_ROLE = 'ROL_IGNATIUS_SOPUTRO';
SET MY_DATABASE = 'USERSPACE_IGNATIUS_SOPUTRO';
SET MY_SCHEMA = $MY_DATABASE || '.X2';
SET MY_GITHUB_REPO = 'GITHUB_REPO_DEMO_STUG_MELB_2024_IGGY';

-- Drop streamlit app
DROP STREAMLIT IF EXISTS TEST_GITHUB_INTEGRATION_STREAMLIT_APP;

-- Drop objects created
DROP SNOWFLAKE.ML.FORECAST IF EXISTS FORECAST_MODEL;
DROP VIEW IF EXISTS "REVENUE";
DROP TABLE IF EXISTS "DEMO_DATA";
DROP TABLE IF EXISTS "STORE_PCT";
DROP TABLE IF EXISTS "TARGET_REVENUE_AU/NZ";
DROP TABLE IF EXISTS "TARGET_REVENUE_US";
DROP TABLE IF EXISTS "TARGET_REVENUE_AU/NZ";

-- Drop github repo
DROP GIT REPOSITORY IF EXISTS IDENTIFIER($MY_GITHUB_REPO);

-- Drop github api integration
USE ROLE SYSADMIN;
DROP API INTEGRATION IF EXISTS IDENTIFIER($MY_GITHUB_INT);

-- Clean up additional privileges
USE ROLE SECURITYADMIN;
REVOKE CREATE GIT REPOSITORY ON SCHEMA IDENTIFIER($MY_SCHEMA) FROM ROLE IDENTIFIER($MY_ROLE);
