# Day 6 · Automated Ingestion, Connectors, and Data Collaboration

**Covers:** objectives 3.2 and 3.3 (Domain 3, 18% of the exam) and 5.1 to 5.3 (Domain 5, 10% of the exam) · **Time:** about 3 hours

**Written from the Snowflake documentation on Nov 11, 2026,** as a story with worked scenarios, like the new Day 5. Each part ends with its sources. Where Snowflake changed something recently, the notes say so, because the exam can lag the docs.

This is the **last lesson with new material**. After it, every exam objective has been covered once.

## How to read this lesson

We stay with **Sevan Coffee**, the online coffee shop from Day 5. Last time you protected its data and loaded the nightly files by hand. Today the business wants three things: **data that arrives on its own**, **tools that connect to Snowflake**, and **sharing data safely with partners**.

Read each section as a story. Learn only the **"What to keep"** boxes. Take a break after each part.

- **Part 1:** Data that loads itself (3.2). About 60 minutes.
- **Part 2:** Plugging things in (3.3). About 20 minutes.
- **Part 3:** Protecting and sharing data (Domain 5). About 50 minutes.

## What this lesson covers

These are the official COF-C03 objective names.

- **3.2 Perform automated data ingestion:** Snowpipe, Snowpipe Streaming, streams, tasks, dynamic tables, Openflow.
- **3.3 Identify the different Snowflake connectors and integrations:** Snowflake drivers, Snowflake connectors, storage integration, API integration, Git integration.
- **5.1 Explain data collaboration and protection:** data replication and failover, Secure Data Sharing features, cloning, Time Travel, Fail-safe.
- **5.2 Explain Snowflake's data sharing capabilities:** accounts (provider, consumer, reader accounts), Secure Data Sharing, sharing and resharing, direct shares, data clean rooms.
- **5.3 Share data using the Snowflake Marketplace and listings:** Snowflake Marketplace, listings (private, public), Native Apps.

| Block | Time | What to do |
|---|---|---|
| Part 1 | 60 min | Read, then run lab sections 1 to 4 ([lab.sql](lab.sql)) |
| Break | 10 min | |
| Part 2 | 20 min | Read only (no lab: it needs a Git or cloud account) |
| Part 3 | 50 min | Read, then run lab sections 5 to 8 |
| Practice | 40 min | Answer [practice-questions.md](practice-questions.md), then log every miss |

---

# Part 1 · Data that loads itself (3.2)

## 1. "Stop running COPY by hand": Snowpipe

**The problem.** Since Day 5, someone at Sevan runs `COPY INTO orders` every morning. Now the website writes a small file to S3 **every few minutes**, and the business wants orders on the dashboard within minutes, not the next morning. Nobody wants to run COPY every five minutes.

**What Snowflake offers.** A **pipe** is an object that holds **one COPY statement** and runs it **by itself whenever a new file arrives**:

```sql
CREATE PIPE orders_pipe
  AUTO_INGEST = TRUE
AS
  COPY INTO orders FROM @orders_s3 FILE_FORMAT = (FORMAT_NAME = 'csv_orders');
```

How does Snowflake know a file arrived? With `AUTO_INGEST = TRUE`, you set up an **event notification** on the bucket (Amazon SQS/SNS/EventBridge, Azure Event Grid, Google Pub/Sub). The cloud tells Snowflake "new file", and the pipe loads it, **typically within a minute**. The other way to trigger a pipe is the **Snowpipe REST API**: your application calls the `insertFiles` endpoint with a list of file names.

**What's different from your morning COPY.**

- **No warehouse.** Snowpipe runs on **serverless** compute that Snowflake manages. You're billed **a fixed number of credits per GB loaded**, with no charge per file and no warehouse time.
- **Its memory is shorter.** Bulk COPY remembers loaded files for **64 days**. A pipe remembers them for **14 days**. It also matches files **by name**: if the web team overwrites `orders_001.csv` with new content, the pipe ignores it.
- **Errors.** One bad row doesn't stop the pipe. Its default is **`ON_ERROR = SKIP_FILE`**, and it doesn't even allow ABORT_STATEMENT.
- **No ordering guarantee.** Older files usually load first, but that's not promised.
- **Fewer options.** Pipes don't support `FILES`, `VALIDATION_MODE`, `FORCE` or `PURGE`. Only simple transformations are allowed (reorder, cast, drop columns), with no WHERE, JOIN or FLATTEN.
- **Can't edit a pipe.** To change the COPY, you recreate the pipe.

**One gotcha.** On the first day, files that were already in the bucket *before* you set up notifications don't load. Notifications only announce new files. `ALTER PIPE orders_pipe REFRESH` queues files staged in the **last 7 days**.

> **What to keep**
> - **Pipe = one COPY statement**, triggered by **cloud event notifications** (`AUTO_INGEST`) or the **REST API**.
> - **Serverless**, billed per GB. Load metadata **14 days** (COPY: 64). Default **ON_ERROR = SKIP_FILE**.
> - Files around 100–250 MB compressed, as with COPY. Snowpipe doesn't load from user or temporary stages.

## 2. "Within seconds, not a minute": Snowpipe Streaming

**The problem.** Sevan launches a mobile app. Each tap ("added to cart", "removed", "paid") is a tiny event. Writing every event to a file and waiting for Snowpipe is wasteful: millions of tiny files, and a minute of delay. Marketing wants live cart numbers.

**What Snowflake offers.** **Snowpipe Streaming** skips files entirely. The application sends **rows** straight into a table through the **Snowpipe Streaming SDK** (Java, Python or Node.js) or a REST API. Data is queryable in **as little as about 5 seconds**. Billing is per **uncompressed GB ingested**.

Rows travel through **channels**, like lanes on a road. A Kafka partition, for example, maps to one channel, and a channel can keep **exactly-once, ordered** delivery using **offset tokens** that record how far it has got.

**How to choose:**

| | Snowpipe | Snowpipe Streaming |
|---|---|---|
| Input | **Files** in a stage | **Rows** from an app, device or Kafka |
| Latency | About a minute | Seconds |
| Trigger | Event notification or REST API | The client SDK sends rows |

The **Kafka connector** (section 6) can use either one.

**Openflow** is the newest ingestion tool (a managed service, based on Apache NiFi, for pulling data from many sources). The tracker notes it isn't tested until it's generally available everywhere, so recognize the name and move on.

> **What to keep**
> - Snowpipe Streaming = **rows, not files**, through an **SDK** or Kafka. Lowest latency (seconds). Channels and offset tokens give exactly-once order.
> - Snowpipe = **files**, about a minute.

## 3. "Process only what's new": streams

**The problem.** Orders now land in `RAW_ORDERS` all day. Every hour, you need to move **only the new and changed orders** into a clean `ORDERS` table. Re-processing the whole table each hour would be slow and expensive. You need a bookmark: "where did I stop last time?"

**What Snowflake offers.** A **stream** on a table is exactly that bookmark. It stores **only an offset**, a point in the table's history, **not a copy of the data**. When you query it, Snowflake shows you every row that changed between the bookmark and now:

```sql
CREATE STREAM raw_orders_stream ON TABLE raw_orders;

-- Later, after 3 new orders arrived and 1 was updated:
SELECT * FROM raw_orders_stream;
```

You get 5 rows, each with three extra columns:
- The 3 new orders: `METADATA$ACTION = 'INSERT'`, `METADATA$ISUPDATE = FALSE`.
- The updated order appears **twice**: once as `DELETE` (the old version) and once as `INSERT` (the new one), both with `METADATA$ISUPDATE = TRUE`.
- `METADATA$ROW_ID` identifies each row across changes.

**When does the bookmark move?** You run that SELECT three times and keep seeing the same 5 rows. **Querying a stream doesn't move the offset.** It moves only when the stream is used in a **DML statement that commits**:

```sql
INSERT INTO orders SELECT order_id, amount, status FROM raw_orders_stream
WHERE METADATA$ACTION = 'INSERT';
-- Now the stream is empty until new changes arrive.
```

**Two teams, one table.** Finance also wants the changes. If finance uses *your* stream, whoever consumes first empties it for the other. Give each consumer **its own stream**. They're cheap: just an offset each.

**Types of stream:**
- **Standard:** inserts, updates and deletes. On tables, views, dynamic tables, directory tables.
- **Append-only:** inserts only. Cheaper for tables that only ever grow, like event logs.
- **Insert-only:** inserts only, for **external tables** and externally managed Iceberg tables.

**The vacation problem.** You go on holiday for three weeks and the hourly job is switched off. When you come back, the stream says it's **stale**. A stream can only read changes that still exist in **Time Travel** (section 8). If the table's retention is 1 day, Snowflake automatically stretches it for the stream, but only **up to 14 days by default** (`MAX_DATA_EXTENSION_TIME_IN_DAYS`). After that, the changes are gone and the stream must be recreated. **Consume your streams regularly.**

> **What to keep**
> - A stream stores **an offset only**. Columns: `METADATA$ACTION`, `METADATA$ISUPDATE`, `METADATA$ROW_ID`. An update = DELETE + INSERT pair.
> - The offset moves only when a **DML statement consuming the stream commits**. SELECT doesn't move it.
> - **Standard**, **append-only**, **insert-only** (external tables). One stream per consumer.
> - A stream goes **stale** if not consumed within the retention period (extended up to **14 days** by default).

## 4. "Run it every hour, by itself": tasks

**The problem.** The INSERT from section 3 has to run every hour, forever. You don't want to be the person who runs it.

**What Snowflake offers.** A **task** runs one SQL statement (or a stored procedure call) **on a schedule**:

```sql
CREATE TASK load_orders_task
  SCHEDULE = '60 MINUTE'
  WHEN SYSTEM$STREAM_HAS_DATA('raw_orders_stream')
AS
  INSERT INTO orders SELECT order_id, amount, status FROM raw_orders_stream
  WHERE METADATA$ACTION = 'INSERT';
```

The `WHEN` clause is a cheap check: if the stream is empty, the task **skips that run** and uses no compute. Instead of an interval you can use **CRON** (`SCHEDULE = 'USING CRON 0 6 * * * Europe/Berlin'`).

**Nothing happens.** Like an alert on Day 5, a **task is created suspended**. You run `ALTER TASK load_orders_task RESUME`. To test once, `EXECUTE TASK load_orders_task`.

**Which compute?** There's no WAREHOUSE in the example, so the task is **serverless**: Snowflake sizes the compute (up to the equivalent of XXLARGE). That needs the **EXECUTE MANAGED TASK** privilege. Or name a `WAREHOUSE`, and the usual warehouse billing applies (60-second minimum each resume). Running any task needs the account-level **EXECUTE TASK** privilege. Tasks run with the privileges of the **task owner's role**.

**From one task to a pipeline: task graphs.** Sevan's real pipeline has steps: load orders, then (in parallel) update the customer totals and the product totals, then send a "done" email. That's a **task graph** (a DAG):

- One **root task** has the schedule.
- Child tasks use `AFTER parent_task` instead of a schedule. A task with two parents waits for **both**.
- An optional **finalizer task** runs at the end, even if something failed (good for clean-up or the email).
- Limits: up to **1,000 tasks** per graph, and **100 parents and 100 children** per task. All tasks must have the **same owner** and live in the **same schema**.
- To change any task in the graph, **suspend the root task first**.

If a run is still going when the next one is due, the next one is **skipped**. Only one run of a graph happens at a time by default.

> **What to keep**
> - Task = **one SQL statement or procedure call** on a **schedule** (interval or CRON), optionally with `WHEN SYSTEM$STREAM_HAS_DATA`.
> - Created **suspended**: `ALTER TASK … RESUME`. **Serverless** (no warehouse) or a named warehouse.
> - **Task graph:** one **root** task with the schedule, children use **AFTER**, optional **finalizer**. Suspend the root to make changes.

## 5. "Just tell Snowflake what the result should be": dynamic tables

**The problem.** Your stream + task pipeline works, but it's a lot of moving parts: a stream, a task, an INSERT with the METADATA$ filters, and logic for updates and deletes. A new analyst asks: "Can't I just write the SELECT I want and have Snowflake keep it up to date?"

**What Snowflake offers.** A **dynamic table** is exactly that. You write the query and say how fresh the result must be:

```sql
CREATE DYNAMIC TABLE customer_totals
  TARGET_LAG = '10 minutes'
  WAREHOUSE = transform_wh
AS
  SELECT customer_id, COUNT(*) AS orders, SUM(amount) AS spent
  FROM orders GROUP BY customer_id;
```

Snowflake refreshes it so the data is **never more than about 10 minutes behind** `orders`. When it can, the refresh is **incremental** (only the changed rows are processed). Some queries can't be done incrementally, and then Snowflake does a **full** refresh. `REFRESH_MODE = AUTO` (the default) lets Snowflake choose. The refresh runs on the **warehouse you name**.

**Chains.** You add a second dynamic table, `vip_customers`, built on `customer_totals`. You set `customer_totals` to `TARGET_LAG = DOWNSTREAM`, meaning "refresh me only when something downstream needs me". Snowflake refreshes the chain in the right order.

**Things to know:**
- **Minimum target lag is 60 seconds.** For fresher data, use streams and tasks or Snowpipe Streaming.
- You **can't INSERT, UPDATE or DELETE** into a dynamic table. Its content is always the query's result.
- Target lag is a target, not a guarantee.

**Which tool when?** (This is a favourite exam question.)

| You need | Use |
|---|---|
| A SQL pipeline with joins and aggregations, declared as a SELECT | **Dynamic table** |
| Procedural logic (IF/ELSE, loops, procedures), MERGE, exact scheduling (CRON) | **Streams + tasks** |
| Faster repeated queries on **one** table, rewritten automatically by the optimizer | **Materialized view** |

> **What to keep**
> - Dynamic table = **a SELECT + TARGET_LAG**. Snowflake refreshes it (incremental or full) on **your warehouse**.
> - `TARGET_LAG = DOWNSTREAM` for intermediate tables. Minimum lag **60 seconds**. **No DML** on it.
> - Declarative SQL → dynamic tables. Procedural or CRON → streams and tasks.

Sources for Part 1: [Snowpipe](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-intro) · [Automate Snowpipe with cloud event notifications](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto) · [Snowpipe REST API](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-rest-overview) · [Snowpipe Streaming](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/data-load-snowpipe-streaming-overview) · [Introduction to streams](https://docs.snowflake.com/en/user-guide/streams-intro) · [Introduction to tasks](https://docs.snowflake.com/en/user-guide/tasks-intro) · [Task graphs](https://docs.snowflake.com/en/user-guide/tasks-graphs) · [Dynamic tables](https://docs.snowflake.com/en/user-guide/dynamic-tables/overview) · [Decision guide for dynamic tables](https://docs.snowflake.com/en/user-guide/dynamic-tables/decision-guide)

**Break time.** Run lab sections 1 to 4, then take 10 minutes away from the screen.

---

# Part 2 · Plugging things in (3.3)

## 6. "Our tools need to talk to Snowflake": drivers and connectors

**The situation.** Three teams want to connect:
- The **backend developers** write Python and Node.js services that place orders.
- **Finance** uses a BI tool that speaks **ODBC** or **JDBC**.
- The **data platform team** already runs **Apache Kafka** and **Apache Spark**.

**Drivers** let your own code or a tool run SQL against Snowflake. Snowflake provides drivers for **JDBC, ODBC, Python, Go, Node.js, .NET and PHP**. The backend team uses the **Python connector** (`snowflake-connector-python`). Finance's BI tool uses the **ODBC or JDBC** driver. There is also the **SQL API**, a REST endpoint for running SQL without a driver.

**Connectors** move data between Snowflake and another system:
- The **Snowflake Connector for Kafka** runs inside a **Kafka Connect** cluster. It reads **topics** and writes each topic to a table, by default with two VARIANT columns: **RECORD_CONTENT** (the message) and **RECORD_METADATA** (topic, partition, offset, …). It loads through **Snowpipe** or **Snowpipe Streaming**. It's one-way: Kafka into Snowflake only.
- The **Snowflake Connector for Spark** lets Spark read from and write to Snowflake as a data source, pushing work down to Snowflake where it can.

> **What to keep**
> - **Drivers:** JDBC, ODBC, Python, Go, Node.js, .NET, PHP (plus the SQL API).
> - **Kafka connector:** topics → tables, RECORD_CONTENT + RECORD_METADATA, via Snowpipe or Snowpipe Streaming.
> - **Spark connector:** Spark reads and writes Snowflake.

## 7. "No passwords in SQL": integrations

All three integrations below are **account-level objects** that hold the connection details in one place, so no keys appear in SQL. Creating one needs **CREATE INTEGRATION**, which only ACCOUNTADMIN has by default.

**Storage integration (Day 5 recap).** Sevan's external stage reads S3. The storage integration holds an **AWS IAM role** that Snowflake assumes (or an Azure service principal, or a GCP service account). Stages say `STORAGE_INTEGRATION = s3_int`, and nobody ever sees an access key.

**API integration.** Sevan wants a SQL function that calls an exchange-rate service running behind **Amazon API Gateway**. That's an **external function**, and it goes through an **API integration**, which records the provider (`API_PROVIDER = aws_api_gateway`, `azure_api_management`, `google_api_gateway`, …) and which URLs are allowed (`API_ALLOWED_PREFIXES`). The same object type also connects Snowflake to **Git** (`API_PROVIDER = git_https_api`).

**Git integration.** The SQL for Sevan's tasks and procedures lives in a GitHub repository. Instead of copy-pasting it, you connect the repository:

```sql
CREATE API INTEGRATION github_int
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sevan-coffee')
  ALLOWED_AUTHENTICATION_SECRETS = (github_token)
  ENABLED = TRUE;

CREATE GIT REPOSITORY sevan_repo
  ORIGIN = 'https://github.com/sevan-coffee/pipelines.git'
  API_INTEGRATION = github_int
  GIT_CREDENTIALS = github_token;      -- a SECRET holding a personal access token

ALTER GIT REPOSITORY sevan_repo FETCH;  -- pull the latest commits
LIST @sevan_repo/branches/main/;
EXECUTE IMMEDIATE FROM @sevan_repo/branches/main/setup/create_tasks.sql;
```

Snowflake keeps a **read-only clone** of the repository, which you browse like a **stage** (by branch, tag or commit). You **fetch** to update it. For a private repository, credentials live in a **secret**, or you use OAuth.

> **What to keep**
> - **Storage integration:** external stage access through an IAM role, no keys.
> - **API integration:** for **external functions** (API Gateway, Azure API Management, Google API Gateway) and for **Git**.
> - **Git repository:** `CREATE GIT REPOSITORY` with an API integration (`git_https_api`), credentials in a **secret**. A read-only, stage-like clone. `FETCH` to update.

Sources for Part 2: [Using Snowflake with Kafka and Spark](https://docs.snowflake.com/en/user-guide/connectors) · [Overview of the Kafka connector](https://docs.snowflake.com/en/user-guide/kafka-connector-overview) · [Overview of the Spark connector](https://docs.snowflake.com/en/user-guide/spark-connector-overview) · [CREATE API INTEGRATION](https://docs.snowflake.com/en/sql-reference/sql/create-api-integration) · [Setting up Snowflake to use Git](https://docs.snowflake.com/en/developer-guide/git/git-setting-up) · [CREATE GIT REPOSITORY](https://docs.snowflake.com/en/sql-reference/sql/create-git-repository)

---

# Part 3 · Protecting and sharing data (Domain 5)

## 8. "I deleted the wrong rows": Time Travel

**The story.** Friday, 16:05. A colleague runs `DELETE FROM orders WHERE status = 'paid'`. They meant `'pending'`. 40,000 paid orders are gone. Everyone looks at you.

**What Snowflake offers.** Snowflake keeps the **old versions** of changed or deleted data for a while. That's **Time Travel**. You can query the table **as it was**:

```sql
-- As it was 10 minutes ago (OFFSET is in seconds)
SELECT COUNT(*) FROM orders AT(OFFSET => -60*10);

-- As it was at a moment in time
SELECT COUNT(*) FROM orders AT(TIMESTAMP => '2026-11-13 16:00:00'::TIMESTAMP_LTZ);

-- As it was just BEFORE the bad statement ran (using its query ID)
SELECT COUNT(*) FROM orders BEFORE(STATEMENT => '01b2c3d4-...');
```

The last one is the most precise. You restore the rows:

```sql
INSERT INTO orders
SELECT * FROM orders BEFORE(STATEMENT => '01b2c3d4-...') WHERE status = 'paid';
```

**Monday.** Someone drops the whole `promotions` table. `UNDROP TABLE promotions` brings it back. UNDROP also works for **schemas** and **databases**. If a new table with the same name already exists, UNDROP fails: rename the new one first.

**How long?** The **retention period** (`DATA_RETENTION_TIME_IN_DAYS`):
- **Default 1 day** on every edition.
- **Standard edition:** 0 or 1 day.
- **Enterprise and higher:** **up to 90 days** for permanent tables, schemas and databases.
- **Transient and temporary tables:** 0 or 1 day, on any edition.
- **0 turns Time Travel off** for that object. After the period ends, you can no longer query, clone or UNDROP that data.

Time Travel isn't free: older versions are stored, and storage costs money. Long retention on a table that changes all day can cost a lot.

> **What to keep**
> - Query the past with **AT** or **BEFORE** + **TIMESTAMP**, **OFFSET** (seconds) or **STATEMENT** (query ID).
> - **UNDROP** tables, schemas and databases (fails if the name is taken).
> - Default **1 day**. **Enterprise: up to 90 days** for permanent objects. Transient and temporary: 0 or 1.

## 9. "It's been two weeks": Fail-safe

**The story.** Someone notices that a table with a 1-day retention was dropped **12 days** ago. Time Travel has ended, so UNDROP fails.

**What's left.** After Time Travel ends, data from **permanent** tables goes into **Fail-safe** for **7 more days**. But Fail-safe is **not for you**: you can't query it or UNDROP from it. Only **Snowflake Support** can recover data from it, on a **best-effort** basis, and it can take hours or days. It's meant for disasters, not mistakes.

So here, day 1 was Time Travel, days 2 to 8 were Fail-safe, and on day 12 the data is gone for good.

| Table type | Time Travel | Fail-safe |
|---|---|---|
| **Permanent** | 1 day by default (up to 90 on Enterprise) | **7 days** |
| **Transient** | 0 or 1 day | **None** |
| **Temporary** | 0 or 1 day (and gone at the end of the session) | **None** |

The Fail-safe period **can't be changed**. That's why staging tables that you can always reload are often made **transient**: no Fail-safe storage to pay for.

> **What to keep**
> - Fail-safe = **7 days** after Time Travel, **permanent tables only**, **not configurable**, recovery **only by Snowflake Support**.
> - Total protection for a permanent table with default settings: 1 + 7 = 8 days.

## 10. "Give me a full copy to test on, right now": cloning

**The story.** A developer wants to test a risky change on a copy of the 2 TB `SALES` database. Copying 2 TB would take hours and double the storage bill.

**What Snowflake offers.** **Zero-copy cloning**:

```sql
CREATE DATABASE sales_dev CLONE sales;
```

It finishes in seconds and uses **no extra storage at first**, because the clone **points to the same micro-partitions** as the original. Only when someone changes data in either copy are new micro-partitions written, and only those cost extra. The two copies are fully independent: a change in one never shows in the other.

You can clone **databases, schemas and tables** (and also streams, tasks, stages, file formats, sequences and more). Combine it with Time Travel: `CREATE TABLE orders_friday CLONE orders AT(TIMESTAMP => '2026-11-13 16:00:00'::TIMESTAMP_LTZ)` makes a copy of the table as it was before the bad DELETE.

**What surprises people after cloning a database:**
- **Tasks** in the clone are **suspended**. You don't want the test copy running production jobs.
- **Streams** in the clone start with their **unconsumed changes inaccessible**, effectively empty.
- **Pipes** that load from an **internal** stage aren't cloned. Pipes on **external** stages are.
- **Internal named stages** aren't cloned unless you add `INCLUDE INTERNAL STAGES`. External stages are cloned. Files in table stages aren't copied.
- **Privileges:** objects *inside* the cloned database keep their grants, but the **cloned database itself doesn't** get the source database's grants.
- You **can't clone a shared database** you received (section 12).

> **What to keep**
> - Clone = **metadata only** until data changes. Instant, no extra storage at first. Works with **AT/BEFORE**.
> - In a cloned database: **tasks suspended**, **streams' unconsumed changes gone**, internal-stage pipes not cloned.

## 11. Replication recap (5.1.1)

Day 5 section 8 covered replication and failover in detail. In one line: **replication groups** copy databases (any edition) to read-only secondaries in another region or cloud in the **same organization**, and **failover groups** (Business Critical) let a secondary become the primary. For sharing, replication matters for one reason: **a direct share only works inside one region** (section 12), so reaching other regions means replicating the data or using a listing with auto-fulfillment (section 14).

## 12. "Our roaster wants our sales numbers": Secure Data Sharing

**The story.** Sevan's coffee supplier, **Ararat Roasters**, also uses Snowflake. They want daily sales per coffee bean so they can plan production. The old way: export a CSV every night and email it. The file is out of date as soon as it's sent, and nobody knows who forwarded it where.

**What Snowflake offers.** **Secure Data Sharing.** Sevan (the **provider**) creates a **share**, adds objects to it, and names the **consumer** account:

```sql
CREATE SHARE bean_sales_share;
GRANT USAGE ON DATABASE sales TO SHARE bean_sales_share;
GRANT USAGE ON SCHEMA sales.public TO SHARE bean_sales_share;
GRANT SELECT ON VIEW sales.public.bean_sales_v TO SHARE bean_sales_share;  -- a SECURE view
ALTER SHARE bean_sales_share ADD ACCOUNTS = ararat_org.ararat_account;
```

Ararat creates a database from the share and queries it:

```sql
CREATE DATABASE sevan_sales FROM SHARE sevan_org.sevan_account.bean_sales_share;
```

**What's going on underneath.** **No data is copied.** Ararat's queries read Sevan's micro-partitions directly, through Snowflake's metadata. So:
- Ararat always sees **live data**: when Sevan loads today's sales, Ararat sees them immediately.
- **Sevan pays for storage** (it's Sevan's data). **Ararat pays for compute** (its own warehouse runs the queries).
- The shared database is **read-only** for Ararat. It can't insert, update, clone it or use Time Travel on it.
- Sevan can **revoke** access at any moment.

Sevan shares a **secure view** rather than the raw table, so Ararat sees only bean-level totals, and can't see the view's definition. Tables, dynamic tables, external and Iceberg tables, secure views, secure materialized views and secure UDFs can all be shared. A **database role** can be granted to a share to control which objects inside it the consumer gets.

**The small café without Snowflake.** A café in Gyumri also wants a slice of the data, but it has no Snowflake account. Sevan creates a **reader account** for it: a small Snowflake account **owned and paid for by the provider (Sevan)**, including its **compute**. The café can only query what Sevan shares with it, and can't load its own data.

**Can Ararat pass the data on?** The classic rule, and probably what the exam expects: **a consumer can't reshare shared data.** The 2026 docs add a newer option: if the provider allows resharing, the consumer can reshare **within its own organization**, by creating a secure view over the imported data and sharing that view. Never to a third company.

**Distance.** Ararat's account is in the same cloud region as Sevan's, so a **direct share** works. A partner in **another region** can't use a direct share. Sevan would need to **replicate** the data to that region first, or publish a **listing with Cross-Cloud Auto-Fulfillment** (section 14).

> **What to keep**
> - **Provider** creates a **share**. **Consumer** creates a read-only database from it. **No data copied**, always live.
> - **Provider pays storage, consumer pays compute.** Reader accounts: **provider pays everything**.
> - Consumers can't modify, **clone** or Time Travel shared data, and (classic rule) can't **reshare** it.
> - **Direct shares work in the same region only.** Other regions: replication or a listing with auto-fulfillment.

## 13. "Analyse together without showing each other the data": data clean rooms

**The story.** Sevan and a German bank want to know how many of Sevan's customers also hold the bank's credit card, to plan a joint promotion. Neither is allowed to give the other its customer list.

**What Snowflake offers.** A **Snowflake Data Clean Room**. Both parties put their data into a shared, controlled environment. **Nobody can query the other's raw rows.** They can only run **approved analysis templates**, such as "count of overlapping customers by city", that return **aggregated results**. The **data provider decides which analyses are allowed** on its data. A plain share is different: there, the consumer can query the shared data freely.

> **What to keep**
> - Clean room = joint analysis through **approved templates**, **aggregated results only**, **no access to raw rows**. The data provider controls what runs.

## 14. "Let the world find our data": listings and the Marketplace

**The story.** Sevan's anonymized "coffee consumption by region" dataset turns out to be interesting to other companies. Sevan wants to offer it widely, maybe charge for it, and reach accounts in other regions, none of which a direct share can do.

**What Snowflake offers.** A **listing** wraps a **share** (or a **Native App**) with a title, description, sample queries and terms. It's "an enhanced method of Secure Data Sharing". Two kinds:

- **Private listing:** offered only to **specific accounts** you name. Sevan uses one for its five biggest wholesale partners.
- **Public listing:** published on the **Snowflake Marketplace**, where any Snowflake customer can find it. This needs a **provider profile**.

Listings can be **free**, a **limited trial** (1 to 90 days), or **paid** (in supported regions). Consumers click **Get**, and a database appears in their account, just like a share. To create listings, you need ACCOUNTADMIN or a role with the provider privileges.

**Other regions.** A buyer in AWS Sydney gets the listing. Sevan doesn't replicate anything by hand. **Cross-Cloud Auto-Fulfillment** copies the data product to that region automatically and keeps it refreshed on a schedule (from 1 minute to 8 days). This adds cost to the provider. It isn't available on trial accounts.

| | Direct share | Listing |
|---|---|---|
| Who | Named accounts | Named accounts (private) or anyone (Marketplace) |
| Regions | Same region only | Any region, via auto-fulfillment |
| Charge money | No | Yes (paid listings) |
| Description, usage metrics | No | Yes |

> **What to keep**
> - **Listing** = share or Native App + metadata. **Private** = named accounts. **Public** = **Marketplace**.
> - Free, limited trial, or paid. **Cross-Cloud Auto-Fulfillment** delivers to other regions.

## 15. "Sell the software, not just the data": Native Apps

**The story.** Sevan builds a "demand forecast" tool: tables plus Python code plus a Streamlit dashboard. Café chains want to run it **on their own sales data**, but would never send that data to Sevan.

**What Snowflake offers.** The **Snowflake Native App Framework**. Sevan (the provider) builds an **application package**, which contains:
- A **manifest file** (`manifest.yml`) describing the app: its setup script, version, and what privileges it needs.
- A **setup script** (SQL) that runs when a consumer **installs** or **upgrades** the app and creates its objects.
- The code, data and Streamlit UI.

Sevan publishes it through a **listing** (private or on the Marketplace, free or paid). A café chain installs it, and **the app runs inside the consumer's account**, on the consumer's data. Sevan ships updates as **versions and patches**.

> **What to keep**
> - **Application package** = **manifest** + **setup script** + code and data. Shared through a **listing**. Installed and run **in the consumer's account**.

Sources for Part 3: [Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel) · [Fail-safe](https://docs.snowflake.com/en/user-guide/data-failsafe) · [Temporary and transient tables](https://docs.snowflake.com/en/user-guide/tables-temp-transient) · [Cloning considerations](https://docs.snowflake.com/en/user-guide/object-clone) · [About Secure Data Sharing](https://docs.snowflake.com/en/user-guide/data-sharing-intro) · [Consume imported data](https://docs.snowflake.com/en/user-guide/data-share-consumers) · [Manage reader accounts](https://docs.snowflake.com/en/user-guide/data-sharing-reader-create) · [Share data across regions and clouds](https://docs.snowflake.com/en/user-guide/secure-data-sharing-across-regions-platforms) · [About Snowflake Data Clean Rooms](https://docs.snowflake.com/en/user-guide/cleanrooms/about) · [About listings](https://docs.snowflake.com/en/collaboration/collaboration-listings-about) · [Auto-fulfillment for listings](https://docs.snowflake.com/en/collaboration/provider-listings-auto-fulfillment) · [About the Native App Framework](https://docs.snowflake.com/en/developer-guide/native-apps/native-apps-about)

Run lab sections 5 to 8 now.

---

## The whole day in one picture

| Sevan's problem | Snowflake feature |
|---|---|
| Load each new file as it lands | **Snowpipe** (serverless, files, about a minute) |
| Live events from the app in seconds | **Snowpipe Streaming** (rows, SDK or Kafka) |
| Process only what changed | **Stream** (an offset) |
| Run SQL every hour | **Task** (created suspended) and **task graphs** |
| "Keep this SELECT up to date" | **Dynamic table** (TARGET_LAG) |
| Python, BI tools, Kafka, Spark | **Drivers** and **connectors** |
| No keys in SQL | **Storage**, **API** and **Git** integrations |
| Undo a bad DELETE | **Time Travel** (AT / BEFORE, UNDROP) |
| Recover after Time Travel ended | **Fail-safe** (7 days, Snowflake Support only) |
| A test copy in seconds | **Zero-copy clone** |
| Live data for a partner | **Secure Data Sharing** (provider storage, consumer compute) |
| A partner without Snowflake | **Reader account** (provider pays all) |
| Analyse together without revealing rows | **Data clean room** |
| Offer data widely or for money | **Listing** (private or Marketplace) |
| Ship an app that runs on the customer's data | **Native App** |

## After this lesson

Every objective has now been covered. The plan's next step is **Mock 1**: 100 questions in 115 minutes, timed. Do it whenever you have a quiet two hours, not straight after this lesson. Then send me your score per domain, and we'll spend the remaining time on your weakest areas.
