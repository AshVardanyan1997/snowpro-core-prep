-- =====================================================================
-- Day 1 lab: architecture, object hierarchy, parameters, storage
-- Run this in a Snowsight SQL worksheet on an Enterprise trial account.
-- It takes about 45 minutes and uses only a few cents of trial credits.
-- If SNOWFLAKE_SAMPLE_DATA is missing, create it from the Snowflake Marketplace
-- (search for "Snowflake Sample Data") or with:
--   CREATE DATABASE SNOWFLAKE_SAMPLE_DATA FROM SHARE SFC_SAMPLES.SAMPLE_DATA;  -- as ACCOUNTADMIN
-- =====================================================================

USE ROLE SYSADMIN;

-- ---------------------------------------------------------------------
-- 0. Setup: a warehouse and a database to work in
-- ---------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS DAY1_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS DAY1_DB;
CREATE SCHEMA IF NOT EXISTS DAY1_DB.LAB;
USE SCHEMA DAY1_DB.LAB;
USE WAREHOUSE DAY1_WH;

-- ---------------------------------------------------------------------
-- 1. Context functions (objective 1.3)
-- ---------------------------------------------------------------------
SELECT CURRENT_ACCOUNT(), CURRENT_REGION(), CURRENT_ROLE(),
       CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA();

-- Check: what does the account locator look like, compared with orgname-accountname?
SELECT CURRENT_ORGANIZATION_NAME(), CURRENT_ACCOUNT_NAME(), CURRENT_ACCOUNT();

-- ---------------------------------------------------------------------
-- 2. Parameter precedence (objective 1.3)
-- ---------------------------------------------------------------------
SHOW PARAMETERS LIKE 'TIMEZONE' IN ACCOUNT;
SHOW PARAMETERS LIKE 'TIMEZONE' IN SESSION;        -- look at the "level" column
ALTER SESSION SET TIMEZONE = 'Asia/Yerevan';
SHOW PARAMETERS LIKE 'TIMEZONE' IN SESSION;        -- level is now SESSION
ALTER SESSION UNSET TIMEZONE;

-- Object parameter: retention set at schema level, overridden at table level
ALTER SCHEMA DAY1_DB.LAB SET DATA_RETENTION_TIME_IN_DAYS = 3;
CREATE OR REPLACE TABLE T_INHERIT (id INT);
CREATE OR REPLACE TABLE T_OVERRIDE (id INT) DATA_RETENTION_TIME_IN_DAYS = 10;
SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS' IN TABLE T_INHERIT;   -- expect 3 (SCHEMA)
SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS' IN TABLE T_OVERRIDE;  -- expect 10 (TABLE)

-- ---------------------------------------------------------------------
-- 3. Metadata-only queries and the result cache (objective 1.1)
-- ---------------------------------------------------------------------
ALTER WAREHOUSE DAY1_WH SUSPEND;
-- These run against sample data that every account can read
SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;          -- answered from metadata
SELECT MIN(O_ORDERDATE), MAX(O_ORDERDATE)
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;                          -- also answered from metadata
-- In Query History, open each query: the profile shows "METADATA-BASED RESULT"

SELECT O_ORDERPRIORITY, COUNT(*), AVG(O_TOTALPRICE)
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
GROUP BY 1 ORDER BY 1;                     -- first run: the warehouse resumes and scans the data
-- Run exactly the same query again: the profile shows "QUERY RESULT REUSE" (from the result cache)

-- ---------------------------------------------------------------------
-- 4. Table types (objective 1.5)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE T_TRANSIENT (id INT);
CREATE OR REPLACE TEMPORARY TABLE T_TEMP (id INT);
SHOW TABLES LIKE 'T_%';    -- look at the "kind" column and retention_time

-- This should FAIL: transient tables allow at most 1 day of Time Travel
ALTER TABLE T_TRANSIENT SET DATA_RETENTION_TIME_IN_DAYS = 5;

-- A temporary table hides a permanent table with the same name, for this session only
INSERT INTO T_INHERIT VALUES (1);
CREATE TEMPORARY TABLE T_INHERIT (id INT);
SELECT COUNT(*) FROM T_INHERIT;            -- 0 rows: you're reading the temporary table
DROP TABLE T_INHERIT;                      -- drops the temporary one
SELECT COUNT(*) FROM T_INHERIT;            -- 1 row: the permanent table is visible again

-- ---------------------------------------------------------------------
-- 5. Micro-partitions and clustering (objective 1.5)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE ORDERS_COPY AS
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;

SELECT SYSTEM$CLUSTERING_INFORMATION('ORDERS_COPY', '(O_ORDERDATE)');
-- Read total_partition_count, average_overlaps and average_depth

-- Pruning: run this, then open Query Profile and compare
-- "Partitions scanned" with "Partitions total"
SELECT COUNT(*) FROM ORDERS_COPY WHERE O_ORDERDATE = '1995-03-15';

-- ---------------------------------------------------------------------
-- 6. View types (objective 1.5)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW V_STD AS
  SELECT O_ORDERKEY, O_TOTALPRICE FROM ORDERS_COPY;
CREATE OR REPLACE SECURE VIEW V_SECURE AS
  SELECT O_ORDERKEY, O_TOTALPRICE FROM ORDERS_COPY;
CREATE OR REPLACE MATERIALIZED VIEW MV_DAILY AS            -- requires Enterprise edition
  SELECT O_ORDERDATE, SUM(O_TOTALPRICE) AS REVENUE
  FROM ORDERS_COPY GROUP BY O_ORDERDATE;

SHOW VIEWS;                     -- is_secure and is_materialized columns
SHOW MATERIALIZED VIEWS;        -- refreshed_on and behind_by columns

-- This should FAIL: a materialized view can't contain a join
CREATE OR REPLACE MATERIALIZED VIEW MV_BAD AS
  SELECT o.O_ORDERKEY, c.C_NAME
  FROM ORDERS_COPY o JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER c
    ON o.O_CUSTKEY = c.C_CUSTKEY;

-- ---------------------------------------------------------------------
-- 7. Clean up
-- ---------------------------------------------------------------------
DROP DATABASE DAY1_DB;
DROP WAREHOUSE DAY1_WH;
