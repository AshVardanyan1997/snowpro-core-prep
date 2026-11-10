-- =====================================================================
-- Day 5 lab: masking and row access policies, aggregation policy, tags,
-- alerts, resource monitors, credit usage, stages, file formats,
-- COPY INTO with error handling, and unloading
-- Run this in a Snowsight SQL worksheet on an Enterprise trial account.
-- It takes about 55 minutes and uses a few cents of credits.
-- The lab switches between ACCOUNTADMIN and SYSADMIN on purpose, so you
-- can see the same query return different results for each role.
-- No local files needed: section 7 unloads sample data to a stage, and
-- the rest of the lab loads it back.
-- =====================================================================

USE ROLE SYSADMIN;
USE SECONDARY ROLES NONE;   -- so only the active role counts in this lab

CREATE OR REPLACE WAREHOUSE DAY5_XS
  WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;
CREATE DATABASE IF NOT EXISTS DAY5_DB;
CREATE SCHEMA IF NOT EXISTS DAY5_DB.LAB;
USE SCHEMA DAY5_DB.LAB;
USE WAREHOUSE DAY5_XS;

-- Test data, owned by SYSADMIN
CREATE OR REPLACE TABLE CUSTOMERS AS
SELECT C_CUSTKEY, C_NAME,
       LOWER(REPLACE(C_NAME, '#', '')) || '@example.com' AS C_EMAIL,
       C_PHONE, C_NATIONKEY, C_MKTSEGMENT, C_ACCTBAL
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER
LIMIT 1000;

CREATE OR REPLACE TABLE CUSTOMERS_AGG AS SELECT * FROM CUSTOMERS;

-- From here to section 6 you act as the security team.
-- In a real account, a dedicated role would hold APPLY MASKING POLICY,
-- APPLY ROW ACCESS POLICY and APPLY TAG instead of using ACCOUNTADMIN.
USE ROLE ACCOUNTADMIN;
USE SECONDARY ROLES NONE;

-- ---------------------------------------------------------------------
-- 1. Masking policy: column-level security (2.2.1.2)
-- ---------------------------------------------------------------------
CREATE OR REPLACE MASKING POLICY EMAIL_MASK AS (val STRING) RETURNS STRING ->
  CASE WHEN IS_ROLE_IN_SESSION('ACCOUNTADMIN') THEN val
       ELSE REGEXP_REPLACE(val, '.+@', '*****@')
  END;

ALTER TABLE CUSTOMERS MODIFY COLUMN C_EMAIL SET MASKING POLICY EMAIL_MASK;

SELECT C_NAME, C_EMAIL FROM CUSTOMERS LIMIT 5;      -- ACCOUNTADMIN: real emails

USE ROLE SYSADMIN;
USE SECONDARY ROLES NONE;
SELECT C_NAME, C_EMAIL FROM CUSTOMERS LIMIT 5;      -- SYSADMIN: *****@example.com
-- The table owner sees masked data. The policy, not ownership, decides.

-- The stored data is unchanged: a filter on the real value still works
SELECT COUNT(*) FROM CUSTOMERS WHERE C_EMAIL LIKE 'customer000000001%';

USE ROLE ACCOUNTADMIN;
USE SECONDARY ROLES NONE;

-- EXPECTED FAILURE: a column can have only one masking policy
CREATE OR REPLACE MASKING POLICY EMAIL_MASK_2 AS (val STRING) RETURNS STRING -> '***';
ALTER TABLE CUSTOMERS MODIFY COLUMN C_EMAIL SET MASKING POLICY EMAIL_MASK_2;

-- ---------------------------------------------------------------------
-- 2. Row access policy with a mapping table: row-level security (2.2.1.1)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE SEGMENT_ACCESS (ROLE_NAME STRING, SEGMENT STRING);
INSERT INTO SEGMENT_ACCESS VALUES ('SYSADMIN', 'BUILDING');

CREATE OR REPLACE ROW ACCESS POLICY SEGMENT_RAP AS (seg STRING) RETURNS BOOLEAN ->
  IS_ROLE_IN_SESSION('ACCOUNTADMIN')
  OR EXISTS (SELECT 1 FROM DAY5_DB.LAB.SEGMENT_ACCESS m
             WHERE m.ROLE_NAME = CURRENT_ROLE() AND m.SEGMENT = seg);

ALTER TABLE CUSTOMERS ADD ROW ACCESS POLICY SEGMENT_RAP ON (C_MKTSEGMENT);

SELECT C_MKTSEGMENT, COUNT(*) FROM CUSTOMERS GROUP BY 1;   -- ACCOUNTADMIN: 5 segments

USE ROLE SYSADMIN;
USE SECONDARY ROLES NONE;
SELECT C_MKTSEGMENT, COUNT(*) FROM CUSTOMERS GROUP BY 1;   -- SYSADMIN: BUILDING only
-- Row access ran first (BUILDING rows only), then masking (emails hidden):
SELECT C_MKTSEGMENT, C_EMAIL FROM CUSTOMERS LIMIT 5;
-- SYSADMIN can't read SEGMENT_ACCESS, but the policy still works,
-- because the policy body runs with the policy owner's privileges.

USE ROLE ACCOUNTADMIN;
USE SECONDARY ROLES NONE;

-- Where are the policies attached? (also ACCOUNT_USAGE.POLICY_REFERENCES)
SELECT POLICY_NAME, POLICY_KIND, REF_COLUMN_NAME, POLICY_STATUS
FROM TABLE(DAY5_DB.INFORMATION_SCHEMA.POLICY_REFERENCES(
       REF_ENTITY_NAME => 'DAY5_DB.LAB.CUSTOMERS', REF_ENTITY_DOMAIN => 'table'));

-- ---------------------------------------------------------------------
-- 3. Aggregation policy: a privacy policy (2.2.3)
-- ---------------------------------------------------------------------
CREATE OR REPLACE AGGREGATION POLICY MIN_GROUP_5
  AS () RETURNS AGGREGATION_CONSTRAINT ->
  CASE WHEN IS_ROLE_IN_SESSION('ACCOUNTADMIN') THEN NO_AGGREGATION_CONSTRAINT()
       ELSE AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 5)
  END;

ALTER TABLE CUSTOMERS_AGG SET AGGREGATION POLICY MIN_GROUP_5;

USE ROLE SYSADMIN;
USE SECONDARY ROLES NONE;
-- EXPECTED FAILURE: the policy requires the query to aggregate
SELECT * FROM CUSTOMERS_AGG LIMIT 5;
-- Works: every group has at least 5 rows
SELECT C_NATIONKEY, COUNT(*), ROUND(AVG(C_ACCTBAL), 2)
FROM CUSTOMERS_AGG GROUP BY 1 ORDER BY 1;

USE ROLE ACCOUNTADMIN;
USE SECONDARY ROLES NONE;

-- ---------------------------------------------------------------------
-- 4. Object tagging and tag-based masking (2.2.2)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TAG PII ALLOWED_VALUES 'email', 'phone';
CREATE OR REPLACE TAG COST_CENTER;

CREATE OR REPLACE MASKING POLICY PHONE_MASK AS (val STRING) RETURNS STRING ->
  CASE WHEN IS_ROLE_IN_SESSION('ACCOUNTADMIN') THEN val
       ELSE '***-***-' || RIGHT(val, 4)
  END;

-- Tag-based masking: protect every STRING column that carries the PII tag
ALTER TAG PII SET MASKING POLICY PHONE_MASK;
ALTER TABLE CUSTOMERS MODIFY COLUMN C_PHONE SET TAG PII = 'phone';

-- Tags for cost attribution
ALTER WAREHOUSE DAY5_XS SET TAG COST_CENTER = 'study';

-- Read the tags back
SELECT SYSTEM$GET_TAG('DAY5_DB.LAB.PII', 'DAY5_DB.LAB.CUSTOMERS.C_PHONE', 'COLUMN');
SELECT TAG_NAME, TAG_VALUE, COLUMN_NAME, APPLY_METHOD
FROM TABLE(DAY5_DB.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
       'DAY5_DB.LAB.CUSTOMERS', 'table'));

USE ROLE SYSADMIN;
USE SECONDARY ROLES NONE;
SELECT C_NAME, C_PHONE FROM CUSTOMERS LIMIT 5;   -- masked by the tag's policy

USE ROLE ACCOUNTADMIN;
USE SECONDARY ROLES NONE;

-- ---------------------------------------------------------------------
-- 5. Alerts (2.2.6)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE ALERT_LOG (FIRED_AT TIMESTAMP_LTZ, MESSAGE STRING);

-- No WAREHOUSE parameter, so the alert runs on serverless compute
CREATE OR REPLACE ALERT BIG_BALANCE_ALERT
  SCHEDULE = '60 MINUTE'
  IF (EXISTS (SELECT 1 FROM CUSTOMERS WHERE C_ACCTBAL > 9900))
  THEN INSERT INTO ALERT_LOG SELECT CURRENT_TIMESTAMP(), 'Customer balance over 9,900';

SHOW ALERTS;                      -- state = suspended: alerts start suspended
EXECUTE ALERT BIG_BALANCE_ALERT;  -- run it once now, without resuming the schedule

-- Wait a few seconds, then:
SELECT * FROM ALERT_LOG;
SELECT NAME, STATE, SCHEDULED_TIME, COMPLETED_TIME
FROM TABLE(INFORMATION_SCHEMA.ALERT_HISTORY(
       SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP())));
-- In a real alert the action would usually call SYSTEM$SEND_EMAIL or
-- SYSTEM$SEND_SNOWFLAKE_NOTIFICATION through a notification integration.

-- ---------------------------------------------------------------------
-- 6. Resource monitor and credit usage (2.3.1, 2.3.2, 2.3.3)
-- ---------------------------------------------------------------------
USE ROLE SYSADMIN;
-- EXPECTED FAILURE: only ACCOUNTADMIN can create resource monitors
CREATE RESOURCE MONITOR DAY5_RM_FAIL WITH CREDIT_QUOTA = 1;

USE ROLE ACCOUNTADMIN;
USE SECONDARY ROLES NONE;
CREATE OR REPLACE RESOURCE MONITOR DAY5_RM
  WITH CREDIT_QUOTA = 1
       FREQUENCY = DAILY
       START_TIMESTAMP = IMMEDIATELY
  TRIGGERS ON 50 PERCENT DO NOTIFY
           ON 90 PERCENT DO SUSPEND
           ON 110 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE DAY5_XS SET RESOURCE_MONITOR = DAY5_RM;
SHOW RESOURCE MONITORS;   -- look at credit_quota, used_credits, frequency, level

-- Real-time credit usage for the last 3 hours (INFORMATION_SCHEMA, no latency)
SELECT WAREHOUSE_NAME, START_TIME, CREDITS_USED, CREDITS_USED_COMPUTE,
       CREDITS_USED_CLOUD_SERVICES
FROM TABLE(DAY5_DB.INFORMATION_SCHEMA.WAREHOUSE_METERING_HISTORY(
       DATEADD('hour', -3, CURRENT_TIMESTAMP())))
ORDER BY START_TIME;

-- Same idea in ACCOUNT_USAGE: whole account, 1 year of history, but up to
-- 3 hours behind, so today's DAY5_XS may not be there yet.
SELECT WAREHOUSE_NAME, SUM(CREDITS_USED) AS CREDITS_LAST_30_DAYS
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1 ORDER BY 2 DESC;

-- Billed cloud services after the 10% daily adjustment
SELECT USAGE_DATE, CREDITS_USED_COMPUTE, CREDITS_USED_CLOUD_SERVICES,
       CREDITS_ADJUSTMENT_CLOUD_SERVICES, CREDITS_BILLED
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
ORDER BY USAGE_DATE DESC LIMIT 7;

-- Quick check of the formula: credits/hour × hours × clusters
SELECT 8 * (15/60)  AS large_15_min,      -- 2
       4 * 2 * 3    AS medium_2h_3_clusters; -- 24

-- ---------------------------------------------------------------------
-- 7. File formats and stages (3.1.1, 3.1.2)
-- ---------------------------------------------------------------------
USE ROLE SYSADMIN;
USE SECONDARY ROLES NONE;

CREATE OR REPLACE FILE FORMAT CSV_FMT
  TYPE = CSV
  FIELD_DELIMITER = ','
  NULL_IF = ('\\N', 'NULL')
  EMPTY_FIELD_AS_NULL = TRUE
  COMPRESSION = AUTO;

-- Named internal stage with a directory table. Encryption defaults to SNOWFLAKE_FULL.
CREATE OR REPLACE STAGE RAW_STAGE
  FILE_FORMAT = CSV_FMT
  DIRECTORY = (ENABLE = TRUE);
DESC STAGE RAW_STAGE;   -- find ENCRYPTION TYPE in the output

-- A server-side-only stage, the kind you need for presigned URLs
CREATE OR REPLACE STAGE SSE_STAGE ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Make two files to load (unloading is the reverse of loading)
-- File 1: 1,000 clean rows
COPY INTO @RAW_STAGE/good/orders_good.csv.gz
FROM (SELECT O_ORDERKEY, O_CUSTKEY, O_TOTALPRICE, O_ORDERDATE
      FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
      ORDER BY O_ORDERKEY LIMIT 1000)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FMT')
SINGLE = TRUE;

-- File 2: 1,000 rows where every 100th price is the text 'not_a_number'
COPY INTO @RAW_STAGE/bad/orders_bad.csv.gz
FROM (SELECT O_ORDERKEY, O_CUSTKEY,
             IFF(rn % 100 = 0, 'not_a_number', O_TOTALPRICE::STRING),
             O_ORDERDATE
      FROM (SELECT o.*, ROW_NUMBER() OVER (ORDER BY O_ORDERKEY) AS rn
            FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o
            WHERE O_ORDERKEY > 100000
            ORDER BY O_ORDERKEY LIMIT 1000))
FILE_FORMAT = (FORMAT_NAME = 'CSV_FMT')
SINGLE = TRUE;

LIST @RAW_STAGE;

-- Query staged files directly, before loading anything
SELECT METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, $1, $2, $3, $4
FROM @RAW_STAGE/bad/ (FILE_FORMAT => 'CSV_FMT')
WHERE $3 = 'not_a_number';

-- Directory table: refresh it, then query it
ALTER STAGE RAW_STAGE REFRESH;
SELECT RELATIVE_PATH, SIZE, LAST_MODIFIED FROM DIRECTORY(@RAW_STAGE);

-- Other stage types
LIST @~;                   -- your user stage
CREATE OR REPLACE TABLE ORDERS_LOAD (
  O_ORDERKEY NUMBER, O_CUSTKEY NUMBER, O_TOTALPRICE NUMBER(12,2), O_ORDERDATE DATE);
LIST @%ORDERS_LOAD;        -- the table stage, empty

-- ---------------------------------------------------------------------
-- 8. COPY INTO <table> with error handling (3.1.3, 3.1.4)
-- ---------------------------------------------------------------------

-- 8a. Validate without loading
COPY INTO ORDERS_LOAD FROM @RAW_STAGE
  VALIDATION_MODE = RETURN_ERRORS;          -- 10 errors, all from the bad file
COPY INTO ORDERS_LOAD FROM @RAW_STAGE
  FILES = ('good/orders_good.csv.gz')
  VALIDATION_MODE = RETURN_10_ROWS;         -- previews 10 parsed rows
SELECT COUNT(*) FROM ORDERS_LOAD;           -- 0: validation loads nothing

-- 8b. EXPECTED FAILURE: the default ON_ERROR = ABORT_STATEMENT stops everything
COPY INTO ORDERS_LOAD FROM @RAW_STAGE;
SELECT COUNT(*) FROM ORDERS_LOAD;           -- still 0, even the good file didn't load

-- 8c. SKIP_FILE: load clean files, skip any file with an error
COPY INTO ORDERS_LOAD FROM @RAW_STAGE ON_ERROR = 'SKIP_FILE';
-- Result: good file LOADED (1,000 rows), bad file LOAD_FAILED
SELECT COUNT(*) FROM ORDERS_LOAD;           -- 1000

-- 8d. CONTINUE: load the good rows of the bad file
COPY INTO ORDERS_LOAD FROM @RAW_STAGE
  FILES = ('bad/orders_bad.csv.gz') ON_ERROR = 'CONTINUE';
-- Result: PARTIALLY_LOADED, 990 rows loaded, 10 errors
SELECT * FROM TABLE(VALIDATE(ORDERS_LOAD, JOB_ID => '_last'));   -- the 10 rejected rows
SELECT COUNT(*) FROM ORDERS_LOAD;           -- 1990

-- 8e. Load metadata: running the same COPY again loads nothing new
COPY INTO ORDERS_LOAD FROM @RAW_STAGE ON_ERROR = 'CONTINUE';
SELECT COUNT(*) FROM ORDERS_LOAD;           -- still 1990

-- 8f. FORCE = TRUE ignores load metadata, so data is duplicated
COPY INTO ORDERS_LOAD FROM @RAW_STAGE
  FILES = ('good/orders_good.csv.gz') FORCE = TRUE;
SELECT COUNT(*), COUNT(DISTINCT O_ORDERKEY) FROM ORDERS_LOAD;   -- 2990 rows, 1990 keys

-- 8g. TRUNCATE clears the table AND its load metadata, so files load again
TRUNCATE TABLE ORDERS_LOAD;
COPY INTO ORDERS_LOAD FROM @RAW_STAGE
  FILES = ('good/orders_good.csv.gz')
  PURGE = TRUE;                             -- 8h. and delete the file after loading
SELECT COUNT(*) FROM ORDERS_LOAD;           -- 1000
LIST @RAW_STAGE;                            -- good/orders_good.csv.gz is gone

-- Load history for this table
SELECT FILE_NAME, STATUS, ROW_COUNT, ERROR_COUNT, FIRST_ERROR_MESSAGE, LAST_LOAD_TIME
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
       TABLE_NAME => 'ORDERS_LOAD',
       START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())))
ORDER BY LAST_LOAD_TIME;

-- 8i. Transformation during load: pick columns by position and skip the bad one
CREATE OR REPLACE TABLE ORDERS_SLIM (ORDER_ID NUMBER, ORDER_DATE DATE, SOURCE_FILE STRING);
COPY INTO ORDERS_SLIM
FROM (SELECT $1, $4, METADATA$FILENAME FROM @RAW_STAGE/bad/);
SELECT COUNT(*) FROM ORDERS_SLIM;           -- 1000: column 3 was never read

-- ---------------------------------------------------------------------
-- 9. Unloading: COPY INTO <location> (3.1.3)
-- ---------------------------------------------------------------------
-- Parquet, split into files, Snappy compression by default
COPY INTO @RAW_STAGE/export/parquet/orders_
FROM ORDERS_LOAD
FILE_FORMAT = (TYPE = PARQUET)
HEADER = TRUE;

-- CSV partitioned into folders by year
COPY INTO @RAW_STAGE/export/by_year/
FROM (SELECT * FROM ORDERS_LOAD)
PARTITION BY ('year=' || YEAR(O_ORDERDATE)::STRING)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FMT');

-- EXPECTED FAILURE: JSON unloads need a single VARIANT column
COPY INTO @RAW_STAGE/export/json/
FROM ORDERS_LOAD
FILE_FORMAT = (TYPE = JSON);

-- Works: build one VARIANT per row
COPY INTO @RAW_STAGE/export/json/
FROM (SELECT OBJECT_CONSTRUCT(*) FROM ORDERS_LOAD)
FILE_FORMAT = (TYPE = JSON);

LIST @RAW_STAGE/export/;   -- note the .snappy.parquet, .csv.gz and .json.gz names
-- To download from an internal stage you'd run GET from Snowflake CLI or SnowSQL:
--   GET @DAY5_DB.LAB.RAW_STAGE/export/json/ file:///tmp/day5/;
-- (GET and PUT don't run in a Snowsight worksheet.)

-- ---------------------------------------------------------------------
-- 10. Cleanup
-- ---------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;
ALTER ALERT DAY5_DB.LAB.BIG_BALANCE_ALERT SUSPEND;
DROP RESOURCE MONITOR IF EXISTS DAY5_RM;
DROP WAREHOUSE IF EXISTS DAY5_XS;
DROP DATABASE IF EXISTS DAY5_DB;   -- drops the policies, tags, alert, stages and their files
USE SECONDARY ROLES ALL;           -- back to the default
