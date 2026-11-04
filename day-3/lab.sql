-- =====================================================================
-- Day 3 lab: Query Profile, the three caches, spilling, pruning,
-- exploding joins, QAS, search optimization, ACCOUNT_USAGE views
-- Run this in a Snowsight SQL worksheet on an Enterprise trial account.
-- It takes about 50 minutes and uses well under one credit.
-- After each query marked [PROFILE], open Query History -> the query ->
-- Query Profile and answer the question in the comment.
-- =====================================================================

USE ROLE SYSADMIN;

CREATE OR REPLACE WAREHOUSE DAY3_XS
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS DAY3_DB;
CREATE SCHEMA IF NOT EXISTS DAY3_DB.LAB;
USE SCHEMA DAY3_DB.LAB;
USE WAREHOUSE DAY3_XS;

-- Tag every query in this session so you can find them later (4.1.3)
ALTER SESSION SET QUERY_TAG = 'day3_lab';

-- ---------------------------------------------------------------------
-- 1. The three caches (4.3)
-- ---------------------------------------------------------------------
-- 1a. Metadata cache: no warehouse needed
ALTER WAREHOUSE DAY3_XS SUSPEND;
SELECT COUNT(*), MIN(O_ORDERDATE), MAX(O_ORDERDATE)
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS;
-- [PROFILE] Expect a single METADATA-BASED RESULT node.
SHOW WAREHOUSES LIKE 'DAY3_XS';   -- still SUSPENDED

-- 1b. First run: the warehouse resumes and reads from remote storage
SELECT O_ORDERPRIORITY, COUNT(*) AS N, SUM(O_TOTALPRICE) AS REVENUE
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS
WHERE O_ORDERDATE BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 1 ORDER BY 1;
-- [PROFILE] Note "Percentage scanned from cache" (probably 0%) and the total time.

-- 1c. Exactly the same text again: the result cache answers
SELECT O_ORDERPRIORITY, COUNT(*) AS N, SUM(O_TOTALPRICE) AS REVENUE
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS
WHERE O_ORDERDATE BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 1 ORDER BY 1;
-- [PROFILE] Expect a single QUERY RESULT REUSE node.

-- 1d. Same query in lower case: is the result reused? (The docs say the text must match exactly.)
select o_orderpriority, count(*) as n, sum(o_totalprice) as revenue
from snowflake_sample_data.tpch_sf10.orders
where o_orderdate between '1995-01-01' and '1995-12-31'
group by 1 order by 1;
-- [PROFILE] If it ran, check "Percentage scanned from cache": now the WAREHOUSE cache helps.

-- 1e. Turn the result cache off and run again: warehouse cache only
ALTER SESSION SET USE_CACHED_RESULT = FALSE;
SELECT O_ORDERPRIORITY, COUNT(*) AS N, SUM(O_TOTALPRICE) AS REVENUE
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS
WHERE O_ORDERDATE BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 1 ORDER BY 1;
-- [PROFILE] Percentage scanned from cache should be high now.

-- 1f. Suspend, resume, run again: the warehouse cache is gone
ALTER WAREHOUSE DAY3_XS SUSPEND;
SELECT O_ORDERPRIORITY, COUNT(*) AS N, SUM(O_TOTALPRICE) AS REVENUE
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS
WHERE O_ORDERDATE BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 1 ORDER BY 1;
-- [PROFILE] Back to (near) 0% from cache. This is why BI warehouses keep a longer auto-suspend.

-- 1g. RESULT_SCAN: query the output of the previous statement as a table
SHOW WAREHOUSES LIKE 'DAY3%';
SELECT "name", "size", "auto_suspend"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- ---------------------------------------------------------------------
-- 2. Spilling (4.1.1.1.1)
--    A big sort and window function on an XS warehouse. Takes a few minutes.
-- ---------------------------------------------------------------------
SELECT L_ORDERKEY, L_LINENUMBER, L_EXTENDEDPRICE,
       ROW_NUMBER() OVER (ORDER BY L_EXTENDEDPRICE DESC, L_COMMENT) AS RN
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.LINEITEM
ORDER BY RN
LIMIT 10;
-- [PROFILE] Look under Spilling for "Bytes spilled to local storage" (and maybe remote).
--           Check the Query Insights pane too. What fix does the profile suggest?
SET SPILL_QID = LAST_QUERY_ID();

-- Now the fix: scale UP, then run the same thing
ALTER WAREHOUSE DAY3_XS SET WAREHOUSE_SIZE = MEDIUM;
SELECT L_ORDERKEY, L_LINENUMBER, L_EXTENDEDPRICE,
       ROW_NUMBER() OVER (ORDER BY L_EXTENDEDPRICE DESC, L_COMMENT) AS RN
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.LINEITEM
ORDER BY RN
LIMIT 10;
-- [PROFILE] Less or no spilling, and faster. Adding clusters would not have helped this one query.
ALTER WAREHOUSE DAY3_XS SET WAREHOUSE_SIZE = XSMALL;

-- ---------------------------------------------------------------------
-- 3. Pruning (4.1.1.1.2)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE ORDERS AS
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS
ORDER BY O_ORDERDATE;          -- loaded in date order, so it's naturally clustered by date

-- Good pruning: filter on the column the data is ordered by
SELECT COUNT(*), SUM(O_TOTALPRICE) FROM ORDERS WHERE O_ORDERDATE = '1996-06-01';
-- [PROFILE] TableScan: Partitions scanned vs Partitions total. Small fraction = good pruning.

-- Poor pruning: wrap the column in a function, or filter on an unrelated column
SELECT COUNT(*), SUM(O_TOTALPRICE) FROM ORDERS WHERE TO_CHAR(O_ORDERDATE, 'YYYY-MM-DD') = '1996-06-01';
SELECT COUNT(*), SUM(O_TOTALPRICE) FROM ORDERS WHERE O_CUSTKEY = 123456;
-- [PROFILE] Partitions scanned close to the total = inefficient pruning.

SELECT SYSTEM$CLUSTERING_INFORMATION('ORDERS', '(O_ORDERDATE)');   -- low average_depth
SELECT SYSTEM$CLUSTERING_INFORMATION('ORDERS', '(O_CUSTKEY)');     -- high average_depth

-- ---------------------------------------------------------------------
-- 4. Search optimization for the point lookup (4.2.2) - Enterprise
-- ---------------------------------------------------------------------
SELECT SYSTEM$ESTIMATE_SEARCH_OPTIMIZATION_COSTS('ORDERS', 'EQUALITY(O_CUSTKEY)');

ALTER TABLE ORDERS ADD SEARCH OPTIMIZATION ON EQUALITY(O_CUSTKEY);
SHOW TABLES LIKE 'ORDERS';     -- watch search_optimization_progress reach 100 (can take a few minutes)

-- When it's at 100, run the lookup again (different literal so the result cache can't answer)
SELECT COUNT(*), SUM(O_TOTALPRICE) FROM ORDERS WHERE O_CUSTKEY = 654321;
-- [PROFILE] Partitions scanned should now be tiny, and Query Insights may say it
--           "benefited from search optimization". No warehouse built the index: it's serverless.

-- ---------------------------------------------------------------------
-- 5. Exploding join (4.1.1.1.3)
-- ---------------------------------------------------------------------
-- Joining on a low-cardinality, non-unique column multiplies rows
SELECT COUNT(*)
FROM (SELECT * FROM ORDERS WHERE O_ORDERDATE = '1996-06-01') a
JOIN (SELECT * FROM ORDERS WHERE O_ORDERDATE = '1996-06-02') b
  ON a.O_ORDERPRIORITY = b.O_ORDERPRIORITY;
-- [PROFILE] The Join node outputs far more rows than it receives. Query Insights: "Exploding join".

-- The correct join on a key
SELECT COUNT(*)
FROM ORDERS o
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.CUSTOMER c ON o.O_CUSTKEY = c.C_CUSTKEY
WHERE o.O_ORDERDATE = '1996-06-01';

-- ---------------------------------------------------------------------
-- 6. Query Acceleration Service (4.2.1) - Enterprise
-- ---------------------------------------------------------------------
SHOW WAREHOUSES LIKE 'DAY3_XS';   -- enable_query_acceleration and query_acceleration_max_scale_factor
                                   -- (new warehouses now have QAS on, scale factor 8)

-- Would the big spilling query from section 2 have benefited from QAS?
SELECT PARSE_JSON(SYSTEM$ESTIMATE_QUERY_ACCELERATION($SPILL_QID));
-- Read "status" (eligible or ineligible), "ineligibleReason" and the estimated times per scale factor.

ALTER WAREHOUSE DAY3_XS SET ENABLE_QUERY_ACCELERATION = TRUE
                            QUERY_ACCELERATION_MAX_SCALE_FACTOR = 4;

-- ---------------------------------------------------------------------
-- 7. Materialized view and automatic rewrite (4.2.4) - Enterprise
-- ---------------------------------------------------------------------
CREATE OR REPLACE MATERIALIZED VIEW MV_DAILY_REVENUE AS
  SELECT O_ORDERDATE, SUM(O_TOTALPRICE) AS REVENUE, COUNT(*) AS N
  FROM ORDERS
  GROUP BY O_ORDERDATE;

-- Query the BASE TABLE, not the view
SELECT O_ORDERDATE, SUM(O_TOTALPRICE)
FROM ORDERS
WHERE O_ORDERDATE BETWEEN '1996-01-01' AND '1996-01-31'
GROUP BY O_ORDERDATE;
-- [PROFILE] Does the TableScan read MV_DAILY_REVENUE instead of ORDERS? That's the optimizer's rewrite.
--           (It may choose the base table if that's just as cheap.)

-- ---------------------------------------------------------------------
-- 8. Query history and attribution (4.1.2) - run as ACCOUNTADMIN
-- ---------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;
ALTER SESSION SET USE_CACHED_RESULT = TRUE;

-- Real time, last 7 days, your session only
SELECT QUERY_ID, LEFT(QUERY_TEXT, 60) AS QUERY, WAREHOUSE_SIZE, TOTAL_ELAPSED_TIME,
       BYTES_SPILLED_TO_LOCAL_STORAGE, BYTES_SPILLED_TO_REMOTE_STORAGE,
       PARTITIONS_SCANNED, PARTITIONS_TOTAL
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY_BY_SESSION(RESULT_LIMIT => 200))
WHERE QUERY_TAG = 'day3_lab'
ORDER BY START_TIME;

-- ACCOUNT_USAGE: 365 days, but up to 45 minutes behind. Run this at the end of the
-- session, or tomorrow, and compare how many of today's queries show up.
SELECT QUERY_ID, LEFT(QUERY_TEXT, 60) AS QUERY, WAREHOUSE_SIZE,
       QUEUED_OVERLOAD_TIME, PERCENTAGE_SCANNED_FROM_CACHE,
       BYTES_SPILLED_TO_LOCAL_STORAGE, BYTES_SPILLED_TO_REMOTE_STORAGE
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG = 'day3_lab'
ORDER BY START_TIME DESC;

-- Cost per query (up to 8 hours behind, excludes idle time): run this tomorrow
SELECT QUERY_ID, WAREHOUSE_NAME, CREDITS_ATTRIBUTED_COMPUTE, CREDITS_USED_QUERY_ACCELERATION
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
WHERE QUERY_TAG = 'day3_lab'
ORDER BY CREDITS_ATTRIBUTED_COMPUTE DESC;

-- Insights Snowflake attached to your queries (also may lag)
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_INSIGHTS LIMIT 50;   -- look at INSIGHT_TOPIC

-- ---------------------------------------------------------------------
-- 9. Clean up (keep DAY3_DB until you've run the ACCOUNT_USAGE queries if you like)
-- ---------------------------------------------------------------------
ALTER SESSION UNSET QUERY_TAG;
USE ROLE SYSADMIN;
DROP DATABASE DAY3_DB;
DROP WAREHOUSE DAY3_XS;
