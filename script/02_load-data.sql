/* 
 * Make sure all the variables below are the same as per what's in 01_setup.sql
 */

-- set the variables for the github repo, as per 01_setup.sql
SET MY_GITHUB_REPO = 'GITHUB_REPO_DEMO_STUG_MELB_2024_IGGY';

-- create csv file format
CREATE OR REPLACE FILE FORMAT MY_CSV_FORMAT
  TYPE = csv
  PARSE_HEADER = true;

-- create a table based on the demo_data.csv
CREATE OR REPLACE TABLE DEMO_DATA
USING TEMPLATE (
  SELECT *
  FROM TABLE (
    INFER_SCHEMA (
      --LOCATION=>'@' || $MY_GITHUB_REPO || '/branches/main/data',
      LOCATION=>'@GITHUB_REPO_DEMO_STUG_MELB_2024_IGGY/branches/main/data',
      FILE_FORMAT=>'MY_CSV_FORMAT',
      FILES=>'demo_data.csv'
    )
  )
);

-- load demo_data
COPY INTO DEMO_DATA
--FROM '@' || $MY_GITHUB_REPO || '/branches/main/data'
FROM '@GITHUB_REPO_DEMO_STUG_MELB_2024_IGGY/branches/main/data'
FILES = ('demo_data.csv')
FILE_FORMAT = ( FORMAT_NAME = 'MY_CSV_FORMAT' );

-- create a table based on store_pct.csv
CREATE OR REPLACE TABLE STORE_PCT
USING TEMPLATE (
  SELECT *
  FROM TABLE (
    INFER_SCHEMA (
      --LOCATION=>'@' || $MY_GITHUB_REPO || '/branches/main/data',
      LOCATION=>'@GITHUB_REPO_DEMO_STUG_MELB_2024_IGGY/branches/main/data',
      FILE_FORMAT=>'MY_CSV_FORMAT',
      FILES=>'store_pct.csv'
    )
  )
);

-- load store_pct
COPY INTO STORE_PCT
--FROM '@' || $MY_GITHUB_REPO || '/branches/main/data'
FROM '@GITHUB_REPO_DEMO_STUG_MELB_2024_IGGY/branches/main/data'
FILES = ('store_pct.csv')
FILE_FORMAT = ( FORMAT_NAME = 'MY_CSV_FORMAT' );
