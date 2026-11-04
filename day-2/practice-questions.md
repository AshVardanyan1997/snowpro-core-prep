# Day 2 Practice Questions

- **Part A: Day 1 review** (8 questions). These retest the topics you missed on Day 1: transient tables, what needs a warehouse, editions, secure views and account identifiers. Answer them **before** the notes, in about 9 minutes.
- **Part B: Day 2 topics** (22 questions on objectives 1.2, 1.4 and 1.6). Answer these after the notes and the lab, at exam pace (about 25 minutes).

Mark your answers the same way as on Day 1. Answers and explanations are at the bottom. Cover them while you work, and add every miss to your error log.

---

## Part A · Day 1 review

**A1.** Which statements about transient tables are true? (Choose two.) - I chose E should be B
A. They have 7 days of Fail-safe  B. Their Time Travel can be set to 0 or 1 day  C. They can be converted to permanent tables with ALTER TABLE  (D.) They have no Fail-safe  (E.) They are dropped when the session ends

**A2.** A schema is created with `CREATE TRANSIENT SCHEMA stg`. A user then runs `CREATE TABLE stg.orders (...)` without any keyword. What kind of table is `stg.orders`?
A. Permanent  (B.) Transient  C. Temporary  D. The statement fails

**A3.** You need a permanent copy of a transient table T. What should you do?
A. `ALTER TABLE T SET TRANSIENT = FALSE`  B. `ALTER TABLE T SET DATA_RETENTION_TIME_IN_DAYS = 7`  (C.) `CREATE TABLE T_PERM AS SELECT * FROM T`  D. Enable Fail-safe on T

**A4.** The warehouse is suspended and auto-resume is on. Which statement makes it resume?
A. `SHOW SCHEMAS`  B. `SELECT MAX(order_date) FROM orders`  C. `ALTER TABLE orders ADD COLUMN note STRING`  (D). `SELECT * FROM orders WHERE status = 'OPEN'`

**A5.** Which features require at least Enterprise edition? (Choose two.) - I chose E should be A
A. Row access policies  B. Secure Data Sharing  (C.) Search Optimization  D. Tri-Secret Secure  (E.) Snowpipe

**A6.** A provider wants to share a view with a consumer account. What must be true of the view?
A. It must be a materialized view ( B.) It must be a secure view  C. It must be in a transient database  D. It must reference only one table

**A7.** Which is an account identifier in the preferred format? - I chose D should be B
A. `ab12345.eu-west-1`  B. `acme-finance_prod`  C. `ab12345` ( D.) `finance_prod.acme`

**A8.** Which statements about clones are true? (Choose two.)
(A.) A clone shares micro-partitions with its source until either one changes  B. Creating a clone copies all data immediately ( C.) A clone is independent: changes to it don't affect the source  D. A clone keeps the Time Travel history of its source

---

## Part B · Day 2 topics (1.2, 1.4, 1.6)

**B1.** A Medium warehouse runs for 90 seconds and then suspends. How many credits does it use?
A. 0.025  (B.) 0.1  C. 0.067  D. 4

**B2.** A query on a Small warehouse shows heavy "Bytes spilled to remote storage" in Query Profile. Other queries are not queuing. What should you do? - should have been C
(A). Raise MAX_CLUSTER_COUNT  B. Change the scaling policy to Economy  C. Resize the warehouse to Large  D. Lower AUTO_SUSPEND

**B3.** About 200 analysts open the same dashboards every Monday at 9 am, and their queries wait in the queue. Each query is simple. What is the best configuration?
A. A 4XL single-cluster warehouse  (B.) A multi-cluster warehouse in auto-scale mode  C. A Snowpark-optimized warehouse  D. Turn off auto-resume

**B4.** Which statements about the Economy scaling policy are true? (Choose two.)
A. It starts a new cluster as soon as a query queues ( B.) It starts a new cluster only if the system estimates it will be busy for at least 6 minutes  (C). It favours saving credits over avoiding queuing  D. It is the default policy

**B5.** A multi-cluster warehouse has MIN_CLUSTER_COUNT = 4 and MAX_CLUSTER_COUNT = 4. What mode is it in? - should be B
(A.) Auto-scale  B. Maximized  C. Economy  D. Standard

**B6.** What is the minimum edition that supports multi-cluster warehouses?
A. Standard (B.)Enterprise  C. Business Critical  D. VPS

**B7.** A data scientist trains a large scikit-learn model in a Snowpark Python stored procedure, and it fails with out-of-memory errors. What should they use?
A. A larger standard warehouse with more clusters  (B.) A Snowpark-optimized warehouse  C. Query Acceleration  D. The result cache

**B8.** Which statement about Standard Gen 2 warehouses is true?
A. They have 16x the memory of a standard warehouse  B. They are only for Snowpark code  (C.) They are especially faster for DML such as MERGE, UPDATE and DELETE  D. They are available in every size up to 6XL

**B9.** You resize a running warehouse from Small to Large. What happens to a query that was already running?-should be B
(A). It is cancelled and restarted on the Large size  B. It finishes on the resources it started with  C. It moves to the new nodes as they come online  D. It fails

**B10.** Which settings fit a warehouse used only for nightly batch loading with COPY INTO? (Choose two.)
(A.) AUTO_SUSPEND = 60  B. A 4XL size so that every file loads faster  (C.) A dedicated warehouse, separate from BI users  D. MAX_CLUSTER_COUNT = 10

**B11.** Why would you set a **longer** AUTO_SUSPEND on a BI warehouse? - -should be B
(A.) To reduce the 60-second minimum charge  B. To keep the warehouse's local disk cache warm  C. To keep the result cache, which is lost when the warehouse suspends  D. Because BI warehouses can't auto-resume

**B12.** A query is submitted to a warehouse with AUTO_RESUME = TRUE while the warehouse is suspended. What happens?
A. The query fails  (B). The warehouse resumes and runs the query  C. The query runs in cloud services  D. The query waits until an admin resumes the warehouse

**B13.** Which privilege lets a role suspend and resume a warehouse without being able to change its size?
A. USAGE ( B.) OPERATE  C. MODIFY  D. MONITOR

**B14.** Which command-line tool is the recommended successor to SnowSQL and can deploy Streamlit apps and Native Apps?
A. SnowSQL 2 ( B.) Snowflake CLI (`snow`)  C. The VS Code extension  D. The Snowpark Python library

**B15.** In Snowsight, where do you see the operator tree and statistics such as partitions scanned for a query?
A. Worksheets ( B. )Query Profile  C. Dashboards  D. The Marketplace

**B16.** Which statements about Snowpark DataFrames are true? (Choose two.)
(A.) They are evaluated lazily, when an action such as `collect()` runs  B. The data is downloaded to the client for processing  (C.) Operations are translated to SQL and pushed down to a warehouse  D. They run only in cloud services, without a warehouse

**B17.** Which statement about Streamlit in Snowflake is true?
A. The app runs on the user's laptop  (B.) A Streamlit app is a schema-level object and its queries run on a warehouse  C. It needs a separate cloud subscription  D. It can only show static charts

**B18.** A company wants a chatbot that answers questions from thousands of internal PDF policy documents. Which Cortex feature should retrieve the relevant passages?
A. Cortex Analyst  (B.) Cortex Search  C. AI_SENTIMENT  D. FORECAST

**B19.** A finance team wants to type "What was revenue by region last quarter?" and get an answer from tables. What does Cortex Analyst need?
A. A Cortex Search service ( B). A semantic view (or a semantic model YAML file)  C. A Snowpark-optimized warehouse  D. A materialized view

**B20.** How are Cortex AI SQL functions such as AI_COMPLETE billed?
A. A flat monthly fee  (B). By the tokens they process  C. Only by the warehouse running time  D. They are free

**B21.** Which database role, granted to PUBLIC by default, gives users access to Cortex AI functions?
(A. )SNOWFLAKE.CORTEX_USER  B. ACCOUNTADMIN  C. ORGADMIN  D. SECURITYADMIN

**B22.** Which Snowflake ML capabilities can you use with SQL alone? (Choose two.)
(A.) FORECAST ( B.) ANOMALY_DETECTION  C. Training a PyTorch model  D. The Feature Store's Python API

---

## Answers

### Part A
| Q | Answer | Why |
|---|---|---|
| A1 | B, D | Transient = 0 or 1 day of Time Travel and **no** Fail-safe. They last until dropped (E describes temporary tables). |
| A2 | B | Every table created in a transient database or schema is transient. |
| A3 | C | A table's type can't be changed with ALTER. Create a new permanent table with CTAS (or clone it). |
| A4 | D | A filtered SELECT has to scan data. SHOW and DDL run in cloud services, and MAX can come from metadata. |
| A5 | A, C | Row access policies and Search Optimization need Enterprise. Sharing and Snowpipe are on Standard; Tri-Secret Secure needs Business Critical. |
| A6 | B | Only secure views (and secure materialized views and secure UDFs) can be shared. |
| A7 | B | `orgname-accountname`. A and C are account locators, the legacy form. |
| A8 | A, C | Clones are metadata-only at first and fully independent afterwards. They don't keep the source's Time Travel history. |

### Part B
| Q | Answer | Why |
|---|---|---|
| B1 | B | Medium = 4 credits per hour. 90 seconds = 0.025 hours, and 4 × 0.025 = 0.1. It's over the 60-second minimum, so per-second billing applies. |
| B2 | C | Spilling = not enough memory, so **scale up**. More clusters (A) fix queuing, not a single query. |
| B3 | B | Many simple concurrent queries = a concurrency problem, so **scale out**. A huge single cluster still has a concurrency limit and costs far more. |
| B4 | B, C | Economy waits until a new cluster would be busy for 6 minutes, so it saves credits. Standard (the default) starts clusters as soon as queries queue. |
| B5 | B | Min = max is maximized mode. Standard and Economy are scaling policies, which only matter in auto-scale mode. |
| B6 | B | Multi-cluster warehouses need Enterprise. |
| B7 | B | Snowpark-optimized warehouses have 16x the memory per node, for ML training and memory-heavy UDFs. Clusters don't add memory to a single query. |
| B8 | C | Gen 2 is a faster standard warehouse, with named gains on DELETE, UPDATE, MERGE and table scans. A describes Snowpark-optimized, and Gen 2 isn't available for 5XL or 6XL. |
| B9 | B | Running queries finish on their original resources. Queued and new queries use the new size. |
| B10 | A, C | Loading speed depends on files, not huge warehouses, and one batch doesn't need concurrency. Keep it isolated and suspend quickly. |
| B11 | B | The local disk cache is lost on suspend. The result cache lives in cloud services and survives suspension. |
| B12 | B | Auto-resume starts the warehouse automatically when a query needs it. |
| B13 | B | OPERATE = start, suspend, resume, abort queries. MODIFY is needed to change the size. |
| B14 | B | Snowflake CLI replaces SnowSQL and deploys Streamlit apps, Native Apps and Snowpark code. |
| B15 | B | Query Profile shows the operator tree, partitions scanned vs total, spilling and more. |
| B16 | A, C | DataFrames are lazy and push their work down to a warehouse as SQL. Data stays in Snowflake. |
| B17 | B | Streamlit apps are schema-level objects hosted in Snowflake, and their queries use a warehouse. |
| B18 | B | Unstructured text and RAG = Cortex Search. Analyst is for structured data. |
| B19 | B | Cortex Analyst needs a semantic view (recommended) or a legacy semantic model YAML file to map business terms to tables. |
| B20 | B | Cortex AI functions are billed per token as AI Services credits. |
| B21 | A | SNOWFLAKE.CORTEX_USER is granted to PUBLIC by default. Users also need the USE AI FUNCTIONS account privilege, which PUBLIC also has by default. The other options are system account roles, not database roles. |
| B22 | A, B | ML Functions such as FORECAST and ANOMALY_DETECTION are called from SQL. PyTorch training and the Feature Store's Python API need Python. |

**Scoring:** 85% or more on Part B (19/22) means you're ready for Day 3. Under 70% (15/22) means you should reread the "Ten facts" in [notes.md](notes.md) and redo the lab's scale-up section before Day 3. If you miss any of Part A again, copy the correct fact into your error log in your own words.
