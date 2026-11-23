# Mock 1 follow-ups · Your questions, answered with examples

Answers to the questions you asked after reviewing Mock 1, in the order you asked them. Each section ends with a short "What to keep" box. Facts come from the Day 1–6 notes, which were written from docs.snowflake.com.

**Contents**
1. [Stages, from zero](#1-stages-from-zero-q53) (Q53)
2. [COPY options: how to remember them](#2-copy-options-how-to-remember-them-q54-q59) (Q54, Q59)
3. [Snowpipe, step by step](#3-snowpipe-step-by-step-q61) (Q61)
4. [What runs serverless, and privilege patterns](#4-what-runs-serverless-and-privilege-patterns-q64) (Q64)
5. [Snowsight](#5-snowsight)
6. [Stream staleness, with examples](#6-stream-staleness-with-examples-q63) (Q63)
7. [UNDROP and Time Travel](#7-undrop-and-time-travel-q92) (Q92)
8. [SnowSQL vs Snowflake CLI, and how PUT works](#8-snowsql-vs-snowflake-cli-and-how-put-works-q15) (Q15)
9. [Who does what: the system roles](#9-who-does-what-the-system-roles-q32) (Q32)
10. [All the numbers (days, hours, sizes) to remember](#10-all-the-numbers-to-remember-q63)
11. [The four performance services, side by side](#11-the-four-performance-services-side-by-side-q74) (Q74)
12. [The three caches, as a story](#12-the-three-caches-as-a-story-q80) (Q80)

---

## 1. Stages, from zero (Q53)

**What a stage is.** COPY INTO can't read a file from your laptop or from a random website. It reads only from a **stage**: a named location that Snowflake knows how to reach. Every load is **files → stage → COPY INTO table**, and every unload is the reverse.

There are two families, depending on **whose storage holds the files**.

### Internal stages: storage inside Snowflake

Snowflake stores the files for you. You upload with **PUT** (from a client on your computer, see section 8) and download with **GET**. There are three kinds, and the difference is **who it belongs to**.

**1. User stage, `@~`: your personal folder.** This is the one you've used. Every user gets one automatically, nobody else can use it, and you can't create, drop or share it.

```sql
PUT file:///home/ashot/test.csv @~;              -- upload to your own stage
LIST @~;
COPY INTO my_table FROM @~/test.csv.gz;
```
Use it for one-off experiments. Your colleague can't load from it, so it's useless for a team pipeline.

**2. Table stage, `@%orders`: a folder attached to one table.** Every table gets one automatically, with the table's name after `%`.

```sql
PUT file:///home/ashot/orders.csv @%orders;
COPY INTO orders FROM @%orders;                  -- FROM can even be left out here
```
Limits that the exam tests (Q53):
- It belongs to **one table** and is only for loading into that table. Tables don't share one.
- You **can't drop or alter it**, and you **can't grant** access to it. Whoever owns the table uses it.
- **No transformations** in COPY: `COPY INTO orders FROM (SELECT $1, $3 FROM @%orders)` fails.

**3. Named internal stage, `@orders_stage`: a shared folder you create.** It's a real schema-level object:

```sql
CREATE STAGE orders_stage FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1);
GRANT READ, WRITE ON STAGE orders_stage TO ROLE loader;
PUT file:///home/ashot/orders.csv @orders_stage/2026/11/;
COPY INTO orders FROM @orders_stage/2026/11/;
```
You can grant it to any role, give it a default file format, use transformations, and load several tables from it. **This is the recommended choice for regular pipelines.**

| | `@~` user | `@%orders` table | `@orders_stage` named |
|---|---|---|---|
| Created by | Automatic, per user | Automatic, per table | You, with CREATE STAGE |
| Who can use it | Only that user | The table's owner | Anyone you grant it to |
| Drop or alter | No | No | Yes |
| COPY transformations | Yes | **No** | Yes |
| Typical use | Quick tests | Loading one table, simply | Team pipelines (recommended) |

### External stages: storage in your own cloud account

This is the one you knew: the files sit in **your** S3 bucket, Azure container or Google Cloud Storage bucket, and the stage is just a **pointer** to it.

```sql
CREATE STAGE orders_s3
  URL = 's3://sevan-exports/orders/'
  STORAGE_INTEGRATION = s3_int;      -- an IAM role, no keys in SQL
```
- You **can't PUT** to it. Files are written with the cloud's own tools (the AWS CLI, an app, Azure Data Factory…).
- Dropping the stage deletes **only the pointer**, never the files.
- Access goes through a **storage integration** (recommended) rather than keys in `CREDENTIALS`.

### Two extra stage features

- **Encryption (internal stages):** the default is `SNOWFLAKE_FULL`. `SNOWFLAKE_SSE` (server-side only) is needed for scoped, file and pre-signed **URLs**, and it can only be chosen **when the stage is created**.
- **Directory table:** `DIRECTORY = (ENABLE = TRUE)` adds a queryable list of the stage's files (`SELECT * FROM DIRECTORY(@orders_stage)`). It's off by default.

> **What to keep**
> - Internal: `@~` user (personal), `@%table` table (one table, no transformations, no grants), `@name` named (grantable, recommended). PUT and GET work only on internal stages.
> - External: a pointer to your S3, Azure or GCS storage, accessed through a storage integration. No PUT.

---

## 2. COPY options: how to remember them (Q54, Q59)

Yes, **PURGE** and **FORCE** are both real COPY options, and so is **LOAD_UNCERTAIN_FILES**. There are many options, but the exam only uses about ten. Don't memorize them as a list. Each one answers one of five questions you'd ask about a load:

| Question you're asking | Option | What it does |
|---|---|---|
| **1. Which files?** | `FILES = ('a.csv', 'b.csv')` | Only these named files |
| | `PATTERN = '.*2026-11.*'` | Files matching a regex |
| **2. What if a row is bad?** | `ON_ERROR` | ABORT_STATEMENT (default for COPY), CONTINUE (skip bad rows), SKIP_FILE (skip bad files; default for Snowpipe) |
| | `VALIDATION_MODE` | Just check, load nothing |
| **3. What about files loaded before?** | *(default)* | Skip them: load metadata remembers loaded files for 64 days |
| | `FORCE = TRUE` | Load **everything again**, even files known to be loaded. Can create duplicates |
| | `LOAD_UNCERTAIN_FILES = TRUE` | Load files whose status is **unknown** (metadata expired after 64 days), but still skip known ones |
| **4. What happens to the files afterwards?** | `PURGE = TRUE` | **Delete the files from the stage** after they load successfully |
| **5. How do columns line up?** | `MATCH_BY_COLUMN_NAME` | Match file fields to columns by name (Parquet, JSON, CSV with headers) |
| | `(SELECT $1, $3 FROM @stage)` | A transformation: pick and reorder columns by position |

Read the questions in order: **Which files → Bad rows → Loaded before → Afterwards → Columns.** When an exam question mentions one of these situations, go to that row.

**The two pairs you mixed up:**
- **FORCE vs LOAD_UNCERTAIN_FILES** (both in question 3). FORCE says "I don't care what you remember, load it all", which **duplicates** anything already loaded. LOAD_UNCERTAIN_FILES says "load the files you're **not sure** about", which only affects old files with expired metadata.
- **PURGE vs TRUNCATE** (Q59). PURGE is a COPY option that cleans the **stage** (deletes files). TRUNCATE TABLE is a separate command that cleans the **table** and, as a side effect, its **load metadata**, so the same files can be loaded again.

A story to tie them together: the nightly load runs with `PURGE = TRUE`, so each file disappears from the stage once loaded. One day you need to reload last month's files, which are still in a backup folder. You `TRUNCATE` the table, which also clears the load metadata, copy the files back to the stage, and run COPY. Without TRUNCATE you'd need `FORCE`, and that's only safe because the table is empty.

> **What to keep**
> - Five questions: which files (FILES, PATTERN), bad rows (ON_ERROR, VALIDATION_MODE), loaded before (FORCE, LOAD_UNCERTAIN_FILES), afterwards (PURGE), columns (MATCH_BY_COLUMN_NAME).
> - **PURGE = stage. TRUNCATE = table and load metadata.**

---

## 3. Snowpipe, step by step (Q61)

You've only ever run COPY yourself. Snowpipe is **COPY that runs itself whenever a file arrives**. Here's what happens, step by step, when Sevan's website drops a file into S3:

```
1. 10:02:15  The website writes orders_1002.csv to s3://sevan-exports/orders/
2. 10:02:16  S3 sends an event notification: "new object orders_1002.csv"
             (through SQS / SNS / EventBridge; on Azure: Event Grid; on GCP: Pub/Sub)
3. 10:02:16  Snowflake receives it and puts the file in the pipe's queue
4. 10:02:40  Snowflake's serverless compute runs the pipe's COPY on that one file
5. 10:02:55  The rows are in the ORDERS table. No warehouse was started.
```

The setup is two pieces:

```sql
-- 1. The pipe: a name wrapped around ONE COPY statement
CREATE PIPE orders_pipe
  AUTO_INGEST = TRUE
AS
  COPY INTO orders FROM @orders_s3 FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1);

-- 2. Tell S3 where to send notifications: SHOW PIPES gives the
--    notification_channel (an SQS queue ARN) to paste into the bucket's settings
SHOW PIPES;
```

**There are exactly two ways to trigger a pipe** (Q61):
1. **Auto-ingest:** the cloud's **event notification**, as above. The most common way.
2. **The Snowpipe REST API:** your own program calls the `insertFiles` endpoint and says "load these files". It's used when you can't set up notifications, or want to control the timing.

What does **not** exist: a schedule or CRON on a pipe (that's a **task**), and an `EXECUTE PIPE` command (there's EXECUTE TASK and EXECUTE ALERT, but no EXECUTE PIPE). To catch up on files staged before notifications were set up, there's `ALTER PIPE … REFRESH` (last 7 days).

**Snowpipe vs your manual COPY:**

| | Bulk COPY (you run it) | Snowpipe |
|---|---|---|
| Who runs it | You, or a task | Snowflake, when a file arrives |
| Compute | Your warehouse | **Serverless**, billed per GB loaded |
| Load metadata | 64 days | **14 days** |
| Default ON_ERROR | ABORT_STATEMENT | **SKIP_FILE** |
| Latency | Whenever you run it | About a minute after the file lands |

And **Snowpipe Streaming** is different again: no files at all, rows sent by an SDK or Kafka, queryable within seconds.

> **What to keep**
> - Pipe = one COPY statement that runs on its own. Triggered **only** by **event notifications (auto-ingest)** or the **REST API**.
> - Serverless, 14-day metadata, SKIP_FILE default. No schedule, no EXECUTE PIPE.

---

## 4. What runs serverless, and privilege patterns (Q64)

### Serverless features

"Serverless" means Snowflake supplies and sizes the compute, and you pay per use instead of running a warehouse. The list worth knowing:

| Feature | What the serverless compute does |
|---|---|
| **Snowpipe** | Loads files as they arrive |
| **Snowpipe Streaming** | Ingests rows |
| **Serverless tasks** | Tasks created **without** a WAREHOUSE |
| **Serverless alerts** | Alerts created without a WAREHOUSE |
| **Automatic Clustering** | Re-clusters tables that have a clustering key |
| **Materialized view maintenance** | Keeps MVs up to date |
| **Search Optimization Service** | Builds and maintains the search access paths |
| **Query Acceleration Service** | Offloads parts of large scans from a warehouse |
| **Replication** | Copies data for replication and failover groups |
| **Trust Center scanners** | The opt-in scanner packages (CIS, Threat Intelligence) |

Not serverless: **dynamic tables** refresh on the warehouse you name. Cortex AI functions are billed per token, but the query that calls them still runs on a warehouse.

Two exam links: **resource monitors can't control any of these** (they only watch warehouses), so use a **budget**. And creating serverless tasks or alerts needs an "EXECUTE **MANAGED** …" privilege.

### Privileges: learn the patterns, not the list

You don't need every privilege. About six patterns cover almost every exam question:

**Pattern 1: To use anything, you need USAGE on its containers.** Reading a table needs SELECT on the table, **plus USAGE on its database and its schema**. Running a query also needs USAGE on a warehouse. This explains many "why can't the user see the table?" questions.

```sql
GRANT USAGE ON DATABASE sales TO ROLE analyst;
GRANT USAGE ON SCHEMA sales.public TO ROLE analyst;
GRANT SELECT ON TABLE sales.public.orders TO ROLE analyst;
GRANT USAGE ON WAREHOUSE analyst_wh TO ROLE analyst;
```

**Pattern 2: CREATE `<thing>` is granted on the container that will hold it.**
- Account level: CREATE DATABASE, CREATE WAREHOUSE, CREATE ROLE, CREATE USER, CREATE INTEGRATION, CREATE SHARE.
- Database level: CREATE SCHEMA.
- Schema level: CREATE TABLE, CREATE VIEW, CREATE STAGE, CREATE PIPE, CREATE TASK…

**Pattern 3: Running things on a schedule takes EXECUTE …, and serverless adds MANAGED.**
- **EXECUTE TASK**, **EXECUTE ALERT**: run tasks or alerts at all (account level, granted by ACCOUNTADMIN).
- **EXECUTE MANAGED TASK**, **EXECUTE MANAGED ALERT**: run them on serverless compute.

**Pattern 4: Governance takes APPLY ….**
- **APPLY MASKING POLICY**, **APPLY ROW ACCESS POLICY**, **APPLY TAG** (and APPLY AGGREGATION POLICY, …). This lets a security team attach policies to tables it doesn't own.

**Pattern 5: Warehouses have their own four.** USAGE (run queries), OPERATE (start, stop, suspend), MODIFY (resize, change settings), MONITOR (see queries and usage). Plus OWNERSHIP.

**Pattern 6: Stages split by family.** Internal stages: **READ** (GET, COPY from) and **WRITE** (PUT, REMOVE). External stages: **USAGE**.

**The specials** (one each, learn by name):

| Privilege | Who has it | What it allows |
|---|---|---|
| **MANAGE GRANTS** | SECURITYADMIN | Grant and revoke any privilege on any object |
| **OWNERSHIP** | One role per object | Full control, including granting and dropping |
| **IMPORTED PRIVILEGES** | Granted on a shared database (or SNOWFLAKE) | Read everything in that imported database |
| **IMPORT SHARE** | ACCOUNTADMIN | Create a database from a share |
| **CREATE INTEGRATION** | ACCOUNTADMIN | Storage, API, notification and security integrations |
| Resource monitors | ACCOUNTADMIN only | Create them. It can grant MONITOR or MODIFY on one |

> **What to keep**
> - Serverless: Snowpipe, serverless tasks and alerts, Automatic Clustering, MV maintenance, Search Optimization, QAS, replication. Not controlled by resource monitors.
> - Patterns: USAGE on the containers, CREATE on the container, EXECUTE (MANAGED) for schedules, APPLY for governance, warehouse USAGE/OPERATE/MODIFY/MONITOR, stage READ/WRITE.

---

## 5. Snowsight

Yes, **Snowsight is Snowflake's web UI**, the website you log in to. Worksheets, Query History and Query Profile, dashboards, Notebooks, Streamlit apps, the Marketplace, the Trust Center, cost management and the lineage graph all live there. (The old UI, the "Classic Console", is retired.)

---

## 6. Stream staleness, with examples (Q63)

**Why streams go stale at all.** A stream stores only a bookmark. The changes it shows are read from the table's **Time Travel** history. If that history is gone, the stream can't show what happened, so it's **stale** and must be recreated.

To stop that happening, Snowflake **stretches the table's Time Travel just for the stream**, up to `MAX_DATA_EXTENSION_TIME_IN_DAYS`, which defaults to **14 days**. The rule is:

> **A stream goes stale after the larger of** the table's retention period **and** MAX_DATA_EXTENSION_TIME_IN_DAYS, **counted from the last time it was consumed.**

**Example 1: the common case.** `RAW_ORDERS` has the default 1-day retention. The stream was last consumed on **Nov 1**.
- Retention is 1 day, but Snowflake extends it for the stream up to 14 days. The larger of 1 and 14 is **14**.
- The stream is fine until about **Nov 15**. If the hourly task resumes on Nov 10, nothing is lost.
- If nobody consumes it until **Nov 20**, it's stale. The changes between Nov 1 and Nov 6 are gone.

**Example 2: long retention.** `ORDERS` has a 30-day retention (Enterprise). Stream last consumed Nov 1.
- The larger of 30 and 14 is **30**, so no extension is needed, and the stream is good until about **Dec 1**.

**Example 3: a longer extension.** An admin sets `MAX_DATA_EXTENSION_TIME_IN_DAYS = 30` on a table with 1-day retention.
- The larger of 1 and 30 is **30**. The stream survives a month without being consumed. (The price is that the table keeps up to 30 days of history, which costs storage.)

**Example 4: the trap.** Someone runs `CREATE OR REPLACE TABLE raw_orders …`. Every stream on it goes stale immediately, because the old table they pointed to is gone. Renaming the table doesn't do this.

You can see it with `SHOW STREAMS`: the `stale` column (TRUE/FALSE) and `stale_after` (the date it will go stale).

> **What to keep**
> - Stale after **max(retention, MAX_DATA_EXTENSION_TIME_IN_DAYS)** since the last consumption. The default extension is **14 days**.
> - CREATE OR REPLACE on the source table makes its streams stale.

---

## 7. UNDROP and Time Travel (Q92)

**Yes, exactly: UNDROP works only during Time Travel.** A dropped table sits in Time Travel for its retention period, and UNDROP pulls it back. After that, it moves into **Fail-safe** for 7 days (permanent tables only), where **only Snowflake Support** can recover it.

```
Permanent table, retention 1 day, dropped Monday 10:00

Mon 10:00 ─────── Tue 10:00 ─────────────────────────── Tue + 7 days
|  Time Travel     |  Fail-safe                           |  gone
|  UNDROP works,   |  UNDROP fails, AT/BEFORE fail,       |
|  AT/BEFORE work  |  only Snowflake Support can recover  |
```

With **retention = 0** (Q92) the first box has zero length: the table goes **straight into Fail-safe**, so UNDROP fails immediately, and only Support can help. A **transient** table with retention 0 has neither box, so it's gone for good.

---

## 8. SnowSQL vs Snowflake CLI, and how PUT works (Q15)

They are **two different programs** that you install on your computer. Both connect to Snowflake from a terminal.

| | **SnowSQL** | **Snowflake CLI** |
|---|---|---|
| Command you type | `snowsql` | `snow` |
| Status | **Legacy**. Still works and is still supported, but gets no new features | **The current tool**. Snowflake adds new features here |
| Main use | Running SQL interactively | Running SQL **and** developer work: deploying Streamlit apps, Native Apps, Snowpark code, managing stages and Git |

Running the same PUT in each:

```bash
# SnowSQL: open an interactive session, then type SQL
snowsql -a myorg-myaccount -u ashot
> PUT file:///home/ashot/orders.csv @orders_stage;

# Snowflake CLI: run one SQL statement from the terminal
snow sql -q "PUT file:///home/ashot/orders.csv @orders_stage"

# Snowflake CLI also has its own stage command
snow stage copy /home/ashot/orders.csv @orders_stage
```

**Why PUT needs a client, and why Snowsight can't run it.** PUT is a SQL command, but it has to **read a file from your computer's disk** (`file:///home/ashot/…`). Only a program running **on your computer** can do that: SnowSQL, Snowflake CLI, or a driver such as the Python connector or JDBC. A Snowsight worksheet runs in your browser and sends SQL to Snowflake's servers, which can't see your disk, so PUT isn't supported there. Snowsight has an **upload button** in its UI for files instead. GET is the same in reverse: it writes a file to your disk.

> **What to keep**
> - **SnowSQL** (`snowsql`) = legacy. **Snowflake CLI** (`snow`) = current, and it also deploys Streamlit, Native Apps and Snowpark.
> - PUT and GET run from a **client on your machine** (CLI, SnowSQL, drivers), not from a Snowsight worksheet.

---

## 9. Who does what: the system roles (Q32)

```
              ACCOUNTADMIN
              /          \
      SECURITYADMIN     SYSADMIN
            |              |
        USERADMIN     (your custom roles go here)
              \          /
                 PUBLIC
```

Arrows point down to the roles each one **inherits**. ACCOUNTADMIN gets everything below it.

| Role | Think of it as | What it does by default | Typical exam answer for… |
|---|---|---|---|
| **ORGADMIN** | The organization manager | Manages the **organization**: creates accounts, views usage across all accounts (ORGANIZATION_USAGE), enables replication between accounts | "Create a new account", "see usage across all accounts" |
| **ACCOUNTADMIN** | The account owner | Everything in the account. Plus things **only it** can do: create resource monitors, see billing, manage account parameters, create integrations, grant EXECUTE TASK | "Create a resource monitor", "view billing", "top-level role" |
| **SECURITYADMIN** | The permissions manager | Has **MANAGE GRANTS**: can grant and revoke any privilege on anything. Inherits USERADMIN | "Grant privileges on any object", "manage grants centrally" |
| **USERADMIN** | The HR desk | Has **CREATE USER** and **CREATE ROLE** | "Create users and roles" |
| **SYSADMIN** | The builder | Has **CREATE WAREHOUSE** and **CREATE DATABASE**. Owns the data objects. Custom roles should be granted to it | "Create warehouses and databases", "where should custom roles roll up?" |
| **PUBLIC** | Everyone | Granted to every user and role automatically | "A privilege everyone should have" |

Best practices that show up as questions:
- **Don't use ACCOUNTADMIN for daily work.** Give it to a few people, with MFA.
- **Grant custom roles to SYSADMIN**, so admins can manage the objects they own.
- **Objects are owned by roles, not users.** Every object has exactly one owner role.

> **What to keep**
> - **USERADMIN** creates users and roles. **SECURITYADMIN** manages all grants. **SYSADMIN** creates warehouses and databases. **ACCOUNTADMIN** is on top (resource monitors, billing). **ORGADMIN** manages accounts in the organization. **PUBLIC** is everyone.

---

## 10. All the numbers to remember (Q63)

Grouped by topic. The **bold** ones are the most tested.

**Data protection**

| Item | Number |
|---|---|
| Time Travel default | **1 day** |
| Time Travel maximum, permanent objects, Enterprise and above | **90 days** |
| Time Travel, Standard edition | 0 or 1 day |
| Time Travel, transient and temporary tables | 0 or 1 day |
| Fail-safe, permanent tables | **7 days** (transient and temporary: none) |
| Stream staleness extension (MAX_DATA_EXTENSION_TIME_IN_DAYS) | **14 days** by default |

**Loading**

| Item | Number |
|---|---|
| COPY load metadata | **64 days** |
| Snowpipe load metadata | **14 days** |
| ALTER PIPE … REFRESH looks back | 7 days |
| Recommended file size to load | **100–250 MB compressed** |
| Unload file size (MAX_FILE_SIZE default) | **16 MB** (max 5 GB) |
| COPY_HISTORY / LOAD_HISTORY in INFORMATION_SCHEMA | 14 days |

**Storage and caching**

| Item | Number |
|---|---|
| Micro-partition size | **50–500 MB uncompressed** |
| Result cache | **24 hours**, reset on each reuse, **31 days** maximum |
| Scoped URL expiry | **24 hours** |
| VARIANT maximum size | 128 MB |

**Compute and cost**

| Item | Number |
|---|---|
| Billing minimum on each warehouse start or resume | **60 seconds**, then per second |
| CREATE WAREHOUSE default AUTO_SUSPEND | 600 seconds (10 minutes) |
| Credits per hour | XS 1, S 2, M 4, L 8, XL 16 (each size doubles) |
| Economy scaling policy | Starts a cluster only if it would be busy for **6 minutes** |
| Cloud services free allowance | **10%** of daily warehouse credits |
| Resource monitor reset | 12:00 AM **UTC** |
| Dynamic table minimum target lag | 60 seconds |
| MAX_CONCURRENCY_LEVEL default | 8 |
| STATEMENT_TIMEOUT_IN_SECONDS default | 2 days |

**Monitoring history**

| Item | Number |
|---|---|
| ACCOUNT_USAGE retention | **1 year** |
| ACCOUNT_USAGE latency | **45 minutes to 3 hours** |
| INFORMATION_SCHEMA QUERY_HISTORY / LOGIN_HISTORY functions | **7 days** |
| Snowsight Query History | 14 days |

**Security**

| Item | Number |
|---|---|
| Automatic key rotation | **30 days** |
| Periodic rekeying (Enterprise) | Keys retired more than **1 year** ago |
| Key-pair authentication | 2048-bit RSA, up to two keys for rotation |
| Tags per object | 50 |

**Sharing**

| Item | Number |
|---|---|
| Limited trial listing | 1–90 days |

---

## 11. The four performance services, side by side (Q74)

All four make queries faster. QAS, Search Optimization and materialized views need **Enterprise**. Clustering keys work on every edition. The trick is matching each one to the **shape of the slow query**.

| Service | The slow query looks like… | What it does | Story |
|---|---|---|---|
| **Query Acceleration Service (QAS)** | **Occasional, unpredictable** queries that **scan a huge amount of data** and hog the warehouse | Lends extra **serverless** compute to the big scan parts of those queries | An analyst's quarterly ad-hoc query over 5 years of data no longer slows down everyone else |
| **Search Optimization Service** | **Point lookups**: `WHERE email = '…'` or `WHERE order_id = 123` on a huge table, returning a few rows | Builds a search access path, like an index, so Snowflake jumps to the right micro-partitions | Support looks up one customer in 5 TB in a second instead of a minute |
| **Clustering key** (Automatic Clustering) | **Range filters** on the same column, again and again: `WHERE event_date BETWEEN …`, but data arrives in no useful order | Re-sorts the table's micro-partitions by the key, so pruning works | Daily dashboards filter by date on a multi-TB table |
| **Materialized view** | The **same expensive aggregation** on **one** table, run over and over | Pre-computes and stores the result. Maintenance is serverless | Every dashboard computes revenue per day from 2 billion rows |

How to pick from the question:
- "**outlier**", "**ad-hoc**", "**large scans**", "**unpredictable**" → **QAS**
- "**point lookup**", "**equality**", "**few rows**", "**substring**", "**VARIANT field**" → **Search Optimization**
- "**range filter on the same column**", "**poor pruning**", "**multi-TB**" → **Clustering key**
- "**same query repeatedly**", "**aggregation on one table**" → **Materialized view**

---

## 12. The three caches, as a story (Q80)

Snowflake has three places where it can avoid redoing work. Follow Ashot's morning:

**08:55. The warehouse is suspended.** Ashot runs:
```sql
SELECT COUNT(*) FROM orders;
```
It answers instantly **without starting the warehouse**. Snowflake keeps the row count of every micro-partition in its **metadata** (in cloud services), so it just adds them up. COUNT, MIN and MAX on a column can work this way. → **Metadata cache.**

**09:00. The warehouse starts.** He runs:
```sql
SELECT region, SUM(amount) FROM orders WHERE order_date >= '2026-11-01' GROUP BY region;
```
It takes 40 seconds. The warehouse reads micro-partitions from remote storage, and **keeps a copy of them on its local SSD**.

**09:05.** He runs the **exact same query** again. It returns in **under a second**, and the warehouse does no work. Cloud services kept the **result** and checked that the data hadn't changed. → **Result cache.** It lasts 24 hours (reset on each reuse, up to 31 days), the user must have privileges on every table in the query, and it doesn't need a running warehouse.

**09:10.** He changes the query slightly: `SUM(amount)` becomes `AVG(amount)`. It's a different query, so the result cache can't help. But it takes **8 seconds instead of 40**: the micro-partitions it needs are already on the warehouse's SSD from 09:00. → **Warehouse (local disk) cache.**

**09:11.** The warehouse auto-suspends after 60 seconds idle.

**09:30.** He runs the AVG query again. The result cache still answers instantly, since it's the exact same text and the data is unchanged. But a *new* variation (`MAX(amount)`) takes the full 40 seconds again, because **suspending wiped the SSD cache**. That's Q80: **the warehouse cache is dropped on suspend.**

**10:00.** Someone inserts new orders. Now even the exact same query can't use the result cache, because **the data changed**. The same is true for queries with CURRENT_TIMESTAMP() and similar functions.

| Cache | Lives in | Holds | Lost when | Needs a warehouse? |
|---|---|---|---|---|
| **Metadata** | Cloud services | Row counts, min and max per micro-partition | Never (always current) | No |
| **Result** | Cloud services | Full results of past queries | 24 h without reuse (31 days max), or the data changes | **No** |
| **Warehouse (local disk)** | The warehouse's SSD | Raw micro-partition data it read | **The warehouse suspends** | Yes |

That's also why BI warehouses get a **longer auto-suspend**: it keeps the SSD cache warm for dashboard queries.

> **What to keep**
> - **Metadata**: COUNT, MIN, MAX without a warehouse. **Result**: the exact same query, unchanged data, 24 h, no warehouse. **Warehouse**: an SSD copy of the data, lost on suspend.
