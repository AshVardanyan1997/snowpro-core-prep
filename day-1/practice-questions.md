# Day 1 Practice Questions

- **Part A: Diagnostic** (15 questions, mixed domains). Answer these **before** reading the notes. Allow 17 minutes, about 69 seconds per question, which is exam pace. Then also answer the 5 sample questions on pages 12 and 13 of the official study guide.
- **Part B: Day 1 topics** (20 questions on objectives 1.1, 1.3 and 1.5). Answer these after the notes and the lab.

Answers and explanations are at the bottom. Cover them while you work. Add every miss to your error log, with the topic, why you chose your answer, and the correct fact.

---

## Part A · Diagnostic (mixed domains)

**A1.** Which Snowflake layer is responsible for query optimization?
A. Database Storage  B. Compute  C. Cloud Services  D. The virtual warehouse's local disk

**A2.** A team's reports queue during the 9 am peak but run quickly once they start. What is the most appropriate change?
A. Increase the warehouse size  B. Configure a multi-cluster warehouse  C. Add a clustering key  D. Enable Search Optimization

**A3.** Which role is designed to create users and roles, following the principle of least privilege?
A. ACCOUNTADMIN  B. SECURITYADMIN  C. USERADMIN  D. SYSADMIN

**A4.** Which COPY INTO option checks files for errors without loading any data?
A. ON_ERROR = CONTINUE  B. VALIDATION_MODE = RETURN_ERRORS  C. FORCE = TRUE  D. PURGE = TRUE

**A5.** How long is data in Fail-safe for a permanent table?
A. 1 day  B. 7 days  C. 14 days  D. 90 days

**A6.** A data consumer has no Snowflake account. How can a provider share data with them? (Choose one.)
A. A direct share to the consumer's email address  B. A reader account  C. Exporting to an external stage  D. A public listing only

**A7.** Query Profile shows "Bytes spilled to remote storage". What is the most direct fix?
A. Use a larger warehouse  B. Add more clusters  C. Enable the result cache  D. Create a secure view

**A8.** Which object tracks row-level changes (CDC) on a table so they can be processed later?
A. Task  B. Pipe  C. Stream  D. Sequence

**A9.** What is the minimum edition that supports column-level dynamic data masking?
A. Standard  B. Enterprise  C. Business Critical  D. VPS

**A10.** Which cache can return a query result without a running warehouse? (Choose two.)
A. The result cache  B. The warehouse local disk cache  C. The metadata cache  D. The remote disk cache

**A11.** Which serverless feature loads files continuously as soon as they arrive in a cloud storage bucket?
A. COPY INTO run by a task  B. Snowpipe with auto-ingest  C. External tables  D. Dynamic tables

**A12.** Which Cortex feature turns a natural-language business question into SQL, using a semantic model?
A. Cortex Search  B. AI_COMPLETE  C. Cortex Analyst  D. AI_CLASSIFY

**A13.** Which statement about zero-copy cloning is true?
A. A clone copies all micro-partitions straight away  B. A clone shares storage with the source until either one changes  C. Clones can only be made of tables  D. Clones keep the Time Travel history of the source

**A14.** Which view gives one year of query history, including history for dropped objects?
A. INFORMATION_SCHEMA.QUERY_HISTORY()  B. SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY  C. SHOW QUERIES  D. Query Profile

**A15.** Which statement about a dynamic table is true?
A. Its refresh schedule is set with a CRON expression  B. You set a TARGET_LAG and Snowflake schedules the refreshes  C. It needs a stream on every source table  D. It can only do full refreshes

---

## Part B · Day 1 topics (1.1, 1.3, 1.5)

**B1.** Which statements about Snowflake's architecture are true? (Choose two.)
A. Compute and storage scale independently  B. Every warehouse shares one local cache  C. Data is stored in a columnar, compressed format  D. Users can access the underlying micro-partition files directly

**B2.** On one day, warehouses use 100 credits and cloud services uses 8 credits. How many cloud services credits are billed?
A. 8  B. 0  C. 10  D. 108

**B3.** A company needs its own AWS PrivateLink connectivity and HIPAA compliance. What is the minimum edition?
A. Standard  B. Enterprise  C. Business Critical  D. VPS

**B4.** Which features need at least Enterprise edition? (Choose three.)
A. Multi-cluster warehouses  B. Time Travel of 30 days  C. Secure Data Sharing  D. Materialized views  E. Snowpipe

**B5.** Which of these are schema-level objects? (Choose two.)
A. Warehouse  B. Named stage  C. Resource monitor  D. File format  E. Share

**B6.** `TIMEZONE` is set to UTC for the account, to America/New_York for the user, and to Europe/Paris with ALTER SESSION. Which time zone does a query in that session use?
A. UTC  B. America/New_York  C. Europe/Paris  D. The warehouse's region

**B7.** `DATA_RETENTION_TIME_IN_DAYS` is 1 for the account, 7 for database DB and 30 for table DB.S.T, with nothing set on schema S. What is the retention for DB.S.T and for another table DB.S.U?
A. 30 and 1  B. 30 and 7  C. 7 and 7  D. 1 and 1

**B8.** What size range of **uncompressed** data does a micro-partition hold?
A. 1 to 16 MB  B. 16 to 50 MB  C. 50 to 500 MB  D. 1 to 5 GB

**B9.** Which statements about micro-partitions are true? (Choose two.)
A. Users define partition boundaries with PARTITION BY  B. They are immutable  C. Metadata records the range of values for each column  D. Each micro-partition stores a single column

**B10.** What does a clustering depth close to 1 mean?
A. The table is poorly clustered  B. The table is well clustered  C. The table has a single micro-partition  D. Automatic Clustering is turned off

**B11.** For which table is a clustering key most appropriate?
A. A 50 MB lookup table  B. A 20 TB event table that is always filtered on event date, and whose query performance has degraded  C. A table that is fully reloaded every hour  D. A table queried only with SELECT *

**B12.** A team loads staging data that it can regenerate, and it wants to keep storage costs as low as possible. Which table type should it use?
A. Permanent  B. Transient  C. External  D. Hybrid

**B13.** Which statements about temporary tables are true? (Choose two.)
A. Other sessions can see them  B. They are dropped when the session ends  C. They have no Fail-safe  D. They support 90 days of Time Travel on Enterprise

**B14.** A user creates a temporary table called ORDERS in a schema that already has a permanent table called ORDERS. What does `SELECT * FROM ORDERS` return in that session?
A. An error about an ambiguous name  B. Data from the permanent table  C. Data from the temporary table  D. Data from both tables combined

**B15.** What can you do with ALTER TABLE on a transient table?
A. Convert it to a permanent table  B. Set DATA_RETENTION_TIME_IN_DAYS = 0  C. Set DATA_RETENTION_TIME_IN_DAYS = 7  D. Turn on Fail-safe

**B16.** A company wants Spark jobs and Snowflake to read and write the same tables in its own S3 bucket, using an open table format. What should it use?
A. External tables  B. Apache Iceberg tables with the Snowflake catalog  C. Transient tables  D. Hybrid tables

**B17.** Which statements about materialized views are true? (Choose two.)
A. They can join several tables  B. A serverless background service keeps them up to date  C. They need Enterprise edition  D. They use no extra storage

**B18.** Why would you create a secure view instead of a standard view? (Choose two.)
A. To hide the view definition from users who don't own it  B. To make queries run faster  C. To be able to share the view with another account  D. To store its results

**B19.** Which statements need a running warehouse? (Choose one.)
A. `SELECT COUNT(*) FROM big_table`  B. `SHOW TABLES`  C. `SELECT AVG(amount) FROM big_table WHERE region = 'EU'`  D. `CREATE TABLE t (id INT)`

**B20.** Which of these is the preferred account identifier format?
A. `xy12345`  B. `xy12345.us-east-1.aws`  C. `myorg-myaccount`  D. `myaccount.snowflakecomputing.com/myorg`

---

## Answers

### Part A
| Q | Answer | Why |
|---|---|---|
| A1 | C | Cloud Services parses and optimizes queries, and the warehouse then runs them. |
| A2 | B | Queuing is a **concurrency** problem, so scale **out** with more clusters. Increasing the size (A) helps complex queries, not queuing. |
| A3 | C | USERADMIN has CREATE USER and CREATE ROLE. SECURITYADMIN sits above it and also manages grants. |
| A4 | B | VALIDATION_MODE is a dry run. |
| A5 | B | Fail-safe is 7 days for permanent tables. Transient and temporary tables have none. |
| A6 | B | A reader account is managed by the provider, and the provider pays for its compute. |
| A7 | A | Spilling means the warehouse has run out of memory and local disk, so scale **up**. |
| A8 | C | A stream records an offset, which lets you see the changes made since it was last consumed. |
| A9 | B | Enterprise. Masking and row access policies aren't available on Standard. |
| A10 | A, C | The result cache and metadata cache live in cloud services. The local disk cache needs a running warehouse. |
| A11 | B | Snowpipe auto-ingest is triggered by cloud event notifications. |
| A12 | C | Cortex Analyst turns natural language into SQL using a semantic model. Cortex Search is for search and RAG. |
| A13 | B | Clones are metadata-only until either the clone or the source changes. |
| A14 | B | ACCOUNT_USAGE keeps 1 year of history, includes dropped objects, and has some latency. INFORMATION_SCHEMA keeps 7 days and runs in real time. |
| A15 | B | Dynamic tables are declarative: you set TARGET_LAG and Snowflake refreshes them incrementally or fully. |

### Part B
| Q | Answer | Why |
|---|---|---|
| B1 | A, C | Each warehouse has its **own** local cache, and users never see the micro-partition files. |
| B2 | B | 10% of 100 is 10 credits, and 8 is below that, so nothing is billed. Cloud services is billed only for usage above 10% of daily warehouse credits. |
| B3 | C | PrivateLink and HIPAA support need Business Critical. |
| B4 | A, B, D | Sharing and Snowpipe are available on Standard. Time Travel beyond 1 day needs Enterprise. |
| B5 | B, D | Warehouses, resource monitors and shares are account-level objects. |
| B6 | C | Session beats user, which beats account. |
| B7 | B | Table T sets its own value (30). Table U inherits from the nearest level that sets one: schema S has none, so it gets 7 from database DB. |
| B8 | C | 50 to 500 MB uncompressed. |
| B9 | B, C | Micro-partitions are created automatically, and each one holds **all** columns for its rows, stored column by column. |
| B10 | B | Lower depth means less overlap between micro-partitions, so pruning works better. |
| B11 | B | Clustering keys pay off on very large tables with a stable filter column and degraded pruning. They cost credits, so they're wasted on small tables or tables that churn constantly. |
| B12 | B | Transient tables have no Fail-safe, so there are no 7 days of extra storage costs. |
| B13 | B, C | Temporary tables are visible only to their session, and their Time Travel is at most 1 day. |
| B14 | C | A temporary table hides the permanent table with the same name for the rest of that session. |
| B15 | B | A transient table can have 0 or 1 day of retention. Its type can't be changed with ALTER, and it never has Fail-safe. |
| B16 | B | Iceberg tables are the open format. With the Snowflake catalog, Snowflake can read and write them, and external engines can read them. External tables are read-only and are not an open table format. |
| B17 | B, C | A materialized view queries a single table only, and it uses extra storage for its results. |
| B18 | A, C | Secure views can be slower, because some optimizations are turned off. Only a materialized view stores results. |
| B19 | C | COUNT(*) without a filter is answered from metadata. SHOW and CREATE statements run in cloud services. An AVG with a filter has to scan the data. |
| B20 | C | `orgname-accountname` is preferred. The account locator in A and B is the legacy form. |

**Scoring:** 85% or more on Part B means you're ready for Day 2. Below 70% means you should reread the "Ten facts" section of [notes.md](notes.md) before you start Day 2.
