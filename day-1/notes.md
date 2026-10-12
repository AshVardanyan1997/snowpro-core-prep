# Day 1 · Mon Oct 12 · Architecture, Object Hierarchy, Storage

**Covers:** objectives 1.1, 1.3 and 1.5 (Domain 1, 31% of the exam) · **Time:** about 3 hours

| Block | Time | What to do |
|---|---|---|
| Setup | 15 min | Sign up for a trial account (choose **Enterprise**) and a Snowflake University (Community) login |
| Diagnostic | 30 min | Answer [practice-questions.md](practice-questions.md) Part A **cold** and score it |
| Notes | 60 min | Read this file |
| Lab | 45 min | Run [lab.sql](lab.sql) in a Snowsight worksheet |
| Practice | 30 min | Answer [practice-questions.md](practice-questions.md) Part B, then log every miss |

Snowflake's free Level Up courses cover the same ground if you want to go further: *Snowflake's Key Concepts*, *Container Hierarchy*, and *Accounts & Assurances*.

---

## 1.1 Architecture

Snowflake has a **hybrid** architecture. Storage is shared, as in a shared-disk system. Compute uses MPP clusters, as in a shared-nothing system. The two layers scale **independently**.

| Layer | What it does | What exam questions focus on |
|---|---|---|
| **Database Storage** | Stores data in cloud object storage (S3, Azure Blob, GCS) as compressed, columnar **micro-partitions**. Snowflake manages it, and users can't see the files. | You pay for compressed storage, averaged over the month. Time Travel and Fail-safe data count towards it. |
| **Compute** (virtual warehouses) | Runs queries, DML and loading. Each warehouse is an independent MPP cluster. | Warehouses **don't share** compute or local cache. A query from one warehouse never slows down another. |
| **Cloud Services** | The "brain": authentication, access control, the metadata store, query parsing and optimization, transactions, and infrastructure management. | It is billed **only for the part of daily usage above 10%** of that day's warehouse credits. It serves the result cache and metadata-only queries. |

Exam traps:
- "Which layer optimizes the query?" The answer is **Cloud Services**, not the warehouse.
- "Which layer holds the result cache?" The answer is **Cloud Services**. The warehouse holds the *local disk* cache.
- `SELECT COUNT(*) FROM t` or `MIN` and `MAX` on a column can be answered from **metadata alone**, so no warehouse needs to run.
- `CREATE TABLE`, `SHOW` and `DESCRIBE` statements don't need a running warehouse.

### Editions

Each edition includes everything in the editions above it.

| Edition | What it adds |
|---|---|
| **Standard** | All core features, Time Travel up to **1 day**, Secure Data Sharing, Snowpipe, encryption at rest and in transit, federated authentication and MFA |
| **Enterprise** | **Multi-cluster warehouses**, Time Travel **up to 90 days**, **materialized views**, **column masking and row access policies**, **Search Optimization**, **Query Acceleration**, object tagging, periodic rekeying |
| **Business Critical** | **Tri-Secret Secure** (a customer-managed key), **PrivateLink**, HIPAA and PCI DSS support, **database failover and failback** |
| **VPS** (Virtual Private Snowflake) | A completely separate Snowflake environment that shares no hardware with other accounts |

> Memory hook: for a "which minimum edition" question, ask whether the feature is about **scale or governance**, which points to Enterprise, or **compliance or network isolation**, which points to Business Critical.

---

## 1.3 Object hierarchy

```
ORGANIZATION
└── ACCOUNT  (users, roles, warehouses, resource monitors, integrations,
    │         network policies, shares, databases, applications)
    └── DATABASE
        └── SCHEMA
            └── tables · views · stages · file formats · sequences ·
                UDFs · stored procedures · pipes · streams · tasks ·
                dynamic tables · ML models · alerts · secrets · policies
```

- **Account-level objects** (not inside a database): users, roles, warehouses, resource monitors, storage, API and notification integrations, network policies, **shares** and databases. Installed **applications** (Native Apps) also sit at account level.
- **Schema-level objects**: everything else, including **stages and file formats**, which people often wrongly think are account-level.
- **Fully qualified name:** `database.schema.object`. Name resolution uses the current database and schema of the session.
- **Account identifier:** the preferred form is `orgname-accountname`. The legacy **account locator** looks like `xy12345.us-east-1` and is tied to a region.

### Parameters and their precedence

Parameters come in three kinds:
- **Account parameters** can only be set at account level, for example `NETWORK_POLICY` and `PERIODIC_DATA_REKEYING`.
- **Session parameters** default at account level, can be overridden per **user**, and then per **session**. Examples are `TIMEZONE`, `QUERY_TAG`, `USE_CACHED_RESULT` and `STATEMENT_TIMEOUT_IN_SECONDS`.
- **Object parameters** default at account level and can be overridden at **database, then schema, then table**, or on a warehouse or user. Examples are `DATA_RETENTION_TIME_IN_DAYS` and `MAX_CONCURRENCY_LEVEL`.

**The most specific setting wins:**
- Session settings beat user settings, which beat account settings.
- Table settings beat schema settings, which beat database settings, which beat account settings.

```sql
SHOW PARAMETERS LIKE 'TIMEZONE' IN SESSION;   -- the "level" column shows where the value came from
ALTER SESSION SET TIMEZONE = 'Europe/Berlin';
```

### Context functions and session variables
- `CURRENT_ROLE()`, `CURRENT_WAREHOUSE()`, `CURRENT_DATABASE()`, `CURRENT_SCHEMA()`, `CURRENT_USER()`, `CURRENT_ACCOUNT()`, `CURRENT_REGION()`, `CURRENT_SESSION()`.
- Session variables: `SET x = 10; SELECT $x;`. They last only for the session.

---

## 1.5 Storage concepts

### Micro-partitions
- They are created **automatically** as data is loaded, in insertion order. You can't define partitions yourself.
- Each one holds **50 to 500 MB of uncompressed data**, stored columnar and compressed.
- They are **immutable**. An UPDATE or DELETE writes new micro-partitions, and the old ones are kept for Time Travel and Fail-safe.
- Their metadata records the min and max value of each column, the number of distinct values, the null count and so on. **Pruning** uses this metadata to skip micro-partitions that can't match the WHERE clause.

### Clustering
- **Clustering depth** is the average number of micro-partitions that overlap for a given value. Lower is better. A table with no micro-partitions has depth 0, and a well-clustered table has depth close to 1.
- `SYSTEM$CLUSTERING_INFORMATION('t', '(col)')` and `SYSTEM$CLUSTERING_DEPTH` show how well a table is clustered.
- Define a **clustering key** only for **very large (multi-TB) tables** whose queries filter on the same columns, and whose clustering has degraded. **Automatic Clustering** is serverless and **costs credits**.
- Good keys have enough distinct values to prune well, but not so many that clustering becomes expensive. A raw timestamp is too fine; `TO_DATE(ts)` is a good choice.

### Table types

| Type | Lasts | Time Travel | Fail-safe | Typical use |
|---|---|---|---|---|
| **Permanent** (the default) | until dropped | 0 to 1 day (Standard), **0 to 90 days** (Enterprise and above) | **7 days** | Production data |
| **Transient** | until dropped | 0 to 1 day | **none** | Staging and ETL data you can regenerate |
| **Temporary** | **the session only** (not visible to other sessions) | 0 to 1 day | **none** | Intermediate data inside one session |
| **External** | metadata over files in an external stage | none | none | Querying a data lake without loading it (read-only) |
| **Apache Iceberg™** | Data and metadata in **your** cloud storage, through an **external volume**. With the Snowflake catalog it is read-write. With an external catalog (such as AWS Glue) it is mostly read-only. | Snowflake-catalog tables only | none | Open table format that Spark, Trino and other engines can share |
| **Dynamic** | defined by a query plus `TARGET_LAG` | yes | yes | Declarative pipelines (covered in Domain 3) |
| **Hybrid** | row-store, for Unistore | not tested | not tested | Low-latency single-row lookups with enforced primary keys |

Exam traps:
- A **temporary** table with the same name as a permanent one **hides** the permanent one for the rest of that session.
- **Transient databases and schemas** make every table created in them transient.
- You **can't** change a table from permanent to transient with ALTER. Instead, use CREATE … AS SELECT, or clone the table into a transient table.
- **Fail-safe** can't be configured or queried, and only Snowflake Support can recover data from it.

### View types

| View | What it is | Points to remember |
|---|---|---|
| **Standard** | A stored query | Anyone with the right privileges can see its definition. Its results are not stored. |
| **Materialized** | Precomputed results, kept up to date by a **serverless** background service | **Enterprise and above.** It can query **a single table only**: no joins, no window functions and no UDFs. It costs storage plus maintenance compute. |
| **Secure** | Hides its definition (`GET_DDL` shows it only to the owner) and turns off optimizations that could leak data | It can be **slightly slower**. It is **required for sharing** views. A materialized view can be secure too. |

---

## Ten facts to know cold by tonight
1. Snowflake has **three layers**: storage, compute and cloud services. Storage and compute scale independently.
2. Cloud services is billed only for the part **above 10%** of daily warehouse credits.
3. Micro-partitions hold **50 to 500 MB uncompressed**, are immutable and columnar, and come with min/max metadata.
4. The **result cache lives in cloud services**, and the local disk cache lives in the warehouse.
5. **Enterprise** adds multi-cluster warehouses, 90-day Time Travel, materialized views, masking, Search Optimization and Query Acceleration.
6. **Business Critical** adds Tri-Secret Secure, PrivateLink, HIPAA and PCI support, and failover.
7. **Stages and file formats are schema-level** objects. **Shares, warehouses and roles are account-level.**
8. For parameters, the most specific setting wins: session over user over account, and table over schema over database over account.
9. Fail-safe lasts **7 days for permanent tables only**. Transient and temporary tables have Time Travel of 0 to 1 day and no Fail-safe.
10. Materialized views query a single table, need Enterprise, and are maintained serverlessly. Secure views are required for sharing.
