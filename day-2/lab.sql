-- =====================================================================
-- Day 2 lab: virtual warehouses, scaling policies, Cortex AI functions
-- Run this in a Snowsight SQL worksheet on an Enterprise trial account.
-- It takes about 50 minutes and uses well under one credit of trial credits.
-- Every warehouse is created INITIALLY_SUSPENDED and AUTO_SUSPEND = 60,
-- so nothing bills while you read.
-- =====================================================================

USE ROLE SYSADMIN;

-- ---------------------------------------------------------------------
-- 0. Setup
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS DAY2_DB;
CREATE SCHEMA IF NOT EXISTS DAY2_DB.LAB;
USE SCHEMA DAY2_DB.LAB;

-- ---------------------------------------------------------------------
-- 1. Create warehouses of each kind (objective 1.4.1)
-- ---------------------------------------------------------------------
CREATE OR REPLACE WAREHOUSE DAY2_XS
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- Defaults: create one without options and see what you get
CREATE OR REPLACE WAREHOUSE DAY2_DEFAULTS INITIALLY_SUSPENDED = TRUE;
SHOW WAREHOUSES LIKE 'DAY2_%';
-- Check: size, auto_suspend (expect 600 for DAY2_DEFAULTS), auto_resume,
-- min_cluster_count, max_cluster_count, scaling_policy, type, state

-- Gen 2 standard warehouse (if your region doesn't support it yet, this errors: note it and move on)
CREATE OR REPLACE WAREHOUSE DAY2_GEN2
  WAREHOUSE_SIZE = XSMALL
  RESOURCE_CONSTRAINT = STANDARD_GEN_2
  AUTO_SUSPEND = 60
  INITIALLY_SUSPENDED = TRUE;

-- Snowpark-optimized warehouse: created suspended only, so it never bills here
CREATE OR REPLACE WAREHOUSE DAY2_SNOWPARK
  WAREHOUSE_SIZE = MEDIUM
  WAREHOUSE_TYPE = 'SNOWPARK-OPTIMIZED'
  AUTO_SUSPEND = 60
  INITIALLY_SUSPENDED = TRUE;

SHOW WAREHOUSES LIKE 'DAY2_%';   -- compare the "type" and "resource_constraint" columns

-- ---------------------------------------------------------------------
-- 2. Multi-cluster warehouses and scaling policies (objectives 1.4.2, 1.4.3.3)
--    Needs Enterprise edition or above.
-- ---------------------------------------------------------------------
-- Auto-scale mode: MIN < MAX, Standard policy (performance first)
CREATE OR REPLACE WAREHOUSE DAY2_BI
  WAREHOUSE_SIZE = XSMALL
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 3
  SCALING_POLICY = STANDARD
  AUTO_SUSPEND = 300            -- longer, to keep the cache warm for dashboards
  INITIALLY_SUSPENDED = TRUE;

-- Switch it to Economy (cost first)
ALTER WAREHOUSE DAY2_BI SET SCALING_POLICY = ECONOMY;

-- Maximized mode: MIN = MAX, every cluster starts with the warehouse
ALTER WAREHOUSE DAY2_BI SET MIN_CLUSTER_COUNT = 2 MAX_CLUSTER_COUNT = 2;
SHOW WAREHOUSES LIKE 'DAY2_BI';
-- Put it back to auto-scale before you use it
ALTER WAREHOUSE DAY2_BI SET MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 3;

-- Question to answer for yourself: what error would a Standard-edition account
-- give for MAX_CLUSTER_COUNT = 3? (Multi-cluster is an Enterprise feature.)

-- ---------------------------------------------------------------------
-- 3. Scale up: same query on XS and on M (objective 1.4.4.1)
-- ---------------------------------------------------------------------
ALTER SESSION SET USE_CACHED_RESULT = FALSE;   -- so the second run really runs
USE WAREHOUSE DAY2_XS;

SELECT L_RETURNFLAG, L_LINESTATUS,
       SUM(L_QUANTITY), SUM(L_EXTENDEDPRICE), AVG(L_DISCOUNT), COUNT(*)
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.LINEITEM
GROUP BY 1, 2
ORDER BY 1, 2;
-- Note the duration in the results pane

ALTER WAREHOUSE DAY2_XS SET WAREHOUSE_SIZE = MEDIUM;   -- resize while it's running
-- Run the same query again and compare the duration.
-- About 4x the compute; is it about 4x faster? (Roughly the same credits per query.)

ALTER WAREHOUSE DAY2_XS SET WAREHOUSE_SIZE = XSMALL;   -- scale back down
ALTER SESSION UNSET USE_CACHED_RESULT;

-- ---------------------------------------------------------------------
-- 4. Suspend, resume and the parameters that protect a warehouse (1.4.4)
-- ---------------------------------------------------------------------
ALTER WAREHOUSE DAY2_XS SUSPEND;
SHOW WAREHOUSES LIKE 'DAY2_XS';          -- state = SUSPENDED
SELECT CURRENT_TIMESTAMP;                 -- no table, so no warehouse needed
SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;   -- metadata: still no resume
SHOW WAREHOUSES LIKE 'DAY2_XS';          -- still SUSPENDED

ALTER WAREHOUSE DAY2_XS SET
  STATEMENT_TIMEOUT_IN_SECONDS = 600            -- kill anything running longer than 10 min
  STATEMENT_QUEUED_TIMEOUT_IN_SECONDS = 120;    -- give up after 2 min in the queue
SHOW PARAMETERS IN WAREHOUSE DAY2_XS;           -- also see MAX_CONCURRENCY_LEVEL (default 8)

-- Credits used so far by today's warehouses (INFORMATION_SCHEMA is real time)
SELECT WAREHOUSE_NAME, SUM(CREDITS_USED) AS CREDITS
FROM TABLE(INFORMATION_SCHEMA.WAREHOUSE_METERING_HISTORY(
       DATE_RANGE_START => DATEADD('hour', -3, CURRENT_TIMESTAMP())))
WHERE WAREHOUSE_NAME LIKE 'DAY2_%'
GROUP BY 1;

-- ---------------------------------------------------------------------
-- 5. Warehouse privileges (preview of Day 4)
-- ---------------------------------------------------------------------
USE ROLE SECURITYADMIN;
CREATE ROLE IF NOT EXISTS DAY2_ANALYST;
GRANT ROLE DAY2_ANALYST TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE DAY2_XS TO ROLE DAY2_ANALYST;     -- can run queries
GRANT OPERATE ON WAREHOUSE DAY2_BI TO ROLE DAY2_ANALYST;   -- can suspend and resume
SHOW GRANTS TO ROLE DAY2_ANALYST;
USE ROLE SYSADMIN;

-- ---------------------------------------------------------------------
-- 6. Cortex AI SQL functions (objective 1.6.4.1)
--    If you get "model not available in your region", run this as ACCOUNTADMIN:
--      ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
--    Each call costs a tiny number of tokens on these few rows.
-- ---------------------------------------------------------------------
USE WAREHOUSE DAY2_XS;

CREATE OR REPLACE TABLE REVIEWS (id INT, review STRING);
INSERT INTO REVIEWS VALUES
  (1, 'The dashboard loads instantly now, great job on the upgrade.'),
  (2, 'Support took four days to answer and the issue is still not fixed.'),
  (3, 'Pricing is fine, but the setup documentation was confusing.'),
  (4, 'La aplicación funciona bien pero a veces es lenta.');

SELECT id,
       review,
       AI_SENTIMENT(review)                                        AS sentiment,
       SNOWFLAKE.CORTEX.SENTIMENT(review)                          AS legacy_score,   -- -1 to 1
       AI_CLASSIFY(review, ['performance', 'support', 'pricing', 'documentation']) AS topic,
       AI_TRANSLATE(review, '', 'en')                              AS english          -- '' = detect the source language
FROM REVIEWS;

-- Natural-language filter
SELECT id, review
FROM REVIEWS
WHERE AI_FILTER(PROMPT('Is this review a complaint? {0}', review));

-- One summary across all rows
SELECT AI_SUMMARIZE_AGG(review) AS summary FROM REVIEWS;

-- A free-form prompt to an LLM
SELECT AI_COMPLETE('mistral-large2',
       'In one sentence, when should a Snowflake user scale up a warehouse instead of scaling out?') AS answer;

-- Who can use Cortex? Look for SNOWFLAKE.CORTEX_USER granted to PUBLIC
USE ROLE ACCOUNTADMIN;
SHOW GRANTS OF DATABASE ROLE SNOWFLAKE.CORTEX_USER;
USE ROLE SYSADMIN;

-- Token usage and credits for Cortex functions show up here (with latency):
-- SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_FUNCTIONS_USAGE_HISTORY ORDER BY START_TIME DESC;

-- ---------------------------------------------------------------------
-- 7. Optional, 10 minutes: Snowflake CLI on your laptop (objective 1.2.2)
--    Not SQL: run these in a terminal after `pip install snowflake-cli`
-- ---------------------------------------------------------------------
--   snow --version
--   snow connection add                         -- answer the prompts (account = orgname-accountname)
--   snow connection test
--   snow sql -q "SELECT CURRENT_ACCOUNT_NAME(), CURRENT_WAREHOUSE()"
--   snow object list warehouse --like 'DAY2_%'
--   snow streamlit --help                       -- see the deploy commands
--
-- Optional too: in Snowsight, open Projects > Notebooks > + Notebook, add a SQL cell
-- and a Python cell, and read the SQL cell's result in Python with cell1.to_pandas().

-- ---------------------------------------------------------------------
-- 8. Clean up
-- ---------------------------------------------------------------------
USE ROLE SYSADMIN;
DROP DATABASE DAY2_DB;
DROP WAREHOUSE DAY2_XS;
DROP WAREHOUSE DAY2_DEFAULTS;
DROP WAREHOUSE IF EXISTS DAY2_GEN2;
DROP WAREHOUSE DAY2_SNOWPARK;
DROP WAREHOUSE DAY2_BI;
USE ROLE SECURITYADMIN;
DROP ROLE DAY2_ANALYST;
