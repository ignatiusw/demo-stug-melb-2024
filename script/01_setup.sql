/* Assumptions:
 * 1. You already have your own Snowflake account
 * 2. You have the ability to assume SYSADMIN and SECURITYADMIN role
 * 3. The database, schema, role, and warehouse already exist
 * 4. The role used has privileges to create database objects and streamlit on the schema - refer to Snowflake documentation
 * 5. The role used has privileges to use the warehouse - refer to Snowflake documentation
 */

-- set the initial variables to be used below, change as required to suit your Snowflake account
SET MY_ROLE = 'ROL_IGNATIUS_SOPUTRO';
SET MY_DATABASE = 'USERSPACE_IGNATIUS_SOPUTRO';
SET MY_SCHEMA = $MY_DATABASE || '.X2';
SET MY_WAREHOUSE = 'DT_PLATFORMS_WH';

-- set the variables for the github integration
SET MY_GITHUB_INT = 'GITHUB_API_INTEGRATION_IGGY';
SET MY_GITHUB_REPO = 'GITHUB_REPO_DEMO_STUG_MELB_2024_IGGY';

-- create api integration with git
USE ROLE SYSADMIN;
CREATE OR REPLACE API INTEGRATION IDENTIFIER($MY_GITHUB_INT)
    API_PROVIDER = git_https_api 
    API_ALLOWED_PREFIXES = ('https://github.com/ignatiusw') 
    ENABLED=TRUE;

-- grant privileges to create github integration
USE ROLE SECURITYADMIN;
GRANT CREATE GIT REPOSITORY ON SCHEMA IDENTIFIER($MY_SCHEMA) TO ROLE IDENTIFIER($MY_ROLE);

-- Switch role, schema and use warehouse
USE ROLE IDENTIFIER($MY_ROLE);
USE SCHEMA IDENTIFIER($MY_SCHEMA);
USE WAREHOUSE IDENTIFIER($MY_WAREHOUSE);

-- create github repo
CREATE OR REPLACE GIT REPOSITORY IDENTIFIER($MY_GITHUB_REPO)
  API_INTEGRATION = $MY_GITHUB_INT
  ORIGIN = 'https://github.com/ignatiusw/demo-stug-melb-2024.git'
;

-- this is a workaround for using variable with stage
SET MY_CMD = 'ls @' || $MY_GITHUB_REPO || '/branches/main';
-- show the command that's going to be executed
SELECT $MY_CMD;
-- execute the command
EXECUTE IMMEDIATE $MY_CMD;

-- show objects not exist initially
SHOW TABLES IN SCHEMA IDENTIFIER($MY_SCHEMA);
SHOW VIEWS IN SCHEMA IDENTIFIER($MY_SCHEMA);
SHOW STREAMLITS IN SCHEMA IDENTIFIER($MY_SCHEMA);
SHOW SNOWFLAKE.ML.FORECAST IN SCHEMA IDENTIFIER($MY_SCHEMA);
SHOW FILE FORMATS IN SCHEMA IDENTIFIER($MY_SCHEMA);

-- create table and load sample data by executing script on github
SET MY_CMD = 'EXECUTE IMMEDIATE FROM @' || $MY_GITHUB_REPO || '/branches/main/script/02_load-data.sql';
SELECT $MY_CMD;
EXECUTE IMMEDIATE $MY_CMD;

-- create supplementary objects by executing script on github
SET MY_CMD = 'EXECUTE IMMEDIATE FROM @' || $MY_GITHUB_REPO || '/branches/main/script/03_create-supp-objects.sql';
SELECT $MY_CMD;
EXECUTE IMMEDIATE $MY_CMD;

-- create streamlit app
SET MY_STREAMLIT_STAGE = '@' || $MY_SCHEMA || '.' || $MY_GITHUB_REPO || '/branches/main/streamlit_app';
SELECT $MY_STREAMLIT_STAGE;

SET MY_CMD = 'CREATE OR REPLACE STREAMLIT TEST_GITHUB_INTEGRATION_STREAMLIT_APP' || $$
ROOT_LOCATION = $$ || $MY_STREAMLIT_STAGE || $$
MAIN_FILE = 'app.py'
QUERY_WAREHOUSE = $$ || $MY_WAREHOUSE;

SELECT $MY_CMD;
EXECUTE IMMEDIATE $MY_CMD;

-- clean up
SET MY_CMD = 'EXECUTE IMMEDIATE FROM @' || $MY_GITHUB_REPO || '/branches/main/script/99_clean-up.sql';
SELECT $MY_CMD;
EXECUTE IMMEDIATE $MY_CMD;
