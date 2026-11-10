# Day 5 · Governance, Cost Monitoring, and Data Loading

**Covers:** objectives 2.2 and 2.3 (Domain 2, 20% of the exam) and 3.1 (Domain 3, 18% of the exam) · **Time:** about 3 hours

**Written from the Snowflake documentation on Nov 10, 2026.** Each section ends with its sources. Where Snowflake changed something recently, the notes say so, because the exam can lag the docs.

## What this lesson covered

These are the official COF-C03 domain and objective names, so you can look each one up in the [Snowflake documentation](https://docs.snowflake.com) for a second round.

**Domain 2.0: Account Management and Data Governance**
- 2.2 Define data governance features and how they are used
  - Data masking: row-level security, column-level security
  - Object tagging · Privacy policies · Trust Center · Encryption key management
  - Alerts · Notifications · Data replication and failover · Data lineage
- 2.3 Explain monitoring and cost management
  - Resource monitors: cost and warehouse monitoring
  - Calculating virtual warehouse credit usage
  - ACCOUNT_USAGE schema

**Domain 3.0: Data Loading, Unloading, and Connectivity**
- 3.1 Perform data loading and unloading
  - File formats
  - Create and use stages: internal, external, server-side encryption, directory tables
  - COPY INTO command
  - Error handling options

---

| Block | Time | What to do |
|---|---|---|
| Notes, part 1 | 35 min | Read 2.2 and 2.3 |
| Lab, part 1 | 25 min | Run sections 1 to 6 of [lab.sql](lab.sql) (masking, row access, aggregation policy, tags, alert, resource monitor) |
| Notes, part 2 | 30 min | Read 3.1 |
| Lab, part 2 | 30 min | Run sections 7 to 10 of the lab (file formats, stages, COPY with errors, unloading, cleanup) |
| Practice | 40 min | Answer [practice-questions.md](practice-questions.md), then log every miss |

---

## 2.2 Data governance

Almost everything in this section needs **Enterprise edition or higher**: masking policies, row access policies, aggregation and projection policies, tag-based masking and propagation, ACCESS_HISTORY and lineage. (Creating and setting plain tags works on every edition.)

### Masking policies: column-level security (2.2.1.2)

- A **masking policy** is a **schema-level object** that decides, **at query time**, what a user sees in a column: the real value, a partly masked value, or a fully masked one. **The stored data never changes.**
- It works on **tables and views**, and applies **everywhere the column appears** in a query.
- A column can have **only one** masking policy.
- Typical body:

```sql
CREATE MASKING POLICY email_mask AS (val STRING) RETURNS STRING ->
  CASE WHEN IS_ROLE_IN_SESSION('PII_READER') THEN val
       ELSE '***MASKED***' END;
ALTER TABLE customers MODIFY COLUMN email SET MASKING POLICY email_mask;
```

- **CURRENT_ROLE()** checks only the active primary role. **IS_ROLE_IN_SESSION()** also counts roles inherited through the hierarchy and secondary roles, so it's usually the better choice.
- Setting or unsetting a policy needs the **APPLY** privilege on it (or the account-level APPLY MASKING POLICY). This allows **centralized** governance: a security team, not the table owner, decides what's masked.
- **Tag-based masking:** attach a masking policy to a **tag**, and every column with that tag (and a matching data type) is masked automatically.
- **External Tokenization** is a related feature: data is tokenized before it's loaded, and a policy calls an external function to detokenize it for allowed roles.

### Row access policies: row-level security (2.2.1.1)

- A **row access policy** is a schema-level object whose body returns **BOOLEAN**. Each row where it's TRUE is visible; the rest are filtered out at query time.
- It filters what SELECT returns and which rows UPDATE, DELETE and MERGE can touch. It doesn't stop INSERTs.
- Often uses a **mapping table** (for example, role → allowed region). Keep it in the same database as the protected table.
- **Order:** if a table has both, **the row access policy is evaluated first, then masking.**
- The body runs with the **policy owner's** privileges, not the querying user's.
- In a **share**, CURRENT_ROLE() and CURRENT_USER() return NULL for the consumer, so policies on shared data use **CURRENT_ACCOUNT()** or database roles instead.

### Object tagging (2.2.2)

- A **tag** is a **schema-level object**; each assignment pairs it with a **string value** (for example `cost_center = 'finance'`).
- Up to **50 tags per object**.
- **Inheritance:** a tag on a table applies to all its columns; a tag on the account applies to its warehouses, and so on down the hierarchy.
- **Propagation** (Enterprise): tags can flow automatically to dependent objects (such as a view on a tagged table) or copies (CTAS).
- **Automatic classification** can find sensitive columns (emails, names, …) and tag them for you.
- Uses: **finding sensitive data** (then protect it with tag-based masking) and **cost attribution** (tag warehouses by team or project).
- Setting a tag needs the **APPLY TAG** privilege. See all tag assignments in **ACCOUNT_USAGE.TAG_REFERENCES**.

### Privacy policies (2.2.3)

These protect individuals in data that analysts can still use for statistics:

| Policy | Effect |
|---|---|
| **Aggregation policy** | Queries **must aggregate**; every group must have at least `MIN_GROUP_SIZE` rows (or entities). Smaller groups are merged into a **remainder group** with a NULL key |
| **Projection policy** | A column **can't appear in query output**, but can still be used in WHERE or JOIN (for example, match on email without seeing it) |
| **Privacy policy** (differential privacy) | Adds statistical **noise** to results and tracks a **privacy budget** per analyst, so no one can work out facts about a single person from repeated queries |
| Join policy | Queries must join the table to another before returning results |

A table can have only one aggregation policy. All of these are Enterprise features.

### Trust Center (2.2.4)

- Evaluates your account against security recommendations using **scanners**, grouped into **scanner packages**, and reports **findings**.
- **Violations** persist while a setting is wrong (severity low, medium, high, critical). **Detections** are one-off events such as an unusual login.
- Packages:
  - **Security Essentials:** on by default, can't be turned off, **no cost** (checks MFA, account network policy, event table).
  - **CIS Benchmarks:** checks against the **CIS Snowflake Benchmark**; off by default, runs daily once enabled.
  - **Threat Intelligence:** risky users and logins (password-only users, failed logins, dormant users); off by default.
  - Newer: AI Security, Data Security.
- Scanners other than Security Essentials run on **serverless compute that costs credits**.
- Access: ACCOUNTADMIN grants the **TRUST_CENTER_ADMIN** or **TRUST_CENTER_VIEWER** application roles. Findings are also in ACCOUNT_USAGE.TRUST_CENTER_FINDINGS, and can be sent by email or a notification integration.

### Encryption key management (2.2.5)

- **All data is encrypted by default**, at rest (AES) and in transit (TLS). No setup needed.
- **Hierarchical key model**, four levels: **root key → account master keys → table master keys → file keys.** Each level encrypts the one below. The root key lives in a hardware security module (HSM).
- **Automatic key rotation:** keys older than **30 days** are retired. A retired key only decrypts existing data; a destroyed key is used for nothing.
- **Periodic rekeying** (**Enterprise**): data whose retired key is **over a year old** is re-encrypted with a new key. Enable with `ALTER ACCOUNT SET PERIODIC_DATA_REKEYING = TRUE` (ACCOUNTADMIN). Rekeyed files add 7 days of Fail-safe storage.
- **Tri-Secret Secure** (**Business Critical**): a **customer-managed key** in your cloud KMS (AWS KMS, Azure Key Vault, Google Cloud KMS) is combined with a Snowflake key into a **composite master key**. If you revoke your key, Snowflake can't decrypt your data.

### Alerts (2.2.6) and notifications (2.2.7)

- An **alert** is a schema-level object with a **condition** (a SQL query), an **action** (SQL to run if the query returns rows), and a **schedule** (interval or CRON).
  - Runs on **serverless compute** or a warehouse you choose.
  - Created **suspended**: run `ALTER ALERT … RESUME`.
  - Needs the account-level **EXECUTE ALERT** privilege (granted by ACCOUNTADMIN).
  - **Alerts on new data** check only newly inserted rows of one table.
  - History in ALERT_HISTORY.
- **Notifications** go out through a **notification integration**:
  - **Email** (to verified addresses), **queue** (Amazon SNS, Azure Event Grid, Google Pub/Sub) or **webhook** (Slack, Teams, PagerDuty).
  - Send from SQL with `SYSTEM$SEND_EMAIL` or `SYSTEM$SEND_SNOWFLAKE_NOTIFICATION`, typically in an alert's action, a task, or a budget.

### Replication and failover (2.2.8)

| | |
|---|---|
| **Replication group** | A set of objects copied together from a **primary** account to one or more **secondary** accounts **in the same organization**, across regions and clouds. Secondaries are **read-only** |
| **Failover group** | A replication group whose secondary can be **promoted** to primary (read-write) if the primary's region fails |
| **Editions** | **Database and share replication: every edition.** Replicating **account objects** (users, roles, warehouses, resource monitors, integrations, network policies, …) and **failover**: **Business Critical** |
| **Not replicated** | Temporary tables, external tables, hybrid tables, event tables, databases created from shares (inbound shares) |
| **Refresh** | Scheduled with `REPLICATION_SCHEDULE` (recommended). Users and roles in a secondary are read-only: change them in the primary |
| **Client Redirect** | A **connection** object that lets clients follow a failover to the new primary without changing their URL (Business Critical) |

Cost: data transfer between regions plus compute for the refresh.

### Data lineage (2.2.9)

- **Snowsight lineage graph** (Enterprise): for a table or view, shows **upstream** sources and **downstream** targets, one step at a time, and **column-level lineage**.
- Built from operations such as **CTAS, INSERT … SELECT, MERGE, CREATE VIEW, CREATE MATERIALIZED VIEW, CLONE and COPY INTO**. Kept for **one year**.
- Needs the **VIEW LINEAGE** privilege (granted to PUBLIC by default) plus privileges on the objects.
- Use it to find columns missing a tag compared with their upstream source, and to see which columns have masking policies.
- **ACCESS_HISTORY** (ACCOUNT_USAGE, Enterprise): one row per query, showing **who read or wrote which tables and columns**: `direct_objects_accessed`, `base_objects_accessed` (the tables behind a view), `objects_modified`, `policies_referenced`. The basis for audits and column lineage.

Sources: [Dynamic Data Masking](https://docs.snowflake.com/en/user-guide/security-column-ddm-intro) · [Column-level security](https://docs.snowflake.com/en/user-guide/security-column-intro) · [Tag-based masking](https://docs.snowflake.com/en/user-guide/tag-based-masking-policies) · [Row access policies](https://docs.snowflake.com/en/user-guide/security-row-intro) · [Object tagging](https://docs.snowflake.com/en/user-guide/object-tagging/introduction) · [Privacy in Snowflake](https://docs.snowflake.com/en/guides-overview-privacy) · [Aggregation policies](https://docs.snowflake.com/en/user-guide/aggregation-policies) · [Projection policies](https://docs.snowflake.com/en/user-guide/projection-policies) · [Trust Center](https://docs.snowflake.com/en/user-guide/trust-center/overview) · [Encryption key management](https://docs.snowflake.com/en/user-guide/security-encryption-manage) · [Tri-Secret Secure](https://docs.snowflake.com/en/user-guide/security-encryption-tss) · [Alerts](https://docs.snowflake.com/en/user-guide/alerts) · [Snowflake notifications](https://docs.snowflake.com/en/user-guide/notifications/snowflake-notifications) · [Replication and failover](https://docs.snowflake.com/en/user-guide/account-replication-intro) · [Data lineage](https://docs.snowflake.com/en/user-guide/ui-snowsight-lineage) · [Access History](https://docs.snowflake.com/en/user-guide/access-history)

---

## 2.3 Monitoring and cost management

### Resource monitors (2.3.1)

- **Only ACCOUNTADMIN can create them.** It can grant MONITOR or MODIFY on a monitor to other roles.
- They track **credits used by warehouses** (warehouse compute plus the cloud services those warehouses use). They **can't control serverless features** (Snowpipe, Automatic Clustering, materialized views, search optimization, serverless tasks) or AI services: use a **budget** for those.
- **Credit quota** per interval: **daily, weekly, monthly (default, resets on the 1st), yearly, or never**. Resets happen at **12:00 AM UTC**.
- **Levels:**
  - **One account-level monitor** per account.
  - Any number of **warehouse-level** monitors. **A warehouse can belong to only one** warehouse monitor; a monitor can cover up to 500 warehouses.
- **Actions** at a percentage of the quota (thresholds can be **over 100%**):
  - **Notify:** just sends a notification (up to five Notify actions).
  - **Notify & Suspend:** suspends the warehouses **after running queries finish** (so usage can go a little over).
  - **Notify & Suspend Immediately:** suspends and **cancels running queries**.
- Suspended warehouses stay suspended until the next interval, the quota is raised, or the warehouse is removed from the monitor.
- **Notifications are off by default**: users must enable them and verify their email. Non-admins can get alerts for warehouse monitors only.

**Budgets** (the newer tool, for exam context): monthly **spending limit** for the account or for a custom group of objects, including **serverless** features. They **only notify** (email, queue, webhook); they don't suspend anything unless you attach your own stored procedure.

### Calculating virtual warehouse credit usage (2.3.2)

(The full table is in Day 2.)
- Credits per hour by size (Gen 1): **XS 1, S 2, M 4, L 8, XL 16, 2XL 32, 3XL 64, 4XL 128, 5XL 256, 6XL 512.**
- Billed **per second**, with a **60-second minimum** each time the warehouse **starts or resumes**.
- **Multi-cluster:** each running cluster bills separately.
- **Cloud services** is billed only for the part of **daily** cloud services usage above **10%** of that day's warehouse credits.

Worked examples:
- A **Large** warehouse runs for **15 minutes**: 8 × 0.25 = **2 credits**.
- An **X-Small** runs a 20-second query, then suspends: billed **60 seconds** = 1/60 of 1 credit ≈ **0.017 credits**.
- A **Medium** multi-cluster warehouse runs **3 clusters for 2 hours**: 4 × 3 × 2 = **24 credits**.
- A day with **100** warehouse credits and **12** cloud services credits: 10 are free, so **2** cloud services credits are billed.

### The ACCOUNT_USAGE schema (2.3.3)

- Lives in the shared **SNOWFLAKE** database. Compared with each database's **INFORMATION_SCHEMA**:

| | ACCOUNT_USAGE | INFORMATION_SCHEMA |
|---|---|---|
| Scope | The whole account | One database |
| Dropped objects | **Included** | Not included |
| Latency | **About 45 minutes to 3 hours** | None (real time) |
| History kept | **1 year** | 7 days to 6 months, depending on the view |

- Access: ACCOUNTADMIN by default. Others need **IMPORTED PRIVILEGES** on SNOWFLAKE, or (recommended) one of the SNOWFLAKE **database roles**: **OBJECT_VIEWER**, **USAGE_VIEWER**, **GOVERNANCE_VIEWER**, **SECURITY_VIEWER**.
- Views to know: **WAREHOUSE_METERING_HISTORY** (credits per warehouse per hour), **METERING_DAILY_HISTORY** (daily credits, including the cloud services adjustment), **STORAGE_USAGE**, **QUERY_HISTORY**, **LOGIN_HISTORY**, **COPY_HISTORY** and **LOAD_HISTORY**, **ACCESS_HISTORY**, **TAG_REFERENCES**, **POLICY_REFERENCES**.

Sources: [Resource monitors](https://docs.snowflake.com/en/user-guide/resource-monitors) · [Budgets](https://docs.snowflake.com/en/user-guide/budgets) · [Overview of warehouses](https://docs.snowflake.com/en/user-guide/warehouses-overview) · [Understanding compute cost](https://docs.snowflake.com/en/user-guide/cost-understanding-compute) · [Account Usage](https://docs.snowflake.com/en/sql-reference/account-usage)

---

## 3.1 Loading and unloading data

The flow: **files → stage → `COPY INTO <table>`**. Unloading is the reverse: **`COPY INTO <stage>` → files → GET** (or your cloud tools).

### File formats (3.1.1)

- **Load:** CSV (any single-byte delimiter, so TSV and pipe-delimited too), **JSON, Avro, ORC, Parquet, XML**.
- **Unload:** **CSV, JSON and Parquet only.**
- A **named file format** (`CREATE FILE FORMAT`) is a reusable **schema-level** object. You can set a format on a table, a stage, or the COPY command; COPY's setting wins.
- Useful options: `SKIP_HEADER`, `FIELD_DELIMITER`, `FIELD_OPTIONALLY_ENCLOSED_BY`, `NULL_IF`, `EMPTY_FIELD_AS_NULL`, `DATE_FORMAT`; for JSON, **`STRIP_OUTER_ARRAY = TRUE`** (a file holding one big `[ … ]` array loads as one row per element instead of one huge row).
- **Size your files** at roughly **100–250 MB compressed**. The number of files that load in parallel can't exceed the number of files, so one 50 GB file loads slowly and millions of tiny files waste per-file overhead.

### Stages (3.1.2)

A **stage** is a location for data files.

**Internal stages** (Snowflake-managed storage):

| Stage | Reference | Notes |
|---|---|---|
| **User stage** | `@~` | One per user, **only that user** can use it. Can't be altered or dropped. No file format options on the stage itself |
| **Table stage** | `@%orders` | One per table, for loading **into that table**. Can't be altered or dropped. **No transformations** during COPY. Using its files needs ownership of the table |
| **Named internal stage** | `@my_stage` | A **schema-level object** you create. Privileges can be granted to any role. The most flexible: **recommended for regular loads** |

- Upload with **PUT** (from a client such as Snowflake CLI, SnowSQL or a driver; it compresses files with gzip by default), download with **GET**, list with **LIST**, delete with **REMOVE**.

**External stages** (your S3, Azure Blob/ADLS or Google Cloud Storage):
- `CREATE STAGE … URL = 's3://bucket/path/'` plus access through a **storage integration** (`STORAGE_INTEGRATION = …`), which the docs **highly recommend** over putting keys in `CREDENTIALS`.
- A **storage integration** is an account-level object holding an IAM role or service principal, so no secrets appear in SQL.
- You can't PUT to an external stage: write files with your cloud tools.

**Server-side encryption on stages (3.1.2.3):**
- Internal stages: `ENCRYPTION = (TYPE = 'SNOWFLAKE_FULL')` is the **default** (client-side encryption on PUT plus server-side AES-256). `TYPE = 'SNOWFLAKE_SSE'` is **server-side only**, and is **needed for file, scoped and pre-signed URLs** (Day 4). It **can't be changed** after creation. Tri-Secret Secure needs SNOWFLAKE_FULL.
- External stages: the cloud's own encryption, for example `AWS_SSE_S3`, `AWS_SSE_KMS`, `GCS_SSE_KMS`, or client-side `AWS_CSE` / `AZURE_CSE` with a master key.

**Directory tables (3.1.2.4):** (Day 4) a catalogue of a stage's files, turned on with `DIRECTORY = (ENABLE = TRUE)` (off by default), refreshed manually with `ALTER STAGE … REFRESH` or automatically with event notifications.

**Temporary stages** are dropped at the end of the session, and dropping a temporary internal stage **deletes its files**.

### COPY INTO <table> (3.1.3)

```sql
COPY INTO orders
FROM @my_stage/2026/11/
FILE_FORMAT = (FORMAT_NAME = 'csv_fmt')
PATTERN = '.*orders_.*[.]csv[.]gz'
ON_ERROR = 'SKIP_FILE';
```

- **Which files:** everything in the path, or `FILES = ('a.csv', 'b.csv')` (up to 1,000 names), or `PATTERN = '<regex>'`.
- **Transformations during load** (`COPY INTO t (c1, c2) FROM (SELECT $1, TO_DATE($3) FROM @stage)`): reorder, omit, cast, and pick JSON paths (`$1:customer.name`). They work from **user and named stages**, not table stages. Not every function is allowed.
- **MATCH_BY_COLUMN_NAME** = CASE_SENSITIVE or CASE_INSENSITIVE loads semi-structured or Parquet files (and CSV with headers) into columns with the same names. Can't be combined with a transformation.
- **Load metadata:** for each table, Snowflake remembers which files it loaded, by name and checksum, for **64 days**. COPY **skips files already loaded**, so re-running a COPY doesn't duplicate data.
  - **`FORCE = TRUE`** reloads every file anyway, **which can duplicate data**.
  - **`LOAD_UNCERTAIN_FILES = TRUE`** loads files whose status is unknown because they're older than 64 days.
  - **TRUNCATE TABLE** deletes the table's load metadata, so the same files **can be loaded again**. (This is the guide's sample question.)
- **`PURGE = TRUE`** removes files from the stage after they load successfully. If the purge fails, there's no error, so check the stage now and then.
- **`SIZE_LIMIT`** stops after that many bytes (at least one file always loads).
- Load history: **COPY_HISTORY** (ACCOUNT_USAGE view and INFORMATION_SCHEMA function) and **LOAD_HISTORY**.

### Error handling (3.1.4)

**ON_ERROR** decides what happens when rows fail:

| Value | Effect |
|---|---|
| **ABORT_STATEMENT** | Stop the whole load at the first error. **The default for COPY.** |
| **CONTINUE** | Load the good rows, skip the bad ones |
| **SKIP_FILE** | Skip any file with an error. **The default for Snowpipe.** |
| `SKIP_FILE_<n>` / `'SKIP_FILE_<n>%'` | Skip a file only if it has at least n errors, or n% bad rows |

**VALIDATION_MODE** checks files **without loading anything**:
- `RETURN_<n>_ROWS` (for example RETURN_10_ROWS): validate and show the first n rows, or fail at the first error.
- `RETURN_ERRORS`: return all errors across the files.
- `RETURN_ALL_ERRORS`: also include errors from files partly loaded earlier with ON_ERROR = CONTINUE.
- **Not supported with transformations** in the COPY.

After a load, **`VALIDATE(table, JOB_ID => '_last')`** returns the errors from a past COPY. Column size problems: `ENFORCE_LENGTH` / `TRUNCATECOLUMNS` decide whether too-long strings fail or get cut.

### Unloading (COPY INTO <location>)

```sql
COPY INTO @my_stage/export/orders_
FROM (SELECT * FROM orders WHERE order_date >= '2026-01-01')
FILE_FORMAT = (TYPE = PARQUET)
HEADER = TRUE;
```

- The source can be a table or a **query** (with joins).
- Output is **split into multiple files** by default (`SINGLE = FALSE`), each up to **MAX_FILE_SIZE**, default **16 MB** (max 5 GB).
- **Compression by default:** **gzip** for CSV and JSON, **Snappy** for Parquet.
- `PARTITION BY <expression>` writes files into folders by value (for example by date).
- `HEADER = TRUE` adds column names. `OVERWRITE = TRUE` replaces files with the same names. `INCLUDE_QUERY_ID = TRUE` makes file names unique.
- **JSON** can only be unloaded from a **VARIANT** column, so build one with `OBJECT_CONSTRUCT(*)`.
- Then **GET** the files from an internal stage to your machine.

Sources: [COPY INTO <table>](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table) · [Preparing your data files](https://docs.snowflake.com/en/user-guide/data-load-considerations-prepare) · [Choosing an internal stage](https://docs.snowflake.com/en/user-guide/data-load-local-file-system-create-stage) · [CREATE STAGE](https://docs.snowflake.com/en/sql-reference/sql/create-stage) · [TRUNCATE TABLE](https://docs.snowflake.com/en/sql-reference/sql/truncate-table) · [Overview of data unloading](https://docs.snowflake.com/en/user-guide/data-unload-overview) · [File formats for unloading](https://docs.snowflake.com/en/user-guide/data-unload-prepare) · [COPY INTO <location>](https://docs.snowflake.com/en/sql-reference/sql/copy-into-location)

---

## Ten facts to know cold by tonight
1. **Masking policy** = column-level, **row access policy** = row-level; both schema-level, applied **at query time**, data unchanged, **Enterprise**. Row access is evaluated **before** masking. One masking policy per column.
2. **Tags:** schema-level, string values, up to 50 per object, **inherited** down the hierarchy; **tag-based masking** protects every tagged column.
3. **Aggregation policy** = must aggregate, minimum group size. **Projection policy** = column can't be in the output. **Differential privacy** = noise plus a privacy budget.
4. **Encryption:** always on; key hierarchy root → account → table → file; keys rotate every **30 days**; **periodic rekeying** yearly (Enterprise); **Tri-Secret Secure** = customer key + Snowflake key (Business Critical).
5. **Replication:** databases and shares on any edition; **account objects and failover need Business Critical**; secondaries are read-only until promoted.
6. **Resource monitors:** **ACCOUNTADMIN only**, **warehouses only** (not serverless), one account monitor, a warehouse belongs to one monitor; Notify / Suspend (waits for queries) / Suspend Immediately (cancels them). **Budgets** cover serverless and only notify.
7. **Credits:** size rate × hours, per second, **60 s minimum per resume**, × running clusters; cloud services billed only above **10%** of daily warehouse credits.
8. **ACCOUNT_USAGE:** whole account, dropped objects, **45 min–3 h** latency, **1 year**. INFORMATION_SCHEMA: one database, real time, 7 days–6 months.
9. **Stages:** `@~` user, `@%t` table (no transformations), `@name` named (recommended). External stages use a **storage integration**. Internal stages default to **SNOWFLAKE_FULL**; URLs need **SNOWFLAKE_SSE**. Unload formats: CSV, JSON, Parquet only.
10. **COPY:** skips files loaded in the last **64 days** (load metadata); **FORCE** reloads (duplicates); **TRUNCATE** clears load metadata; **PURGE** deletes loaded files; **ON_ERROR** default **ABORT_STATEMENT** (Snowpipe: **SKIP_FILE**); **VALIDATION_MODE** checks without loading.
