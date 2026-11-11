-- =====================================================================
-- Day 6 lab: streams, tasks and task graphs, dynamic tables, Snowpipe,
-- Time Travel and UNDROP, transient tables, cloning, and sharing
-- Run this in a Snowsight SQL worksheet on an Enterprise trial account.
-- It takes about 50 minutes and uses a few cents of credits.
-- IMPORTANT: run the cleanup in section 9 at the end. Sections 2 and 3
-- start a scheduled task and a dynamic table that keep running otherwise.
-- =====================================================================

-- SYSADMIN needs these account-level privileges to run tasks
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK, EXECUTE MANAGED TASK ON ACCOUNT TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
CREATE OR REPLACE WAREHOUSE DAY6_XS
  WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;
CREATE DATABASE IF NOT EXISTS DAY6_DB;
CREATE SCHEMA IF NOT EXISTS DAY6_DB.LAB;
USE SCHEMA DAY6_DB.LAB;
USE WAREHOUSE DAY6_XS;

CREATE OR REPLACE TABLE RAW_ORDERS AS
SELECT O_ORDERKEY AS ORDER_ID, O_CUSTKEY AS CUSTOMER_ID, O_TOTALPRICE AS AMOUNT,
       O_ORDERSTATUS AS STATUS, O_ORDERDATE AS ORDER_DATE
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
ORDER BY O_ORDERKEY LIMIT 1000;

CREATE OR REPLACE TABLE ORDERS LIKE RAW_ORDERS;   -- the clean target, empty

-- ---------------------------------------------------------------------
-- 1. Streams (3.2.3)
-- ---------------------------------------------------------------------
CREATE OR REPLACE STREAM RAW_ORDERS_STREAM ON TABLE RAW_ORDERS;               -- standard
CREATE OR REPLACE STREAM RAW_ORDERS_APPEND ON TABLE RAW_ORDERS APPEND_ONLY = TRUE;

SELECT COUNT(*) FROM RAW_ORDERS_STREAM;   -- 0: the offset starts "now", old rows aren't changes

-- Make some changes: 3 inserts, 1 update, 1 delete
INSERT INTO RAW_ORDERS VALUES
  (9000001, 1, 100.00, 'O', CURRENT_DATE()),
  (9000002, 2, 250.50, 'O', CURRENT_DATE()),
  (9000003, 3, 75.25,  'O', CURRENT_DATE());
UPDATE RAW_ORDERS SET STATUS = 'F' WHERE ORDER_ID = 9000001;
DELETE FROM RAW_ORDERS WHERE ORDER_ID = 1;

-- Standard stream: the NET change since the offset
SELECT ORDER_ID, STATUS, METADATA$ACTION, METADATA$ISUPDATE
FROM RAW_ORDERS_STREAM ORDER BY ORDER_ID;
-- Expect: order 1 DELETE, and 3 INSERTs (9000001 shows its latest status 'F',
-- because the insert and update both happened after the offset)

-- Append-only stream: inserts only, the delete is not there
SELECT ORDER_ID, METADATA$ACTION FROM RAW_ORDERS_APPEND ORDER BY ORDER_ID;

-- Update an OLD row (from before the stream) to see the DELETE + INSERT pair
UPDATE RAW_ORDERS SET STATUS = 'X' WHERE ORDER_ID = 2;
SELECT ORDER_ID, STATUS, METADATA$ACTION, METADATA$ISUPDATE
FROM RAW_ORDERS_STREAM WHERE ORDER_ID = 2;   -- two rows, ISUPDATE = TRUE

-- SELECT doesn't move the offset: run it twice, same answer
SELECT COUNT(*) FROM RAW_ORDERS_STREAM;
SELECT COUNT(*) FROM RAW_ORDERS_STREAM;

-- A DML statement that reads the stream DOES move the offset
INSERT INTO ORDERS
SELECT ORDER_ID, CUSTOMER_ID, AMOUNT, STATUS, ORDER_DATE
FROM RAW_ORDERS_STREAM WHERE METADATA$ACTION = 'INSERT';

SELECT COUNT(*) FROM RAW_ORDERS_STREAM;   -- 0: consumed
SELECT COUNT(*) FROM RAW_ORDERS_APPEND;   -- still 3: each stream has its own offset

SHOW STREAMS;   -- look at the "stale" and "stale_after" columns

-- ---------------------------------------------------------------------
-- 2. Tasks and a task graph (3.2.4)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE PIPELINE_LOG (STEP STRING, RAN_AT TIMESTAMP_LTZ);

-- Serverless (no WAREHOUSE), runs only when the stream has data
CREATE OR REPLACE TASK LOAD_ORDERS_TASK
  SCHEDULE = '60 MINUTE'
  WHEN SYSTEM$STREAM_HAS_DATA('DAY6_DB.LAB.RAW_ORDERS_STREAM')
AS
  INSERT INTO ORDERS
  SELECT ORDER_ID, CUSTOMER_ID, AMOUNT, STATUS, ORDER_DATE
  FROM RAW_ORDERS_STREAM WHERE METADATA$ACTION = 'INSERT';

-- Two children that run after the root, and a finalizer
CREATE OR REPLACE TASK LOG_CUSTOMERS_TASK
  AFTER LOAD_ORDERS_TASK
AS INSERT INTO PIPELINE_LOG VALUES ('customer totals', CURRENT_TIMESTAMP());

CREATE OR REPLACE TASK LOG_PRODUCTS_TASK
  AFTER LOAD_ORDERS_TASK
AS INSERT INTO PIPELINE_LOG VALUES ('product totals', CURRENT_TIMESTAMP());

CREATE OR REPLACE TASK FINAL_TASK
  FINALIZE = LOAD_ORDERS_TASK
AS INSERT INTO PIPELINE_LOG VALUES ('finalizer', CURRENT_TIMESTAMP());

SHOW TASKS;   -- every task: state = suspended

-- New data for the stream
INSERT INTO RAW_ORDERS VALUES (9000004, 4, 999.99, 'O', CURRENT_DATE());

-- Resume the children and finalizer, then the root, in one call
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('DAY6_DB.LAB.LOAD_ORDERS_TASK');
SHOW TASKS;   -- now started

-- Run the graph once now instead of waiting an hour
EXECUTE TASK LOAD_ORDERS_TASK;

-- Wait about a minute, then:
SELECT * FROM PIPELINE_LOG ORDER BY RAN_AT;   -- both children, then the finalizer
SELECT NAME, STATE, SCHEDULED_TIME, COMPLETED_TIME, ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
       SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP())))
ORDER BY SCHEDULED_TIME DESC;
SELECT COUNT(*) FROM ORDERS WHERE ORDER_ID = 9000004;   -- 1

-- EXPECTED FAILURE: you can't change a child while the root is running
ALTER TASK LOG_PRODUCTS_TASK SET COMMENT = 'try to change me';
-- Suspend the root first, then it works
ALTER TASK LOAD_ORDERS_TASK SUSPEND;
ALTER TASK LOG_PRODUCTS_TASK SET COMMENT = 'try to change me';

-- ---------------------------------------------------------------------
-- 3. Dynamic tables (3.2.5)
-- ---------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE CUSTOMER_TOTALS
  TARGET_LAG = DOWNSTREAM
  WAREHOUSE = DAY6_XS
AS
  SELECT CUSTOMER_ID, COUNT(*) AS ORDERS, SUM(AMOUNT) AS SPENT
  FROM ORDERS GROUP BY CUSTOMER_ID;

CREATE OR REPLACE DYNAMIC TABLE BIG_CUSTOMERS
  TARGET_LAG = '1 minute'
  WAREHOUSE = DAY6_XS
AS
  SELECT * FROM CUSTOMER_TOTALS WHERE SPENT > 200;

SHOW DYNAMIC TABLES;   -- look at target_lag, refresh_mode, scheduling_state

SELECT * FROM BIG_CUSTOMERS ORDER BY SPENT DESC LIMIT 5;

-- Add a big order, wait a minute or two, and query again
INSERT INTO ORDERS VALUES (9000005, 77777, 5000, 'O', CURRENT_DATE());
-- (after about 1–2 minutes)
SELECT * FROM BIG_CUSTOMERS WHERE CUSTOMER_ID = 77777;
SELECT NAME, STATE, REFRESH_ACTION, REFRESH_TRIGGER
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY())
ORDER BY REFRESH_START_TIME DESC LIMIT 10;

-- EXPECTED FAILURE: no DML on a dynamic table
INSERT INTO BIG_CUSTOMERS VALUES (1, 1, 1);

-- Stop the refreshes so they don't keep using credits
ALTER DYNAMIC TABLE BIG_CUSTOMERS SUSPEND;
ALTER DYNAMIC TABLE CUSTOMER_TOTALS SUSPEND;

-- ---------------------------------------------------------------------
-- 4. Snowpipe (3.2.1)
-- ---------------------------------------------------------------------
-- A trial has no cloud event notifications set up, so this pipe has
-- AUTO_INGEST = FALSE and is triggered by hand with REFRESH.
CREATE OR REPLACE STAGE PIPE_STAGE FILE_FORMAT = (TYPE = CSV);
CREATE OR REPLACE TABLE PIPE_ORDERS LIKE RAW_ORDERS;

CREATE OR REPLACE PIPE ORDERS_PIPE AS
  COPY INTO PIPE_ORDERS FROM @PIPE_STAGE;

-- EXPECTED FAILURE: pipes don't support ON_ERROR = ABORT_STATEMENT
CREATE OR REPLACE PIPE BAD_PIPE AS
  COPY INTO PIPE_ORDERS FROM @PIPE_STAGE ON_ERROR = ABORT_STATEMENT;

-- Put a file in the stage (by unloading 100 rows)
COPY INTO @PIPE_STAGE/orders_001.csv.gz
FROM (SELECT * FROM RAW_ORDERS LIMIT 100) SINGLE = TRUE;

ALTER PIPE ORDERS_PIPE REFRESH;            -- queue files staged in the last 7 days
SELECT SYSTEM$PIPE_STATUS('ORDERS_PIPE');  -- executionState, pendingFileCount

-- Wait about a minute (serverless, no warehouse), then:
SELECT COUNT(*) FROM PIPE_ORDERS;          -- 100
SELECT FILE_NAME, STATUS, ROW_COUNT, PIPE_NAME
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
       TABLE_NAME => 'PIPE_ORDERS',
       START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())));

-- Refresh again: the pipe remembers the file (14-day load metadata)
ALTER PIPE ORDERS_PIPE REFRESH;
-- (after a minute) still 100
SELECT COUNT(*) FROM PIPE_ORDERS;

-- ---------------------------------------------------------------------
-- 5. Time Travel and UNDROP (5.1.4)
-- ---------------------------------------------------------------------
SELECT COUNT(*) FROM RAW_ORDERS WHERE STATUS = 'F';   -- note this number

-- The "Friday mistake": delete the wrong status
DELETE FROM RAW_ORDERS WHERE STATUS = 'F';
SET BAD_QUERY = LAST_QUERY_ID();

SELECT COUNT(*) FROM RAW_ORDERS WHERE STATUS = 'F';                                   -- 0
SELECT COUNT(*) FROM RAW_ORDERS BEFORE(STATEMENT => $BAD_QUERY) WHERE STATUS = 'F';  -- back!
SELECT COUNT(*) FROM RAW_ORDERS AT(OFFSET => -60 * 5);   -- the table 5 minutes ago
-- (if the table is less than 5 minutes old this fails: the point is before it existed)

-- Restore the deleted rows
INSERT INTO RAW_ORDERS
SELECT * FROM RAW_ORDERS BEFORE(STATEMENT => $BAD_QUERY) WHERE STATUS = 'F';
SELECT COUNT(*) FROM RAW_ORDERS WHERE STATUS = 'F';   -- same as the first number

-- DROP and UNDROP
CREATE OR REPLACE TABLE PROMOTIONS (ID INT, NAME STRING);
INSERT INTO PROMOTIONS VALUES (1, 'Black Friday');
DROP TABLE PROMOTIONS;
SHOW TABLES HISTORY LIKE 'PROMOTIONS';   -- the dropped version has a dropped_on date

-- Someone creates a new PROMOTIONS table before you notice
CREATE TABLE PROMOTIONS (ID INT, NAME STRING);
-- EXPECTED FAILURE: the name is taken
UNDROP TABLE PROMOTIONS;
ALTER TABLE PROMOTIONS RENAME TO PROMOTIONS_NEW;
UNDROP TABLE PROMOTIONS;
SELECT * FROM PROMOTIONS;   -- Black Friday is back

-- ---------------------------------------------------------------------
-- 6. Retention, transient tables and Fail-safe (5.1.4, 5.1.5)
-- ---------------------------------------------------------------------
SHOW TABLES LIKE 'RAW_ORDERS';             -- retention_time = 1 (the default)
ALTER TABLE RAW_ORDERS SET DATA_RETENTION_TIME_IN_DAYS = 30;   -- OK on Enterprise (max 90)

CREATE OR REPLACE TRANSIENT TABLE STAGING_ORDERS (ORDER_ID NUMBER);
-- EXPECTED FAILURE: transient tables allow only 0 or 1 day
ALTER TABLE STAGING_ORDERS SET DATA_RETENTION_TIME_IN_DAYS = 30;
SHOW TABLES LIKE 'STAGING_ORDERS';         -- kind = TRANSIENT

-- Fail-safe bytes per table (ACCOUNT_USAGE, so up to a few hours behind)
SELECT TABLE_NAME, IS_TRANSIENT, ACTIVE_BYTES, TIME_TRAVEL_BYTES, FAILSAFE_BYTES
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
WHERE TABLE_CATALOG = 'DAY6_DB' AND DELETED = FALSE;

-- ---------------------------------------------------------------------
-- 7. Zero-copy cloning (5.1.3)
-- ---------------------------------------------------------------------
-- Leave some unconsumed changes in the stream before cloning
INSERT INTO RAW_ORDERS VALUES (9000006, 6, 60, 'O', CURRENT_DATE());
SELECT COUNT(*) FROM RAW_ORDERS_STREAM;    -- at least 1

CREATE OR REPLACE SCHEMA DAY6_DB.LAB_CLONE CLONE DAY6_DB.LAB;

SHOW TASKS IN SCHEMA DAY6_DB.LAB_CLONE;          -- all suspended
SELECT COUNT(*) FROM DAY6_DB.LAB_CLONE.RAW_ORDERS_STREAM;   -- the original's unconsumed changes aren't here
SHOW PIPES IN SCHEMA DAY6_DB.LAB_CLONE;          -- empty: the pipe used an internal stage
SHOW STAGES IN SCHEMA DAY6_DB.LAB_CLONE;         -- empty: internal stages need INCLUDE INTERNAL STAGES

-- The clone is independent
DELETE FROM DAY6_DB.LAB_CLONE.RAW_ORDERS;
SELECT (SELECT COUNT(*) FROM DAY6_DB.LAB.RAW_ORDERS)       AS original,
       (SELECT COUNT(*) FROM DAY6_DB.LAB_CLONE.RAW_ORDERS) AS clone;

-- Clone + Time Travel: a copy of the table as it was before the bad DELETE
CREATE OR REPLACE TABLE RAW_ORDERS_BEFORE_DELETE CLONE RAW_ORDERS
  BEFORE(STATEMENT => $BAD_QUERY);

-- ---------------------------------------------------------------------
-- 8. Secure Data Sharing and the Marketplace (5.2, 5.3)
-- ---------------------------------------------------------------------
-- A share needs ACCOUNTADMIN (or the CREATE SHARE privilege)
USE ROLE ACCOUNTADMIN;
USE SCHEMA DAY6_DB.LAB;

CREATE OR REPLACE VIEW DAILY_SALES_V AS          -- a normal view
  SELECT ORDER_DATE, SUM(AMOUNT) AS SALES FROM RAW_ORDERS GROUP BY 1;
CREATE OR REPLACE SECURE VIEW DAILY_SALES_SV AS  -- a secure view
  SELECT ORDER_DATE, SUM(AMOUNT) AS SALES FROM RAW_ORDERS GROUP BY 1;

CREATE OR REPLACE SHARE DAY6_SHARE;
GRANT USAGE ON DATABASE DAY6_DB TO SHARE DAY6_SHARE;
GRANT USAGE ON SCHEMA DAY6_DB.LAB TO SHARE DAY6_SHARE;

-- EXPECTED FAILURE: by default a share accepts only secure views, not normal ones
GRANT SELECT ON VIEW DAY6_DB.LAB.DAILY_SALES_V TO SHARE DAY6_SHARE;
GRANT SELECT ON VIEW DAY6_DB.LAB.DAILY_SALES_SV TO SHARE DAY6_SHARE;

SHOW SHARES LIKE 'DAY6_SHARE';      -- kind = OUTBOUND
SHOW GRANTS TO SHARE DAY6_SHARE;
-- To give it to a consumer in the same region you would run:
--   ALTER SHARE DAY6_SHARE ADD ACCOUNTS = <org_name>.<account_name>;
-- A reader account would be: CREATE MANAGED ACCOUNT ... TYPE = READER;
-- (not run here: it creates a real account that your account pays for)

-- Inbound shares: the SNOWFLAKE and SNOWFLAKE_SAMPLE_DATA databases are
-- shares you received from Snowflake
SHOW SHARES;                        -- look for kind = INBOUND

-- Consumer rules on an imported database
-- EXPECTED FAILURE: you can't clone a shared database
CREATE DATABASE SAMPLE_COPY CLONE SNOWFLAKE_SAMPLE_DATA;

-- Marketplace (in Snowsight, not SQL):
--   1. Open Marketplace from the left-hand menu.
--   2. Search for a free listing, for example a public holidays or weather dataset.
--   3. Click Get. A new database appears in your account. It's read-only,
--      and querying it uses your warehouse (you pay compute, not storage).

-- ---------------------------------------------------------------------
-- 9. Cleanup (run this!)
-- ---------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;
ALTER TASK IF EXISTS DAY6_DB.LAB.LOAD_ORDERS_TASK SUSPEND;
DROP SHARE IF EXISTS DAY6_SHARE;
DROP DATABASE IF EXISTS DAY6_DB;   -- tasks, streams, pipe, dynamic tables, clone schema
DROP WAREHOUSE IF EXISTS DAY6_XS;
REVOKE EXECUTE TASK, EXECUTE MANAGED TASK ON ACCOUNT FROM ROLE SYSADMIN;
