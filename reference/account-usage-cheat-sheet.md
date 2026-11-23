# Cheat sheet · ACCOUNT_USAGE vs INFORMATION_SCHEMA, and which view answers what

Checked against the [Account Usage](https://docs.snowflake.com/en/sql-reference/account-usage) docs on Nov 23, 2026. Covers Mock 1 Q47 and Q50, and objectives 2.3.3 and 4.1.2.

---

## 1. The two places to look

Snowflake keeps metadata in two places. They answer the same kinds of questions with opposite trade-offs.

| | **SNOWFLAKE.ACCOUNT_USAGE** | **<database>.INFORMATION_SCHEMA** |
|---|---|---|
| Where it is | One shared database, `SNOWFLAKE`, for the whole account | Inside **every** database, created automatically |
| What it covers | **The whole account** | **That one database** (plus account-level items like warehouses, through table functions) |
| Dropped objects | **Included** | **Not included**, only what exists now |
| Latency | **45 minutes to 3 hours**, depending on the view. Most views are about 2 hours | **None**: real time |
| History kept | **1 year** | **7 days to 6 months**, depending on the view or function |
| Who can read it | ACCOUNTADMIN by default. Others need SNOWFLAKE database roles (USAGE_VIEWER, GOVERNANCE_VIEWER, SECURITY_VIEWER, OBJECT_VIEWER) or IMPORTED PRIVILEGES | Anyone, but they only see objects their role has privileges on |
| Form | Views: `SELECT … FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY` | Views (TABLES, COLUMNS…) and **table functions**: `SELECT … FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())` |

**Memory hook: ACCOUNT_USAGE is the archive** (everything, a year back, a few hours late). **INFORMATION_SCHEMA is the live window** (right now, recent, this database only).

Exam clues to watch for:
- "dropped", "deleted user", "months ago", "whole account" → **ACCOUNT_USAGE**
- "right now", "the query I just ran", "no delay" → **INFORMATION_SCHEMA**

Also good to know: **Snowsight Query History** shows **14 days**.

---

## 2. Which view answers which question

| The question | Where to look | Notes |
|---|---|---|
| What SQL ran, who ran it, how long it took, how many bytes it scanned | **QUERY_HISTORY** | ACCOUNT_USAGE: 1 year, about 45 min behind. INFORMATION_SCHEMA function: 7 days, real time |
| How many **credits** did a single query use? | **QUERY_ATTRIBUTION_HISTORY** | ACCOUNT_USAGE only. Excludes idle time and very short queries. Up to about 8 hours behind |
| Which **tables and columns** did a query read or write? Who read column X? | **ACCESS_HISTORY** | ACCOUNT_USAGE only, **Enterprise**. See section 3 |
| Who logged in, from where, did it fail, with what method? | **LOGIN_HISTORY** | ACCOUNT_USAGE 1 year. INFORMATION_SCHEMA function: 7 days |
| Credits per warehouse per hour | **WAREHOUSE_METERING_HISTORY** | Both. INFORMATION_SCHEMA function: 6 months |
| Daily credits, including the cloud services 10% adjustment | **METERING_DAILY_HISTORY** | ACCOUNT_USAGE |
| Credits per service (warehouses, Snowpipe, clustering, …) per hour | **METERING_HISTORY** | ACCOUNT_USAGE |
| Account storage over time (tables, stages, Fail-safe) | **STORAGE_USAGE** | ACCOUNT_USAGE |
| Bytes per table: active, Time Travel, **Fail-safe** | **TABLE_STORAGE_METRICS** | Both. The Day 6 lab used it |
| Files loaded with COPY or Snowpipe, and their errors | **COPY_HISTORY** | ACCOUNT_USAGE 1 year. INFORMATION_SCHEMA function: 14 days |
| Files loaded with bulk COPY only (not Snowpipe) | **LOAD_HISTORY** | INFORMATION_SCHEMA view: 14 days. ACCOUNT_USAGE: 1 year |
| Snowpipe credits | **PIPE_USAGE_HISTORY** | |
| Task runs | **TASK_HISTORY** | INFORMATION_SCHEMA function: 7 days |
| Alert runs | **ALERT_HISTORY** | |
| Which objects carry which **tags** | **TAG_REFERENCES** | |
| Which **masking or row access policies** are attached where | **POLICY_REFERENCES** | |
| Users, roles, and who has which grants | **USERS**, **ROLES**, **GRANTS_TO_ROLES**, **GRANTS_TO_USERS** | ACCOUNT_USAGE includes dropped users and roles |
| Tables and columns that exist (or existed) | **TABLES**, **COLUMNS** | INFORMATION_SCHEMA: current only. ACCOUNT_USAGE: dropped too |

---

## 3. QUERY_HISTORY vs ACCESS_HISTORY: why `LIKE '%salary%'` isn't enough

Your idea was `SELECT … FROM QUERY_HISTORY WHERE query_text LIKE '%salary%'`. That's a fair first thought, but it misses most real reads:

| Query someone ran | Read salaries? | Does `LIKE '%salary%'` find it? |
|---|---|---|
| `SELECT name, salary FROM hr.employees` | Yes | ✅ Yes |
| `SELECT * FROM hr.employees` | Yes | ❌ No, the word never appears |
| `SELECT * FROM finance.payroll_v` (a view that selects salary) | Yes | ❌ No, only the view name appears |
| `SELECT name, pay FROM hr.employees_renamed_v` | Yes | ❌ No, the view renames the column |
| `SELECT 'my salary is private'` | No | ✅ Yes, a false match |

QUERY_HISTORY stores **the text people typed**. ACCESS_HISTORY stores **what Snowflake actually read**, resolved down to the real tables and columns, whatever the SQL looked like.

### What an ACCESS_HISTORY row looks like

One row per query. The interesting columns are JSON arrays (VARIANT):

| Column | Holds |
|---|---|
| `QUERY_ID`, `QUERY_START_TIME`, `USER_NAME` | Which query, when, who |
| `DIRECT_OBJECTS_ACCESSED` | What the SQL named directly, for example the **view** |
| `BASE_OBJECTS_ACCESSED` | The **real tables and columns** behind it, with views resolved |
| `OBJECTS_MODIFIED` | Tables and columns written by INSERT, UPDATE, MERGE, COPY, CTAS… (the source of column lineage) |
| `POLICIES_REFERENCED` | Masking and row access policies that were applied |

Example: Anna runs `SELECT * FROM finance.payroll_v`, a view over `hr.public.employees`.

```
USER_NAME:               ANNA
DIRECT_OBJECTS_ACCESSED: [ { "objectName": "FINANCE.PUBLIC.PAYROLL_V",
                             "objectDomain": "View",
                             "columns": [ {"columnName": "NAME"}, {"columnName": "SALARY"} ] } ]
BASE_OBJECTS_ACCESSED:   [ { "objectName": "HR.PUBLIC.EMPLOYEES",
                             "objectDomain": "Table",
                             "columns": [ {"columnName": "NAME"}, {"columnName": "SALARY"} ] } ]
```

The query text never says "employees" or "salary", but `BASE_OBJECTS_ACCESSED` shows Anna read `HR.PUBLIC.EMPLOYEES.SALARY`.

### The auditor's query: who read salary last month

It uses **FLATTEN** from Day 4 twice: once over the list of objects, then over each object's columns.

```sql
SELECT DISTINCT ah.user_name,
       ah.query_start_time,
       obj.value:"objectName"::STRING AS table_name,
       col.value:"columnName"::STRING AS column_name
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
     LATERAL FLATTEN(input => ah.base_objects_accessed) obj,
     LATERAL FLATTEN(input => obj.value:"columns") col
WHERE obj.value:"objectName"::STRING = 'HR.PUBLIC.EMPLOYEES'
  AND col.value:"columnName"::STRING = 'SALARY'
  AND ah.query_start_time >= DATEADD('month', -1, CURRENT_TIMESTAMP())
ORDER BY ah.query_start_time;
```

You can try a version of this on your trial (Enterprise). Run a few SELECTs on a table, wait about 3 hours (ACCESS_HISTORY's latency), then query it.

---

## 4. Retention and latency, the numbers to know

You don't need every view's number. These come up:

| Item | Number |
|---|---|
| ACCOUNT_USAGE retention | **1 year** |
| ACCOUNT_USAGE latency | **45 min to 3 h** (QUERY_HISTORY about 45 min, most others about 2 h) |
| INFORMATION_SCHEMA latency | **None** |
| INFORMATION_SCHEMA.QUERY_HISTORY(), LOGIN_HISTORY(), TASK_HISTORY() | **7 days** |
| INFORMATION_SCHEMA.COPY_HISTORY(), LOAD_HISTORY view | **14 days** |
| INFORMATION_SCHEMA.WAREHOUSE_METERING_HISTORY() | **6 months** |
| Snowsight Query History | **14 days** |
| COPY load metadata (not a view, but often confused with these) | **64 days** |
| Snowpipe load metadata | **14 days** |

---

## 5. The other SNOWFLAKE schemas (recognize the names)

| Schema | What it is |
|---|---|
| **ACCOUNT_USAGE** | This account's history, as above |
| **ORGANIZATION_USAGE** | The same kind of views across **all accounts in the organization** (ORGADMIN) |
| **READER_ACCOUNT_USAGE** | Usage of the **reader accounts** you created as a provider |
| **DATA_SHARING_USAGE** | Marketplace and listing usage for providers |
| **INFORMATION_SCHEMA** (in SNOWFLAKE) | The SNOWFLAKE database's own live metadata, like any database |
