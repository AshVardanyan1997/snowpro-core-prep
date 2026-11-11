# Day 6 Practice Questions

- **Part A: Automated ingestion** (12 questions on objective 3.2).
- **Part B: Connectors and integrations** (5 questions on objective 3.3).
- **Part C: Data collaboration** (15 questions on objectives 5.1 to 5.3).

32 questions, about 37 minutes at exam pace. Answer them after the notes and the lab. Mark your answers the same way as before. Answers and explanations are at the bottom. Cover them while you work, and add every miss to your error log.

Several questions put two related features side by side, the trap you've hit before. Look for the one word in the question that fits only one of them.

---

## Part A · Automated ingestion (3.2)

**A1.** Files land in an S3 bucket every few minutes and must load automatically, without a warehouse. What should you use?
A. A task running COPY every minute on a warehouse  B. Snowpipe with AUTO_INGEST and S3 event notifications  C. Snowpipe Streaming  D. A dynamic table

**A2.** How long does Snowpipe keep load metadata to avoid loading the same file twice?
A. 24 hours  B. 7 days  C. 14 days  D. 64 days

**A3.** What is Snowpipe's default ON_ERROR behaviour?
A. ABORT_STATEMENT  B. CONTINUE  C. SKIP_FILE  D. SKIP_FILE_1%

**A4.** A mobile app sends millions of small events per hour, and they must be queryable within seconds. No files are involved. What fits best?
A. Snowpipe with REST API calls  B. Snowpipe Streaming  C. External tables  D. COPY INTO every minute

**A5.** What does a stream store?
A. A full copy of the changed rows  B. An offset (a point in the source table's change history)  C. A copy of the whole table  D. The text of the DML statements

**A6.** A standard stream shows 10 rows. You run `SELECT * FROM my_stream` three times. How many rows does the fourth SELECT return, if nothing else changed?
A. 0  B. 10  C. 30  D. An error, because the stream is stale

**A7.** In a standard stream, how does an UPDATE to one row appear?
A. One row with METADATA$ACTION = 'UPDATE'  B. Two rows, a DELETE and an INSERT, with METADATA$ISUPDATE = TRUE  C. One INSERT row with METADATA$ISUPDATE = TRUE  D. Updates aren't tracked

**A8.** Which stream type is used on external tables?
A. Standard  B. Append-only  C. Insert-only  D. Delta

**A9.** You create a task with CREATE TASK and a SCHEDULE. An hour later it hasn't run. Why?
A. Tasks need a warehouse  B. Tasks are created suspended and need ALTER TASK … RESUME  C. The schedule must use CRON  D. Tasks only run when a stream has data

**A10.** Which statements about task graphs are TRUE? (Select TWO)
A. Every task in the graph has its own schedule  B. Child tasks use AFTER to name their parent tasks  C. To change a task in the graph, you must suspend the root task first  D. Tasks in one graph can be in different databases  E. A graph can have any number of finalizer tasks

**A11.** An analyst wants to write one SELECT with joins and aggregations, and have Snowflake keep its result at most 15 minutes behind the source tables. No procedural logic is needed. What fits best?
A. A materialized view  B. A dynamic table with TARGET_LAG = '15 minutes'  C. A stream and a task  D. A secure view

**A12.** Which is TRUE about dynamic tables?
A. You can INSERT into them to add corrections  B. TARGET_LAG = DOWNSTREAM refreshes the table only when a table that depends on it needs fresh data  C. They always refresh in full  D. Their minimum target lag is 1 second

---

## Part B · Connectors and integrations (3.3)

**B1.** A finance team's BI tool connects to databases through a standard Windows driver interface. Which Snowflake driver does it most likely use?
A. The Kafka connector  B. ODBC  C. The Spark connector  D. Snowpipe Streaming SDK

**B2.** By default, which two columns does the Snowflake Connector for Kafka create in each target table? (Select TWO)
A. RECORD_CONTENT  B. RECORD_KEY  C. RECORD_METADATA  D. METADATA$ACTION  E. TOPIC_NAME

**B3.** Which object lets an external stage access an S3 bucket through an IAM role, without keys in SQL?
A. API integration  B. Storage integration  C. Notification integration  D. Security integration

**B4.** Which object does Snowflake need to call an exchange-rate service behind Amazon API Gateway as an external function?
A. Storage integration  B. API integration  C. Git repository  D. Network policy

**B5.** Which statements about Git integration are TRUE? (Select TWO)
A. CREATE GIT REPOSITORY uses an API integration with API_PROVIDER = git_https_api  B. You can commit and push changes back to GitHub from the repository object  C. Credentials for a private repository are stored in a secret  D. Git repositories can only be connected through a storage integration

---

## Part C · Data collaboration (5.1 to 5.3)

**C1.** A colleague deleted the wrong rows 20 minutes ago. Which query shows the table exactly as it was just before that DELETE?
A. `SELECT * FROM t AT(OFFSET => 20)`  B. `SELECT * FROM t BEFORE(STATEMENT => '<delete query id>')`  C. `SELECT * FROM t FAILSAFE`  D. `UNDROP TABLE t`

**C2.** What is the maximum Time Travel retention for a permanent table on Enterprise edition?
A. 1 day  B. 7 days  C. 30 days  D. 90 days

**C3.** What is the maximum Time Travel retention for a transient table on Enterprise edition?
A. 0 days  B. 1 day  C. 7 days  D. 90 days

**C4.** Which statements about Fail-safe are TRUE? (Select TWO)
A. It lasts 7 days after Time Travel ends  B. Users can query Fail-safe data with AT  C. Only Snowflake Support can recover data from it  D. Transient tables have 7 days of Fail-safe  E. You can set it to 14 days on Enterprise

**C5.** You run `UNDROP TABLE promotions`, but it fails. What's the most likely reason?
A. UNDROP only works on databases  B. A table named promotions already exists  C. You need Business Critical  D. The table was transient

**C6.** You clone a 2 TB database. Immediately afterwards, how much extra storage does the clone use?
A. 2 TB  B. About 1 TB  C. Almost none, until data in one of them changes  D. It depends on the warehouse size

**C7.** You clone a schema that contains a stream and a scheduled task. What do you find in the clone? (Select TWO)
A. The task is suspended  B. The task is running on its schedule  C. The stream's unconsumed changes from the original are inaccessible  D. The stream has a copy of all unconsumed changes

**C8.** Sevan shares a secure view with a consumer account. Who pays for what?
A. The consumer pays storage and compute  B. The provider pays storage, the consumer pays compute for its queries  C. The provider pays everything  D. Snowflake pays storage, the consumer pays compute

**C9.** A partner has no Snowflake account but needs to query shared data. What's the solution, and who pays for its compute?
A. A reader account, paid for by the provider  B. A reader account, paid for by the partner  C. A listing, paid for by Snowflake  D. A data clean room, paid for by the partner

**C10.** Which actions can a consumer perform on a database created from a direct share? (Select TWO)
A. Query the shared objects with its own warehouse  B. Update rows in a shared table  C. Clone the shared database  D. Create views in its own database that select from the shared data  E. Use Time Travel on the shared tables

**C11.** A provider in AWS Frankfurt wants to share data with an account in Azure East US. What's TRUE?
A. A direct share works across any region  B. A direct share only works within one region, so it needs replication or a listing with auto-fulfillment  C. Cross-region sharing is not possible  D. The consumer must move its account to Frankfurt

**C12.** Two companies want to count their overlapping customers without either seeing the other's customer list. What fits best?
A. A direct share in both directions  B. A data clean room  C. A reader account  D. A public listing

**C13.** What is the difference between a private listing and a public listing?
A. Private listings are free, public ones are paid  B. Private listings go to specific named accounts, public listings appear on the Snowflake Marketplace  C. Private listings copy the data, public ones don't  D. Public listings only work in one region

**C14.** Which feature delivers a listing's data product to consumers in other regions without the provider setting up replication by hand?
A. Client Redirect  B. Cross-Cloud Auto-Fulfillment  C. Failover groups  D. Reader accounts

**C15.** What does a Snowflake Native App application package contain? (Select TWO)
A. A manifest file  B. A setup script  C. The consumer's data  D. A reader account  E. A storage integration

---

## Answers

### Part A
| Q | Answer | Why |
|---|---|---|
| A1 | B | Snowpipe with AUTO_INGEST loads files when the cloud's event notification arrives, on serverless compute. Snowpipe Streaming is for rows, not files. |
| A2 | C | 14 days for pipes. Bulk COPY keeps load metadata for 64 days. |
| A3 | C | SKIP_FILE. Pipes don't even accept ABORT_STATEMENT, which is the bulk COPY default. |
| A4 | B | "No files" and "within seconds" both point to Snowpipe Streaming: rows through an SDK, latency as low as about 5 seconds. |
| A5 | B | Only an offset. The change data is read from the table's history when you query the stream. |
| A6 | B | SELECT never moves the offset. Only a DML statement that reads the stream and commits does. |
| A7 | B | An update is a DELETE (old version) plus an INSERT (new version), both with METADATA$ISUPDATE = TRUE. |
| A8 | C | Insert-only streams are for external tables (and externally managed Iceberg tables). Append-only is for standard tables, views and dynamic tables. |
| A9 | B | Tasks, like alerts, are created suspended. Tasks without a warehouse run serverless, so A is wrong. |
| A10 | B, C | Only the root task has a schedule, and children use AFTER. You must suspend the root to change any task. All tasks must share an owner, database and schema, and a root has at most one finalizer. |
| A11 | B | A declarative SELECT with joins plus a freshness target is exactly a dynamic table. Materialized views can't join. Streams and tasks are for procedural logic. |
| A12 | B | DOWNSTREAM refreshes on demand for dependents. No DML is allowed, refresh can be incremental, and the minimum lag is 60 seconds. |

### Part B
| Q | Answer | Why |
|---|---|---|
| B1 | B | ODBC is the standard driver interface most BI tools use (JDBC is the Java equivalent). |
| B2 | A, C | RECORD_CONTENT holds the message, RECORD_METADATA the topic, partition, offset and so on. Both are VARIANT. |
| B3 | B | A storage integration holds the IAM role (or Azure or GCP identity) for external stages. |
| B4 | B | External functions call proxy services such as API Gateway through an API integration. |
| B5 | A, C | The repository object is a read-only clone that you FETCH into Snowflake. It uses an API integration (git_https_api), with credentials in a secret. |

### Part C
| Q | Answer | Why |
|---|---|---|
| C1 | B | BEFORE(STATEMENT => query id) is the most precise. OFFSET is in seconds and must be negative (-1200 here), so A is wrong. |
| C2 | D | 90 days for permanent objects on Enterprise or higher. The default is 1. |
| C3 | B | Transient and temporary tables: 0 or 1 day, on every edition. |
| C4 | A, C | 7 days, not configurable, permanent tables only, recovery by Snowflake Support only. Transient tables have no Fail-safe. |
| C5 | B | UNDROP fails if an object with the same name exists. Rename it first. |
| C6 | C | Zero-copy: the clone points to the same micro-partitions. Storage is added only for changed data. |
| C7 | A, C | Cloned tasks start suspended. Unconsumed changes in a cloned stream are inaccessible. |
| C8 | B | No data is copied. The provider keeps paying for storage, and the consumer pays for the warehouse it queries with. |
| C9 | A | Reader accounts are created, owned and paid for by the provider, compute included. |
| C10 | A, D | Shared data is read-only. Consumers can't modify, clone or Time Travel it, but they can query it and build their own views on it. |
| C11 | B | Direct shares are same-region only. Use replication or a listing with Cross-Cloud Auto-Fulfillment. |
| C12 | B | A clean room allows only approved, aggregated analyses, with no access to raw rows. A share would expose the rows. |
| C13 | B | Private = named accounts, public = Marketplace. Both can be free or paid, and neither copies data within a region. |
| C14 | B | Cross-Cloud Auto-Fulfillment. Client Redirect is about connections during failover. |
| C15 | A, B | The manifest (manifest.yml) and the setup script, plus the app's code and data. The app runs in the consumer's account, on the consumer's data. |

**Scoring:** 85% or more overall (28/32) means you're ready for Mock 1. Under 70% (23/32) means you should reread the "What to keep" boxes in [notes.md](notes.md) and redo lab sections 1 and 5 first.
