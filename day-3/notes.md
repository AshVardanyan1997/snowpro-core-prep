# Day 3 · Wed Nov 4 · Query Performance, Optimization and Caching

**Covers:** objectives 4.1, 4.2 and 4.3 (Domain 4, 21% of the exam) · **Time:** about 3 hours

**Written from the Snowflake documentation on Nov 4, 2026.** Each section ends with its sources. Where Snowflake changed something in 2026, the notes say so, because the exam can lag the docs.

## What this lesson covered

These are the official COF-C03 domain and objective names, so you can look each one up in the [Snowflake documentation](https://docs.snowflake.com) for a second round.

**Domain 4.0: Performance Optimization, Querying, and Transformation**
- 4.1 Evaluate query performance
  - Query performance tuning: Query Profile and Query Insights (bytes spilled to storage, inefficient pruning, exploding joins, queuing)
  - SNOWFLAKE.ACCOUNT_USAGE views: query attribution, query history
  - Workload management best practices: grouping similar workloads
- 4.2 Optimize query performance
  - Query Acceleration Service
  - Search Optimization Service
  - Clustering keys
  - Materialized views
- 4.3 Use Snowflake caching
  - Query result cache
  - Metadata cache
  - Warehouse cache

---

| Block | Time | What to do |
|---|---|---|
| Warm-up | 10 min | The drill list at the end of [day-2/practice-review.md](../day-2/practice-review.md) |
| Review set | 10 min | Answer [practice-questions.md](practice-questions.md) Part A (repeat misses from Days 1 and 2) |
| Notes | 60 min | Read this file |
| Lab | 50 min | Run [lab.sql](lab.sql) in a Snowsight worksheet |
| Practice | 35 min | Answer [practice-questions.md](practice-questions.md) Part B, then log every miss |

Free courses if you want to go further: *Level Up: Query History & Caching*, and the community articles "Understand Result Caching" and "Local and Remote Disk Spilling".

---

## 4.1 Evaluating query performance

### Query Profile

Open it in Snowsight: **Monitoring → Query History → a query → Query Profile**. It shows:
- The **operator tree**: one node per operator (TableScan, Filter, Join, Aggregate, Sort, …), with arrows showing how rows flow and each node's share of the query time.
- **Most expensive nodes**: the nodes that took at least 1% of the time, slowest first. Start there.
- **Statistics**, grouped by kind:

| Group | Statistics you'll be asked about |
|---|---|
| IO | **Partitions scanned**, **Partitions total**, **Percentage scanned from cache**, Bytes scanned |
| Spilling | **Bytes spilled to local storage**, **Bytes spilled to remote storage** |
| Network | Bytes sent over the network |

Snowsight's Query History page covers the **last 14 days**. You always see your own queries; seeing other users' queries on a warehouse needs **MONITOR** or **OPERATE** on that warehouse (or ACCOUNTADMIN).

### The four problems the guide names

| Problem | What you see in Query Profile | Fix |
|---|---|---|
| **Bytes spilled to storage** | The operation ran out of memory, so data spilled to **local disk** first, then to **remote** cloud storage, which is much slower | A **larger warehouse** (more memory and local disk), or process the data in **smaller batches** |
| **Inefficient pruning** | In TableScan, **Partitions scanned** is close to **Partitions total**. A Filter above the scan throws away most rows | Filter on columns the data is organized by; consider a **clustering key**; avoid wrapping filter columns in functions; for point lookups, **search optimization** |
| **Exploding join** | A Join node outputs **far more rows than it receives**, usually from a missing or non-unique join condition | Fix or add the join condition; filter subqueries before joining |
| **Queuing** | The query waited before it started. In QUERY_HISTORY, `QUEUED_OVERLOAD_TIME` is high | **Multi-cluster** warehouse (or more clusters), or spread queries across **more warehouses** |

Also in the docs' list: **UNION without ALL** (a UnionAll node with an Aggregate on top). If you don't need duplicates removed, write UNION ALL.

Exam traps:
- Remote spilling is worse than local spilling. Both point to **scale up**, never to more clusters (your Day 2 B2).
- `QUEUED_PROVISIONING_TIME` is time waiting for compute to start (after a resume or resize). `QUEUED_OVERLOAD_TIME` is waiting because the warehouse is busy, which is the one multi-cluster fixes.

### Query Insights

Snowflake now analyses each query and attaches **insights** to it. They appear in a **Query Insights** pane in Query Profile, and in the **ACCOUNT_USAGE.QUERY_INSIGHTS** view. Examples by topic:

| Topic | Insights |
|---|---|
| Table scan | No filter on table scan · Filter not selective · Filter not applicable · LIKE with leading wildcard (consider search optimization) · Filter used the clustering key / search optimization (positive) |
| Join | **Exploding join** · Join with no join condition (a cross join) · Inefficient join condition |
| Aggregation and union | Unnecessary DISTINCT or GROUP BY · Unnecessary UNION (use UNION ALL) |
| Warehouse | **Remote spilling** (use a larger warehouse or smaller batches) · **Queued too long** (larger warehouse or fewer concurrent queries) |

### ACCOUNT_USAGE views for performance (4.1.2)

These live in the shared **SNOWFLAKE** database. By default only ACCOUNTADMIN can read them; other roles need IMPORTED PRIVILEGES on SNOWFLAKE or a SNOWFLAKE database role such as GOVERNANCE_VIEWER or USAGE_VIEWER.

**ACCOUNT_USAGE.QUERY_HISTORY** (query history, 4.1.2.2)
- **365 days** of history, with **up to 45 minutes** of latency.
- Columns worth knowing: `PARTITIONS_SCANNED`, `PARTITIONS_TOTAL`, `BYTES_SPILLED_TO_LOCAL_STORAGE`, `BYTES_SPILLED_TO_REMOTE_STORAGE`, `QUEUED_OVERLOAD_TIME`, `QUEUED_PROVISIONING_TIME`, `PERCENTAGE_SCANNED_FROM_CACHE`, `QUERY_TAG`, `WAREHOUSE_SIZE`, `QUERY_HASH`.
- Compare with the **INFORMATION_SCHEMA.QUERY_HISTORY()** table function: last **7 days** only, no latency, returns at most 10,000 rows (100 by default). Variants: `QUERY_HISTORY_BY_SESSION`, `_BY_USER`, `_BY_WAREHOUSE`.

**ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY** (query attribution, 4.1.2.1)
- Estimates the **warehouse credits used by each query** over the last 365 days. Latency up to **8 hours**.
- Credits are split among the queries running in each minute, weighted by the resources they used.
- **Excluded:** warehouse **idle time**, queries of about **100 ms or less**, cloud services, storage, data transfer, serverless features and AI tokens.
- Key columns: `CREDITS_ATTRIBUTED_COMPUTE`, `CREDITS_USED_QUERY_ACCELERATION`, `QUERY_TAG`, `QUERY_PARAMETERIZED_HASH` (groups repeated runs of the same query).

Exam angle: "Which view shows the cost of each query?" → **QUERY_ATTRIBUTION_HISTORY**. "Does it include idle time?" → **No**. Use WAREHOUSE_METERING_HISTORY for the warehouse's total credits.

### Workload management (4.1.3)

- **Group similar workloads on the same warehouse.** The docs: optimizing a warehouse "is more straightforward when the warehouse runs similar workloads." A size that suits heavy ETL is wasted on tiny lookups, and the reverse.
- **Separate different workloads** (loading, BI, data science, each team) onto their own warehouses, so they don't queue each other and costs are easy to attribute.
- The docs' six warehouse strategies: **reduce queues · resolve memory spillage · increase warehouse size · try query acceleration · optimize the warehouse cache · limit concurrently running queries** (MAX_CONCURRENCY_LEVEL).
- Use **QUERY_TAG** (a session parameter) to label queries by application or team for later analysis.

Sources: [Monitor query activity with Query History](https://docs.snowflake.com/en/user-guide/ui-snowsight-activity) · [Query insights](https://docs.snowflake.com/en/user-guide/query-insights) · [Queries too large to fit in memory](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-memory) · [Reducing queues](https://docs.snowflake.com/en/en/user-guide/performance-query-warehouse-queue) · [Optimizing warehouses for performance](https://docs.snowflake.com/en/user-guide/performance-query-warehouse) · [QUERY_HISTORY view](https://docs.snowflake.com/en/sql-reference/account-usage/query_history) · [QUERY_HISTORY table functions](https://docs.snowflake.com/en/sql-reference/functions/query_history) · [QUERY_ATTRIBUTION_HISTORY view](https://docs.snowflake.com/en/sql-reference/account-usage/query_attribution_history)

---

## 4.2 Optimizing query performance

Four features, and the exam mostly asks **which one fits a scenario**:

| Feature | Best for | Compute | Edition |
|---|---|---|---|
| **Query Acceleration Service** | **Outlier** queries: large scans with selective filters or aggregation, or big INSERT/CTAS, that hog the warehouse | **Serverless**, leased per query | Enterprise |
| **Search Optimization Service** | **Selective point lookups** returning a few rows; substring and regex (LIKE, ILIKE, RLIKE); fields in VARIANT; geospatial; SEARCH | **Serverless** maintenance of a search access path | Enterprise |
| **Clustering keys** | **Very large (multi-TB)** tables queried with **range or equality filters on the same few columns**, where pruning has degraded | **Serverless** Automatic Clustering | Any |
| **Materialized views** | **Expensive, repeated** aggregations or semi-structured processing over **one table** whose results are small and which changes rarely | **Serverless** maintenance | Enterprise |

### Query Acceleration Service (4.2.1)

- Offloads **parts** of a query's work (mainly scanning and filtering) to **shared serverless compute**, so one big outlier query doesn't hold up the warehouse.
- **Eligible:** large scans with an aggregation or a selective filter, and large scans that insert or copy many rows.
- **Not eligible** if, for example: too few partitions to scan, the filter isn't selective enough, GROUP BY cardinality is too high, or it uses nondeterministic functions such as RANDOM or SEQ.
- **Scale factor** (`QUERY_ACCELERATION_MAX_SCALE_FACTOR`, default **8**): the cap on extra compute, as a multiple of the warehouse size. A Medium (4 credits/hour) with scale factor 5 can lease up to 20 extra credits/hour. **0** means no cap.
- Turn it on with `ENABLE_QUERY_ACCELERATION = TRUE`. Find candidates with `SYSTEM$ESTIMATE_QUERY_ACCELERATION('<query_id>')` or the **ACCOUNT_USAGE.QUERY_ACCELERATION_ELIGIBLE** view.
- **Billing:** serverless credits per second, **separate from warehouse credits**.
- **2026 change:** after the 2026_03 and 2026_06 behaviour changes, **new standard warehouses have QAS turned on by default** with scale factor 8 (Snowpark-optimized warehouses excluded). Altering an existing warehouse never turns it on. Older questions assume it's off until you enable it.

### Search Optimization Service (4.2.2)

- Builds and maintains a **search access path** (a kind of index) in the background. **No warehouse** is needed for maintenance, and queries only benefit once the build finishes (`search_optimization_progress` in SHOW TABLES).
- Speeds up: **equality and IN point lookups** that return a few rows, **substring and regex** searches, **semi-structured** fields (VARIANT, OBJECT, ARRAY), **geospatial** functions, and SEARCH / SEARCH_IP text searches. It can also help some joins.
- Enable: `ALTER TABLE t ADD SEARCH OPTIMIZATION;` (whole table) or `… ADD SEARCH OPTIMIZATION ON EQUALITY(col), SUBSTRING(col2);` (specific columns and methods).
- **Cost:** storage for the access path plus serverless compute for maintenance. Estimate first with `SYSTEM$ESTIMATE_SEARCH_OPTIMIZATION_COSTS`.

Search optimization vs clustering: clustering helps **range** filters on a few columns over huge tables; search optimization helps **needle-in-a-haystack** lookups on any column, including high-cardinality IDs, emails, and text.

### Clustering keys (4.2.3)

(You met clustering depth on Day 1; this is the "when and how" side.)
- Worth it for **very large tables, typically multiple TB**, that are **queried often and change rarely**, with selective filters or sorts on the same few columns, when queries have slowed or **clustering depth** is large.
- Choosing a key:
  - **At most 3 or 4 columns or expressions.**
  - Prefer columns in selective **filters**, then columns in **join** predicates.
  - Order columns from **lowest to highest cardinality**.
  - Cardinality in the middle: a Boolean prunes too little; a raw timestamp has too many values. Use an expression such as `TO_DATE(event_ts)`.
- Syntax: `CREATE TABLE … CLUSTER BY (…)`, `ALTER TABLE … CLUSTER BY (…)`, `ALTER TABLE … DROP CLUSTERING KEY`.
- **Automatic Clustering** is **serverless** (no warehouse to specify) and billed in credits; see AUTOMATIC_CLUSTERING_HISTORY. Pause and restart it with `ALTER TABLE … SUSPEND RECLUSTER` / `RESUME RECLUSTER`. It is suspended on **cloned** tables until you resume it.
- Reclustering also adds **storage**: replaced micro-partitions are kept for Time Travel and Fail-safe.

### Materialized views (4.2.4)

(Day 1 covered what they are; this is when to use them.)
- Use them when the result is **small compared with the base table**, the query is **expensive** (heavy aggregation or semi-structured processing), it runs **often**, and the base table **changes rarely**. They also help over **external tables**.
- Limits: **one table** (no joins, even self-joins); no window functions, UDFs, HAVING, ORDER BY, LIMIT, ROLLUP/CUBE; only certain aggregates; deterministic functions only; no DML on the view.
- A **serverless** background service keeps them up to date. If it's behind, Snowflake reads the changed part from the base table, so results are **always current**.
- **Costs:** storage plus maintenance credits. **Resource monitors can't control these credits.**
- The optimizer can **rewrite** a query against the base table to use a materialized view automatically.
- You can **cluster** a materialized view independently of its base table, and make it **secure**.

### Beyond the guide: Snowflake Optima

Newer than the study guide, so unlikely on the exam, but you'll see it in Query Insights. On **Gen 2** warehouses Snowflake automatically creates hidden search-optimization indexes for repeated point lookups (**Optima Indexing**, no extra cost), improves pruning (**Optima Metadata**) and learns better plans (**Optima Planning**). Since Sept 1, 2026 newly clustered tables use **Optima Clustering**.

Sources: [Query Acceleration Service](https://docs.snowflake.com/en/user-guide/query-acceleration-service) · [QAS on by default for all warehouse types (2026_06)](https://docs.snowflake.com/en/release-notes/bcr-bundles/2026_06/bcr-2373) · [Search optimization service](https://docs.snowflake.com/en/user-guide/search-optimization-service) · [Search optimization costs](https://docs.snowflake.com/en/user-guide/search-optimization/cost-estimation) · [Clustering keys](https://docs.snowflake.com/en/user-guide/tables-clustering-keys) · [Automatic Clustering](https://docs.snowflake.com/en/user-guide/tables-auto-reclustering) · [Materialized views](https://docs.snowflake.com/en/user-guide/views-materialized) · [Snowflake Optima](https://docs.snowflake.com/en/user-guide/snowflake-optima)

---

## 4.3 Caching

| Cache | Where it lives | What it holds | How long | Needs a running warehouse? |
|---|---|---|---|---|
| **Query result cache** (4.3.1) | Cloud services | The **full result** of each query | **24 hours**, reset each time it's reused, up to **31 days** after the first run | **No** |
| **Metadata cache** (4.3.2) | Cloud services | Micro-partition statistics: row counts, min and max per column, distinct values, null counts | Always, kept up to date by Snowflake | **No** |
| **Warehouse cache** (4.3.3) | The warehouse's local disk (SSD) | **Table data** that queries on that warehouse have read | Until the warehouse **suspends** | Yes: only queries on **that same** warehouse use it |

### Query result cache (4.3.1)

A query reuses a persisted result only if **all** of these hold:
- The **query text is exactly the same**. Even a different case or table alias stops reuse.
- No functions that can't be reused, such as `RANDOM`, `UUID_STRING` or `RANDSTR`.
- No **external functions**, and no **hybrid tables**.
- The **underlying data hasn't changed**, and the micro-partitions haven't been reclustered.
- The earlier result **still exists** (not purged).
- The **role has the privileges** for every table in the query. For SHOW commands, it must be the same role that created the result.
- No configuration option that affects the result has changed.

Other facts:
- Controlled by the `USE_CACHED_RESULT` parameter (default TRUE), settable at account, user or session level. Set it to FALSE when you benchmark.
- Query Profile shows a single **QUERY RESULT REUSE** node when the cache answered.
- `RESULT_SCAN(LAST_QUERY_ID())` lets you query the result of an earlier query as a table, which is handy for SHOW, DESCRIBE and CALL output.
- Reuse depends on the **role's privileges**, not on who ran the query first.

### Metadata cache (4.3.2)

Cloud services keeps statistics for every micro-partition. That is what makes **pruning** possible, and it answers some queries with **no warehouse at all**:
- `SELECT COUNT(*) FROM t` (no WHERE clause)
- `SELECT MIN(col), MAX(col) FROM t` on numbers and dates
- `SHOW`, `DESCRIBE` and similar commands

Query Profile shows **METADATA-BASED RESULT** for these (you saw this in the Day 1 lab).

### Warehouse cache (4.3.3)

- A running warehouse caches the table data it reads on local SSD, and **later queries on the same warehouse** read from it instead of remote storage. Check **Percentage scanned from cache** in Query Profile (or `PERCENTAGE_SCANNED_FROM_CACHE` in QUERY_HISTORY).
- It's **dropped when the warehouse suspends**, and shrinking a warehouse drops the part held by removed resources. Warehouses don't share caches.
- The docs' auto-suspend advice based on this:
  - **Tasks:** suspend immediately.
  - **DevOps, DataOps and data science** (ad-hoc, unique queries): about **5 minutes**.
  - **BI and SELECT query warehouses:** **at least 10 minutes**, to keep the cache warm for users.

Exam traps:
- "Which cache survives a warehouse suspend?" → the **result cache** (and metadata). The warehouse cache doesn't. (Your Day 2 B11.)
- "The same query ran twice, but the second run didn't use the result cache." Look for: changed data, different text, a nondeterministic function, USE_CACHED_RESULT = FALSE, a role without privileges.
- Result cache answers need no warehouse, so they cost no warehouse credits.

Sources: [Using persisted query results](https://docs.snowflake.com/en/user-guide/querying-persisted-results) · [Optimizing the warehouse cache](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-cache) · [Snowflake key concepts (cloud services)](https://docs.snowflake.com/en/user-guide/intro-key-concepts) · [Understanding compute cost](https://docs.snowflake.com/en/user-guide/cost-understanding-compute) · [RESULT_SCAN](https://docs.snowflake.com/en/sql-reference/functions/result_scan)

---

## Ten facts to know cold by tonight
1. **Spilling** (local, then worse, remote) → **larger warehouse** or smaller batches. **Queuing** → multi-cluster or more warehouses.
2. **Inefficient pruning** = partitions scanned ≈ partitions total → clustering key, better filters, or search optimization.
3. **Exploding join** = a join outputs far more rows than it takes in → fix the join condition.
4. **ACCOUNT_USAGE.QUERY_HISTORY:** 365 days, up to 45 min latency. **INFORMATION_SCHEMA.QUERY_HISTORY():** 7 days, real time. Snowsight Query History: 14 days.
5. **QUERY_ATTRIBUTION_HISTORY** = credits per query, **excluding idle time** and queries of ~100 ms or less.
6. **QAS** = serverless help for **outlier large scans**; scale factor caps it (default 8). **Search optimization** = **point lookups**, substrings, VARIANT. Both need **Enterprise**.
7. **Clustering keys:** multi-TB tables, ≤ 3–4 columns, lowest cardinality first, `TO_DATE(ts)` not raw timestamps; Automatic Clustering is serverless and costs credits.
8. **Materialized views:** one table, expensive repeated query, small result, rarely changing base table; serverless maintenance not controlled by resource monitors; always current.
9. **Result cache:** cloud services, **24 h** (reset on reuse, max **31 days**), exact same text, unchanged data, same privileges, **no warehouse needed**. Off with `USE_CACHED_RESULT = FALSE`.
10. **Warehouse cache** is **lost on suspend**; BI warehouses keep auto-suspend **≥ 10 minutes**. **Metadata** answers COUNT(*), MIN, MAX without a warehouse.
