# Day 3 Practice Questions

- **Part A: Repeat-miss review** (8 questions). These retest the topics you've missed more than once: transient vs temporary tables, editions, account identifiers, and scaling up vs out. The wording is new on purpose. Answer them **before** the notes, in about 9 minutes.
- **Part B: Day 3 topics** (24 questions on objectives 4.1, 4.2 and 4.3). Answer these after the notes and the lab, at exam pace (about 28 minutes).

Mark your answers the same way as before. Answers and explanations are at the bottom. Cover them while you work, and add every miss to your error log.

---

## Part A · Repeat-miss review

**A1.** A user creates a table with `CREATE TRANSIENT TABLE t (...)`, logs out, and logs back in the next day. What happened to `t`?
A. It was dropped when the session ended  B. It still exists  C. It moved to Fail-safe  D. It became a temporary table

**A2.** Which table types have **no** Fail-safe? (Choose two.)
A. Permanent  B. Transient  C. Temporary  D. Permanent tables in an Enterprise account

**A3.** Which feature is available on **Standard** edition?
A. Masking policies  B. Multi-cluster warehouses  C. Snowpipe  D. 90-day Time Travel

**A4.** An organization is called `ACME` and the account is called `SALES_EU`. What is the account identifier in the preferred format?
A. `SALES_EU.ACME`  B. `ACME-SALES_EU`  C. `ACME.SALES_EU.aws`  D. `xy12345.eu-central-1`

**A5.** A single nightly MERGE runs on a Large warehouse with MAX_CLUSTER_COUNT = 1 and spills to remote storage. No other queries run at that time. What helps?
A. Set MAX_CLUSTER_COUNT = 4  B. Resize the warehouse to X-Large  C. Switch to the Economy scaling policy  D. Increase AUTO_SUSPEND

**A6.** A warehouse is set with MIN_CLUSTER_COUNT = 1 and MAX_CLUSTER_COUNT = 5. Which statements are true? (Choose two.)
A. It is in maximized mode  B. It is in auto-scale mode  C. The scaling policy decides when extra clusters start  D. All five clusters start when the warehouse resumes

**A7.** While a long query is running, an admin resizes the warehouse from Medium to 2X-Large. What happens?
A. The running query is restarted on 2X-Large  B. The running query continues on its current resources; new queries use 2X-Large  C. The resize waits until the warehouse is idle  D. The running query fails

**A8.** A BI warehouse suspends after 60 seconds, and dashboards are slow on the first refresh after each pause. Which cache are users losing?
A. The result cache  B. The metadata cache  C. The warehouse (local disk) cache  D. The Fail-safe cache

---

## Part B · Day 3 topics (4.1, 4.2, 4.3)

**B1.** In Query Profile, the TableScan node shows Partitions scanned = 9,850 and Partitions total = 10,000, and the query filters on one column. What problem does this indicate?
A. Exploding join  B. Inefficient pruning  C. Spilling  D. Queuing

**B2.** A Join node receives 10,000 rows from each input and outputs 40 million rows. What is the most likely cause and fix?
A. Spilling; use a larger warehouse  B. A missing or non-unique join condition; fix the join condition  C. Queuing; add clusters  D. Poor pruning; add a clustering key

**B3.** Which is worse for performance?
A. Bytes spilled to local storage  B. Bytes spilled to remote storage  C. They are equal  D. Neither affects performance

**B4.** Which statistics help you spot inefficient pruning? (Choose two.)
A. Partitions scanned  B. Partitions total  C. Bytes sent over the network  D. Bytes written to result

**B5.** In ACCOUNT_USAGE.QUERY_HISTORY, which column shows time a query waited because the warehouse was busy with other queries?
A. QUEUED_PROVISIONING_TIME  B. QUEUED_OVERLOAD_TIME  C. COMPILATION_TIME  D. EXECUTION_TIME

**B6.** How long does SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY keep data, and how current is it?
A. 7 days, real time  B. 14 days, real time  C. 365 days, up to 45 minutes behind  D. 90 days, up to 3 hours behind

**B7.** You need the last hour's queries for your current session, with no delay. What should you use?
A. SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY  B. INFORMATION_SCHEMA.QUERY_HISTORY_BY_SESSION()  C. QUERY_ATTRIBUTION_HISTORY  D. WAREHOUSE_METERING_HISTORY

**B8.** Which statements about QUERY_ATTRIBUTION_HISTORY are true? (Choose two.)
A. It shows the warehouse credits attributed to each query  B. It includes warehouse idle time  C. It excludes very short queries (about 100 ms or less)  D. It is real time

**B9.** A warehouse runs both large nightly ETL transformations and small, fast dashboard lookups, and tuning it for one hurts the other. What does Snowflake recommend?
A. Run everything on one 6XL warehouse  B. Group similar workloads on their own warehouses  C. Turn off auto-suspend  D. Use Economy scaling

**B10.** Which kind of query is the Query Acceleration Service designed to help?
A. A query that returns one row by primary key  B. An outlier query that scans a large table with a selective filter  C. A query answered from the result cache  D. A query with a nondeterministic function such as RANDOM

**B11.** What does QUERY_ACCELERATION_MAX_SCALE_FACTOR control?
A. The number of clusters  B. The upper limit on extra serverless compute, as a multiple of the warehouse size  C. The warehouse size  D. How long results are cached

**B12.** Which function tells you whether a past query would have benefited from query acceleration?
A. SYSTEM$CLUSTERING_INFORMATION  B. SYSTEM$ESTIMATE_QUERY_ACCELERATION  C. SYSTEM$ESTIMATE_SEARCH_OPTIMIZATION_COSTS  D. RESULT_SCAN

**B13.** Users often run `SELECT * FROM events WHERE user_email = 'x@y.com'` on a 5 TB table. Each query returns a few rows but scans most partitions. What's the best fit?
A. A clustering key on user_email  B. Search optimization on user_email  C. A materialized view  D. A bigger warehouse

**B14.** Which query patterns can the Search Optimization Service speed up? (Choose two.)
A. `WHERE description LIKE '%refund%'`  B. A full-table `SELECT SUM(amount)` with no filter  C. Equality lookups on a field inside a VARIANT column  D. `ORDER BY` on every column

**B15.** Which statements about clustering keys are true? (Choose two.)
A. They suit very large tables queried with filters on the same few columns  B. They should include as many columns as possible  C. Columns should be ordered from lowest to highest cardinality  D. They are best on small tables that change constantly

**B16.** Which is a good clustering key for a 30 TB table filtered by day on a TIMESTAMP column `event_ts`?
A. `event_ts`  B. `TO_DATE(event_ts)`  C. A Boolean column `is_test`  D. A UUID column

**B17.** What runs Automatic Clustering?
A. The table owner's default warehouse  B. A serverless service billed in credits  C. The cloud services layer at no cost  D. A task you schedule

**B18.** Which are valid reasons to create a materialized view? (Choose two.)
A. An expensive aggregation on one table is queried often and the table changes rarely  B. You need to join five tables  C. You want to speed up queries on an external table  D. You need a window function over a stream

**B19.** Which statements about materialized views are true? (Choose two.)
A. Queries always return current data, even if maintenance is behind  B. Resource monitors cap their maintenance credits  C. The optimizer can use one automatically for a query against the base table  D. They can be updated with INSERT

**B20.** How long is a query result kept in the result cache?
A. Until the warehouse suspends  B. 24 hours, reset each time it's reused, up to 31 days from the first run  C. 7 days  D. Forever, until the table changes

**B21.** The same SELECT ran twice in a row, but the second run did not use the result cache. Which could explain it? (Choose two.)
A. The query includes RANDOM()  B. Rows were inserted into the table between the runs  C. The warehouse was suspended between the runs  D. The second run used the same role

**B22.** Which queries can run with no running warehouse? (Choose two.)
A. `SELECT COUNT(*) FROM orders` (no filter)  B. A repeated identical query whose data hasn't changed  C. `SELECT * FROM orders WHERE status = 'X'` run for the first time  D. A MERGE into orders

**B23.** You want to benchmark a query's real execution time, ignoring the result cache. What do you do?
A. `ALTER SESSION SET USE_CACHED_RESULT = FALSE`  B. Suspend the warehouse  C. Drop the table  D. Set AUTO_SUSPEND = 0

**B24.** Where does the warehouse cache live, and who can use it?
A. In cloud services; every warehouse  B. On the warehouse's local disk; only queries on that same warehouse  C. In remote storage; every account  D. In the result cache; the same user only

---

## Answers

### Part A
| Q | Answer | Why |
|---|---|---|
| A1 | B | Transient tables last **until dropped**. Only temporary tables disappear when the session ends. |
| A2 | B, C | Transient and temporary tables have no Fail-safe. Permanent tables get 7 days on every edition. |
| A3 | C | Snowpipe is on Standard. Masking, multi-cluster and Time Travel beyond 1 day need Enterprise. |
| A4 | B | `orgname-accountname`, joined with a hyphen. D is an account locator (legacy, region-bound). |
| A5 | B | One query, spilling = memory. Scale **up**. More clusters can't help a single query. |
| A6 | B, C | MIN < MAX = auto-scale, and the scaling policy (Standard or Economy) decides when clusters start. Maximized is MIN = MAX. |
| A7 | B | A resize never touches running queries. Queued and new queries get the new size. |
| A8 | C | The local disk cache is dropped on suspend. The result cache lives in cloud services and survives. |

### Part B
| Q | Answer | Why |
|---|---|---|
| B1 | B | Partitions scanned ≈ partitions total means the filter isn't pruning. |
| B2 | B | A join that outputs far more rows than it takes in is an exploding join, usually a missing or non-unique join condition. |
| B3 | B | Remote spilling is slower than local spilling. Both suggest a larger warehouse or smaller batches. |
| B4 | A, B | Compare partitions scanned with partitions total in TableScan. |
| B5 | B | QUEUED_OVERLOAD_TIME = waiting because the warehouse is busy. QUEUED_PROVISIONING_TIME = waiting for compute to start after a resume or resize. |
| B6 | C | ACCOUNT_USAGE: 365 days, up to 45 minutes of latency. |
| B7 | B | INFORMATION_SCHEMA table functions are real time (last 7 days). ACCOUNT_USAGE can be 45 minutes behind. |
| B8 | A, C | It estimates per-query warehouse credits, excludes idle time and queries of about 100 ms or less, and can be up to 8 hours behind. |
| B9 | B | The docs: tuning is easier when a warehouse runs similar workloads. Split ETL and BI. |
| B10 | B | QAS offloads parts of large scans with selective filters or aggregations, for outlier queries. Nondeterministic functions make a query ineligible. |
| B11 | B | The scale factor caps how much serverless compute QAS can lease, as a multiple of the warehouse size (default 8, 0 = no cap). |
| B12 | B | SYSTEM$ESTIMATE_QUERY_ACCELERATION takes a query ID and reports eligibility and estimated times. |
| B13 | B | Selective point lookups on a high-cardinality column are what search optimization is for. A clustering key on an email column would have far too many distinct values. |
| B14 | A, C | Substring searches and lookups in semi-structured data are supported. Full scans with no filter can't be helped by an index. |
| B15 | A, C | At most 3 or 4 columns, lowest cardinality first, on very large tables that are queried often and change rarely. |
| B16 | B | `TO_DATE(event_ts)` keeps order with far fewer distinct values. A raw timestamp or UUID has too many; a Boolean has too few. |
| B17 | B | Automatic Clustering is serverless and billed in credits. You don't pick a warehouse. |
| B18 | A, C | Materialized views suit expensive, repeated, single-table queries on rarely changing data, and they help over external tables. No joins and no window functions. |
| B19 | A, C | Snowflake reads changed data from the base table if maintenance lags, and the optimizer can rewrite queries to use the view. Resource monitors can't control the maintenance credits, and DML isn't allowed. |
| B20 | B | 24 hours, renewed on each reuse, purged at most 31 days after the first run. |
| B21 | A, B | Non-reusable functions and changed data both prevent reuse. Suspending the warehouse doesn't affect the result cache. |
| B22 | A, B | COUNT(*) with no filter comes from metadata, and an unchanged repeated query comes from the result cache. A first-time filtered SELECT and a MERGE need a warehouse. |
| B23 | A | USE_CACHED_RESULT = FALSE turns off result reuse for the session. |
| B24 | B | The warehouse cache is local SSD on that warehouse, used only by queries running there, and lost on suspend. |

**Scoring:** 85% or more on Part B (21/24) means you're ready for Day 4. Under 70% (17/24) means you should reread the "Ten facts" in [notes.md](notes.md) and redo lab sections 1 and 2 before Day 4. For Part A, any miss here is a third miss on the same topic: write the fact on a sticky note, not just the error log.
