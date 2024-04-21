/* 
 * Make sure all the variables below are the same as per what's in 01_setup.sql
 */

-- set the variables for the github repo, as per 01_setup.sql
SET MY_GITHUB_REPO = 'GITHUB_REPO_DEMO_STUG_MELB_2024_IGGY';

-- create csv file format
CREATE OR REPLACE FILE FORMAT MY_CSV_FORMAT
  TYPE = csv
  PARSE_HEADER = true;

-- create a table based on the demo_data.sql
CREATE OR REPLACE TABLE DEMO_DATA
USING TEMPLATE (
  SELECT *
  FROM TABLE (
    INFER_SCHEMA (
      LOCATION=>'@' || $MY_GITHUB_REPO || '/branches/main/data/demo_data.csv',
      FILE_FORMAT=>'MY_CSV_FORMAT'
    )
  )
);
