-- =====================================================================
-- Day 4 lab: semi-structured data, FLATTEN, aggregates, window functions,
-- roles, secondary roles, managed access, network policies, directory tables
-- Run this in a Snowsight SQL worksheet on an Enterprise trial account.
-- It takes about 60 minutes and uses a few cents of credits.
-- Nothing here changes how YOU log in: the network policy in section 8 is
-- only attached to a test user that can't log in.
-- =====================================================================

USE ROLE SYSADMIN;

CREATE OR REPLACE WAREHOUSE DAY4_XS
  WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;
CREATE DATABASE IF NOT EXISTS DAY4_DB;
CREATE SCHEMA IF NOT EXISTS DAY4_DB.LAB;
USE SCHEMA DAY4_DB.LAB;
USE WAREHOUSE DAY4_XS;

-- ---------------------------------------------------------------------
-- 1. Semi-structured data: VARIANT and path notation (4.4.1)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE ORDERS_JSON (src VARIANT);

INSERT INTO ORDERS_JSON
SELECT PARSE_JSON(column1) FROM VALUES
('{"order_id": 1, "customer": {"name": "Ana", "country": "AM"},
   "order_date": "2026-11-01",
   "items": [{"sku": "A1", "qty": 2, "price": 10.5}, {"sku": "B7", "qty": 1, "price": 99}]}'),
('{"order_id": 2, "customer": {"name": "Ben", "country": "DE"},
   "order_date": "2026-11-02",
   "items": [{"sku": "A1", "qty": 5, "price": 10.5}]}'),
('{"order_id": 3, "customer": {"name": "Cleo", "country": "AM"},
   "order_date": "2026-11-02",
   "items": []}');

-- Colon, dot and bracket notation
SELECT src:order_id,
       src:customer.name,              -- VARIANT: shows "Ana" in double quotes
       src:customer.name::STRING,      -- cast: Ana
       src['customer']['country']::STRING,
       src:items[0].sku::STRING        -- arrays start at 0
FROM ORDERS_JSON;

-- Key names are case-sensitive: this returns NULL, not an error
SELECT src:Customer.Name FROM ORDERS_JSON;
-- Column names are not: this works
SELECT SRC:customer.name::STRING FROM ORDERS_JSON;

-- SQL NULL vs JSON null
SELECT PARSE_JSON(NULL) IS NULL       AS sql_null,     -- TRUE
       PARSE_JSON('null') IS NULL     AS json_null,    -- FALSE: it's a VARIANT null value
       TYPEOF(PARSE_JSON('null'))     AS type_of;      -- NULL_VALUE

-- Building values
SELECT OBJECT_CONSTRUCT('a', 1, 'b', 'x') AS obj,
       ARRAY_CONSTRUCT(1, 2, 3)           AS arr,
       TYPEOF(src)                        AS t
FROM ORDERS_JSON LIMIT 1;

-- ---------------------------------------------------------------------
-- 2. LATERAL FLATTEN (4.4.1)
-- ---------------------------------------------------------------------
SELECT o.src:order_id::INT        AS order_id,
       f.index                    AS position,
       f.value:sku::STRING        AS sku,
       f.value:qty::INT           AS qty,
       f.value:price::NUMBER(10,2) AS price
FROM ORDERS_JSON o,
     LATERAL FLATTEN(INPUT => o.src:items) f;
-- Question: where is order 3 (empty items array)?

SELECT o.src:order_id::INT AS order_id, f.value:sku::STRING AS sku
FROM ORDERS_JSON o,
     LATERAL FLATTEN(INPUT => o.src:items, OUTER => TRUE) f;
-- With OUTER => TRUE, order 3 comes back with a NULL sku.

-- Every key and path in a document
SELECT f.path, f.key, TYPEOF(f.value)
FROM ORDERS_JSON o, LATERAL FLATTEN(INPUT => o.src, RECURSIVE => TRUE) f
WHERE o.src:order_id = 1;

-- Extract to a typed table (better pruning for dates and numbers)
CREATE OR REPLACE TABLE ORDER_LINES AS
SELECT o.src:order_id::INT             AS order_id,
       o.src:customer.country::STRING  AS country,
       o.src:order_date::DATE          AS order_date,
       f.value:sku::STRING             AS sku,
       f.value:qty::INT                AS qty,
       f.value:price::NUMBER(10,2)     AS price
FROM ORDERS_JSON o, LATERAL FLATTEN(INPUT => o.src:items) f;

-- ---------------------------------------------------------------------
-- 3. Aggregates, estimation and ROLLUP (4.4.2)
-- ---------------------------------------------------------------------
SELECT country, sku, SUM(qty * price) AS revenue, GROUPING(sku) AS is_subtotal
FROM ORDER_LINES
GROUP BY ROLLUP (country, sku)
ORDER BY country NULLS LAST, sku NULLS LAST;
-- Rows with sku NULL and is_subtotal = 1 are per-country subtotals;
-- the row with both NULL is the grand total.

SELECT country, ARRAY_AGG(DISTINCT sku) AS skus, MAX_BY(sku, price) AS priciest_sku
FROM ORDER_LINES GROUP BY country;

-- Exact vs approximate distinct count on a bigger table
SELECT COUNT(DISTINCT O_CUSTKEY)        AS exact_count,
       APPROX_COUNT_DISTINCT(O_CUSTKEY) AS approx_count     -- HyperLogLog
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;

SELECT APPROX_TOP_K(O_ORDERPRIORITY, 3) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;

-- ---------------------------------------------------------------------
-- 4. Window functions and QUALIFY (4.4.4)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE SCORES (player STRING, team STRING, points INT, game_date DATE);
INSERT INTO SCORES VALUES
 ('Ani','Red',30,'2026-11-01'), ('Bo','Red',25,'2026-11-01'), ('Cy','Red',25,'2026-11-01'),
 ('Di','Red',20,'2026-11-01'), ('Ed','Blue',40,'2026-11-01'), ('Fa','Blue',10,'2026-11-01'),
 ('Ani','Red',12,'2026-11-02'), ('Ed','Blue',33,'2026-11-02');

-- Ranking: compare the three on the tie between Bo and Cy
SELECT player, team, points,
       ROW_NUMBER() OVER (PARTITION BY team ORDER BY points DESC) AS row_num,
       RANK()       OVER (PARTITION BY team ORDER BY points DESC) AS rnk,
       DENSE_RANK() OVER (PARTITION BY team ORDER BY points DESC) AS dense_rnk
FROM SCORES WHERE game_date = '2026-11-01';

-- Running total and LAG
SELECT player, game_date, points,
       SUM(points) OVER (PARTITION BY player ORDER BY game_date
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
       LAG(points) OVER (PARTITION BY player ORDER BY game_date)           AS previous_game
FROM SCORES ORDER BY player, game_date;

-- Top scorer per team with QUALIFY (no subquery)
SELECT player, team, points
FROM SCORES
WHERE game_date = '2026-11-01'
QUALIFY ROW_NUMBER() OVER (PARTITION BY team ORDER BY points DESC) = 1;

-- ---------------------------------------------------------------------
-- 5. Build a role hierarchy the recommended way (2.1.1, 2.1.6, 2.1.7)
-- ---------------------------------------------------------------------
USE ROLE USERADMIN;                         -- creates roles and users
CREATE OR REPLACE ROLE DAY4_SALES_READ;      -- access role
CREATE OR REPLACE ROLE DAY4_ANALYST;         -- functional role
GRANT ROLE DAY4_SALES_READ TO ROLE DAY4_ANALYST;   -- analyst inherits read
GRANT ROLE DAY4_ANALYST TO ROLE SYSADMIN;          -- best practice: roll up to SYSADMIN

-- A test user that cannot log in (no password, no key)
CREATE OR REPLACE USER DAY4_TEST_USER TYPE = PERSON DEFAULT_ROLE = DAY4_ANALYST;
GRANT ROLE DAY4_ANALYST TO USER DAY4_TEST_USER;

-- Object privileges are granted by the owner (SYSADMIN owns DAY4_DB) or SECURITYADMIN
USE ROLE SYSADMIN;
GRANT USAGE ON DATABASE DAY4_DB TO ROLE DAY4_SALES_READ;
GRANT USAGE ON SCHEMA DAY4_DB.LAB TO ROLE DAY4_SALES_READ;
GRANT SELECT ON TABLE DAY4_DB.LAB.ORDER_LINES TO ROLE DAY4_SALES_READ;
GRANT USAGE ON WAREHOUSE DAY4_XS TO ROLE DAY4_ANALYST;

SHOW GRANTS TO ROLE DAY4_SALES_READ;
SHOW GRANTS TO ROLE DAY4_ANALYST;      -- shows the inherited role
SHOW GRANTS OF ROLE DAY4_ANALYST;      -- who has it: SYSADMIN and the test user

-- Who owns what?
SHOW TABLES IN SCHEMA DAY4_DB.LAB;     -- "owner" column = the role that created it

-- Database roles: scoped to one database, can't be activated directly
CREATE OR REPLACE DATABASE ROLE DAY4_DB.DB_READER;
GRANT USAGE ON SCHEMA DAY4_DB.LAB TO DATABASE ROLE DAY4_DB.DB_READER;
GRANT SELECT ON ALL TABLES IN SCHEMA DAY4_DB.LAB TO DATABASE ROLE DAY4_DB.DB_READER;
GRANT DATABASE ROLE DAY4_DB.DB_READER TO ROLE DAY4_ANALYST;
-- This should FAIL: you can't USE a database role
USE ROLE DAY4_DB.DB_READER;

-- ---------------------------------------------------------------------
-- 6. Primary vs secondary roles (2.1.8)
-- ---------------------------------------------------------------------
USE ROLE SECURITYADMIN;
CREATE OR REPLACE ROLE DAY4_ROLE_A;
CREATE OR REPLACE ROLE DAY4_ROLE_B;
GRANT ROLE DAY4_ROLE_A TO ROLE SYSADMIN;
GRANT ROLE DAY4_ROLE_B TO ROLE SYSADMIN;
SET ME = CURRENT_USER();
GRANT ROLE DAY4_ROLE_A TO USER IDENTIFIER($ME);
GRANT ROLE DAY4_ROLE_B TO USER IDENTIFIER($ME);

USE ROLE SYSADMIN;
CREATE OR REPLACE SCHEMA DAY4_DB.SEC;
CREATE OR REPLACE TABLE DAY4_DB.SEC.T_A (x INT);
CREATE OR REPLACE TABLE DAY4_DB.SEC.T_B (y INT);
GRANT USAGE ON DATABASE DAY4_DB TO ROLE DAY4_ROLE_A;
GRANT USAGE ON DATABASE DAY4_DB TO ROLE DAY4_ROLE_B;
GRANT USAGE ON SCHEMA DAY4_DB.SEC TO ROLE DAY4_ROLE_A;
GRANT USAGE ON SCHEMA DAY4_DB.SEC TO ROLE DAY4_ROLE_B;
GRANT SELECT ON TABLE DAY4_DB.SEC.T_A TO ROLE DAY4_ROLE_A;
GRANT SELECT ON TABLE DAY4_DB.SEC.T_B TO ROLE DAY4_ROLE_B;
GRANT USAGE ON WAREHOUSE DAY4_XS TO ROLE DAY4_ROLE_A;

USE ROLE DAY4_ROLE_A;
USE SECONDARY ROLES NONE;
SELECT * FROM DAY4_DB.SEC.T_A, DAY4_DB.SEC.T_B;     -- FAILS: role A can't read T_B

USE SECONDARY ROLES ALL;
SELECT CURRENT_ROLE(), CURRENT_SECONDARY_ROLES();
SELECT * FROM DAY4_DB.SEC.T_A, DAY4_DB.SEC.T_B;     -- WORKS: role B authorizes T_B

-- CREATE uses the primary role only
CREATE TABLE DAY4_DB.SEC.T_NEW (z INT);  -- FAILS: role A has no CREATE TABLE on the schema,
                                         -- even though SYSADMIN (a secondary role) has it
USE SECONDARY ROLES NONE;

-- ---------------------------------------------------------------------
-- 7. Managed access schema and future grants (2.1.2)
-- ---------------------------------------------------------------------
USE ROLE SYSADMIN;
CREATE OR REPLACE SCHEMA DAY4_DB.MANAGED WITH MANAGED ACCESS;
GRANT USAGE ON SCHEMA DAY4_DB.MANAGED TO ROLE DAY4_ROLE_A;
GRANT CREATE TABLE ON SCHEMA DAY4_DB.MANAGED TO ROLE DAY4_ROLE_A;

USE ROLE DAY4_ROLE_A;
CREATE TABLE DAY4_DB.MANAGED.MINE (id INT);        -- role A owns this table...
GRANT SELECT ON TABLE DAY4_DB.MANAGED.MINE TO ROLE DAY4_ROLE_B;
-- ...but this GRANT FAILS: in a managed access schema only the schema owner
-- (SYSADMIN here) or a role with MANAGE GRANTS can grant.

USE ROLE SYSADMIN;
GRANT SELECT ON TABLE DAY4_DB.MANAGED.MINE TO ROLE DAY4_ROLE_B;   -- works

-- Future grants: every table created later in LAB is readable by the read role
USE ROLE SECURITYADMIN;
GRANT SELECT ON FUTURE TABLES IN SCHEMA DAY4_DB.LAB TO ROLE DAY4_SALES_READ;
SHOW FUTURE GRANTS IN SCHEMA DAY4_DB.LAB;

-- ---------------------------------------------------------------------
-- 8. Network rule and policy, attached to the test user only (2.1.4)
--    ACCOUNTADMIN here because the rule lives in SYSADMIN's database and the
--    policy is normally SECURITYADMIN's job; ACCOUNTADMIN has both.
-- ---------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE NETWORK RULE DAY4_DB.LAB.OFFICE_RANGE
  TYPE = IPV4 MODE = INGRESS VALUE_LIST = ('203.0.113.0/24');   -- a documentation-only range
CREATE OR REPLACE NETWORK POLICY DAY4_OFFICE_ONLY
  ALLOWED_NETWORK_RULE_LIST = ('DAY4_DB.LAB.OFFICE_RANGE');
ALTER USER DAY4_TEST_USER SET NETWORK_POLICY = DAY4_OFFICE_ONLY;   -- user level: beats any account policy
DESCRIBE NETWORK POLICY DAY4_OFFICE_ONLY;
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN USER DAY4_TEST_USER;
-- Do NOT run ALTER ACCOUNT SET NETWORK_POLICY here: it would apply to you too.

-- ---------------------------------------------------------------------
-- 9. Identifiers, users and event table (2.1.5, 2.1.9, 2.1.10)
-- ---------------------------------------------------------------------
SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME() AS preferred_identifier,
       CURRENT_ACCOUNT() AS account_locator, CURRENT_REGION() AS region;

USE ROLE USERADMIN;
DESCRIBE USER DAY4_TEST_USER;    -- look at TYPE, HAS_PASSWORD, HAS_MFA, RSA_PUBLIC_KEY

USE ROLE ACCOUNTADMIN;
SHOW PARAMETERS LIKE 'EVENT_TABLE' IN ACCOUNT;    -- expect SNOWFLAKE.TELEMETRY.EVENTS
SHOW PARAMETERS LIKE 'LOG_LEVEL' IN ACCOUNT;      -- default OFF
SHOW PARAMETERS LIKE 'TRACE_LEVEL' IN ACCOUNT;

-- ---------------------------------------------------------------------
-- 10. Optional: directory table and file URLs (4.4.1 unstructured)
-- ---------------------------------------------------------------------
USE ROLE SYSADMIN;
CREATE OR REPLACE STAGE DAY4_DB.LAB.DOCS
  DIRECTORY = (ENABLE = TRUE)
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');     -- needed for URL access on an internal stage
-- In Snowsight: Data > Databases > DAY4_DB > LAB > Stages > DOCS > + Files, upload any PDF or image. Then:
ALTER STAGE DAY4_DB.LAB.DOCS REFRESH;
SELECT RELATIVE_PATH, SIZE, LAST_MODIFIED, FILE_URL FROM DIRECTORY(@DAY4_DB.LAB.DOCS);
SELECT RELATIVE_PATH,
       BUILD_SCOPED_FILE_URL(@DAY4_DB.LAB.DOCS, RELATIVE_PATH) AS scoped_url,      -- you only, 24 h
       GET_PRESIGNED_URL(@DAY4_DB.LAB.DOCS, RELATIVE_PATH, 600) AS presigned_url   -- anyone, 10 min
FROM DIRECTORY(@DAY4_DB.LAB.DOCS);

-- ---------------------------------------------------------------------
-- 11. Clean up
-- ---------------------------------------------------------------------
USE ROLE SECURITYADMIN;
ALTER USER DAY4_TEST_USER UNSET NETWORK_POLICY;
DROP NETWORK POLICY DAY4_OFFICE_ONLY;
DROP USER DAY4_TEST_USER;
DROP ROLE DAY4_ANALYST;
DROP ROLE DAY4_SALES_READ;
DROP ROLE DAY4_ROLE_A;
DROP ROLE DAY4_ROLE_B;
USE ROLE SYSADMIN;
DROP DATABASE DAY4_DB;
DROP WAREHOUSE DAY4_XS;
