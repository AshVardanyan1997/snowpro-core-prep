# Mock 1 · Answer key

**Don't open this until you've pushed your answers to [questions.md](questions.md).**

Each row gives the objective from the tracker and the lesson that covers it, so every miss maps straight to something to reread.

## Scoring

| Domain | Questions | Your score | Target (80%) |
|---|---|---|---|
| 1 · Features and Architecture | 1–31 | __ / 31 | 25 |
| 2 · Account Management and Governance | 32–51 | __ / 20 | 16 |
| 3 · Loading, Unloading, Connectivity | 52–69 | __ / 18 | 15 |
| 4 · Performance, Querying, Transformation | 70–90 | __ / 21 | 17 |
| 5 · Data Collaboration | 91–100 | __ / 10 | 8 |
| **Total** | | **__ / 100** | **80** |

The real exam is scored from 0 to 1000 and needs **750** to pass. Snowflake doesn't publish how that maps to raw scores, so aim for **80% or higher** on mocks to have a safety margin. A multi-select question counts as right only if every choice is right.

## Domain 1 · Features and Architecture

| Q | Answer | Why | Objective | Lesson |
|---|---|---|---|---|
| 1 | B | Cloud services handles authentication, metadata, optimization and access control. | 1.1 | Day 1 |
| 2 | C, D | Central storage that every warehouse can read (shared-disk), and independent compute clusters (shared-nothing). | 1.1 | Day 1 |
| 3 | D | 50–500 MB of uncompressed data. 100–250 MB compressed is the recommended size for **files to load**, a different thing. | 1.5 | Day 1 |
| 4 | C, D | Immutable and columnar. Snowflake creates them automatically as data arrives; users never define them. | 1.5 | Day 1 |
| 5 | B | Multi-cluster warehouses need Enterprise. | 1.1 | Days 1, 2 |
| 6 | A | PrivateLink and HIPAA/PCI support start at Business Critical. | 1.1 | Day 1 |
| 7 | A, B | Stages and file formats are schema-level. Warehouses, roles and shares are account-level. | 1.3 | Day 1 |
| 8 | C | The most specific level wins: session over user over account. | 1.3 | Day 1 |
| 9 | C | An average depth near 1 means little overlap between micro-partitions, so pruning works well. | 1.5 | Days 1, 3 |
| 10 | D | Transient tables persist until dropped, but have no Fail-safe. Temporary tables vanish at the end of the session. | 1.5 | Day 1 |
| 11 | C | Temporary tables live only in their session. No Fail-safe, any edition. | 1.5 | Day 1 |
| 12 | B | Secure views hide the definition and are the type used for sharing. | 1.5 | Day 1 |
| 13 | A | One table only, no joins. Enterprise. Maintained automatically and serverlessly. | 1.5 | Days 1, 3 |
| 14 | B | Snowflake CLI (`snow`) deploys Streamlit, Native Apps and Snowpark. SnowSQL is the legacy client. | 1.2 | Day 2 |
| 15 | B, C | PUT runs from a client such as Snowflake CLI, SnowSQL or a driver, not from a Snowsight worksheet. | 1.2 | Day 2 |
| 16 | A | Spilling means the warehouse ran out of memory: **spill → size**. More clusters don't help a single query. | 1.4 | Days 2, 3 |
| 17 | D | Queuing from many concurrent users: **queue → clusters**. | 1.4 | Day 2 |
| 18 | D | Economy saves credits and accepts some queuing. Standard starts clusters eagerly. | 1.4 | Day 2 |
| 19 | B | 8 credits × 0.5 hours = 4. | 1.4 | Days 2, 5 |
| 20 | A | Suspending drops the local disk cache, so repeated BI queries lose their warm cache. The result cache is in cloud services and isn't affected. | 1.4 | Days 2, 3 |
| 21 | C | Snowpark-optimized warehouses have 16x the memory per node by default. | 1.4 | Day 2 |
| 22 | D | Running queries finish on the old size. New and queued queries use the new size. | 1.4 | Day 2 |
| 23 | A | MIN = MAX (and above 1) is Maximized mode. Economy and Standard are scaling policies, not modes. | 1.4 | Day 2 |
| 24 | D | Gen 2 is faster hardware and software, with named gains for DML and scans. 16x memory is Snowpark-optimized. | 1.4 | Day 2 |
| 25 | A | DataFrames are lazy. An action triggers the SQL, which runs on a warehouse (pushdown). | 1.6 | Day 2 |
| 26 | D | Streamlit in Snowflake runs with owner's rights by default. | 1.6 | Day 2 |
| 27 | D | Cortex Search: hybrid search over unstructured text, the retrieval half of RAG. | 1.6 | Day 2 |
| 28 | D | Cortex Analyst turns natural language into SQL, driven by a semantic view. | 1.6 | Day 2 |
| 29 | B | Billed per token, as AI Services credits. | 1.6 | Day 2 |
| 30 | A | AI_FILTER returns TRUE or FALSE for a natural-language condition. | 1.6 | Day 2 |
| 31 | A | FORECAST is an ML function you call from SQL, no ML expertise needed. | 1.6 | Day 2 |

## Domain 2 · Account Management and Data Governance

| Q | Answer | Why | Objective | Lesson |
|---|---|---|---|---|
| 32 | B | USERADMIN has CREATE USER and CREATE ROLE. | 2.1 | Day 4 |
| 33 | D | MANAGE GRANTS, held by SECURITYADMIN. | 2.1 | Day 4 |
| 34 | D | Grant custom roles to SYSADMIN, so the hierarchy reaches the objects they own. | 2.1 | Day 4 |
| 35 | D | Secondary roles authorize actions, but CREATE uses the primary role, which becomes the owner. | 2.1 | Day 4 |
| 36 | C | The most specific network policy wins and replaces the account's. JO's address isn't in the user policy. | 2.1 | Day 4 |
| 37 | C | Service users can't use passwords. Key-pair (or OAuth or workload identity federation) is the method. | 2.1 | Day 4 |
| 38 | D | `orgname-account_name`. The account locator is the older format. | 2.1 | Day 4 |
| 39 | C | Row access first, masking second. | 2.2 | Day 5 |
| 40 | D, E | Tags are inherited down the hierarchy, and tag-based masking attaches a policy to a tag. Values are strings, tags are schema-level, and the limit is 50 per object. | 2.2 | Day 5 |
| 41 | B | An aggregation policy makes non-aggregated queries fail. | 2.2 | Day 5 |
| 42 | C | The CIS Benchmarks package is opt-in. Security Essentials is the always-on package. | 2.2 | Day 5 |
| 43 | D | Tri-Secret Secure, customer key + Snowflake key, Business Critical. | 2.2 | Day 5 |
| 44 | B | Periodic rekeying (Enterprise) re-encrypts data whose key was retired over a year ago. 30-day rotation is automatic on every edition. | 2.2 | Day 5 |
| 45 | A | Alerts, like tasks, start suspended. | 2.2 | Day 5 |
| 46 | D | Failover groups (Business Critical) let a secondary become primary. Replication groups only give read-only copies. | 2.2 | Day 5 |
| 47 | B | ACCESS_HISTORY records columns read, and base_objects_accessed sees through views. | 2.2 | Day 5 |
| 48 | C | SUSPEND_IMMEDIATE cancels running queries. SUSPEND lets them finish. | 2.3 | Day 5 |
| 49 | D | Budgets cover serverless features and notify. Resource monitors only see warehouses. | 2.3 | Day 5 |
| 50 | A, C | ACCOUNT_USAGE includes dropped objects and keeps about a year, with 45 min to 3 h latency, account-wide. | 2.3 | Day 5 |
| 51 | C | Only ACCOUNTADMIN creates resource monitors. | 2.3 | Day 5 |

## Domain 3 · Data Loading, Unloading, and Connectivity

| Q | Answer | Why | Objective | Lesson |
|---|---|---|---|---|
| 52 | C | Unloading supports CSV, JSON and Parquet only. XML, Avro and ORC are load-only. | 3.1 | Day 5 |
| 53 | B | Table stages can't be dropped or altered, belong to one table, and don't support COPY transformations. | 3.1 | Day 5 |
| 54 | D | LOAD_UNCERTAIN_FILES. FORCE reloads everything, including files known to be loaded. | 3.1 | Day 5 |
| 55 | B | SKIP_FILE skips the whole file with errors and loads the rest. | 3.1 | Day 5 |
| 56 | B | VALIDATION_MODE only checks. It doesn't work with transformations, and Snowpipe doesn't support it. | 3.1 | Day 5 |
| 57 | D | Snappy for Parquet, gzip for CSV and JSON. | 3.1 | Day 5 |
| 58 | D | STRIP_OUTER_ARRAY removes the outer brackets so each element becomes a row. | 3.1 | Day 5 |
| 59 | B | PURGE removes loaded files from the stage. TRUNCATE clears load metadata. | 3.1 | Day 5 |
| 60 | D | Serverless, a fixed number of credits per GB loaded. No warehouse. | 3.2 | Day 6 |
| 61 | B, C | Auto-ingest through cloud event notifications, or the REST API (insertFiles). | 3.2 | Day 6 |
| 62 | D | Only a committed DML statement that reads the stream advances the offset. SELECT never does. | 3.2 | Day 6 |
| 63 | C | Up to 14 days by default (MAX_DATA_EXTENSION_TIME_IN_DAYS). | 3.2 | Day 6 |
| 64 | A, B | No warehouse means serverless, which needs EXECUTE MANAGED TASK. | 3.2 | Day 6 |
| 65 | D | Procedural logic, MERGE and CRON point to streams and tasks. Dynamic tables are declarative SELECTs. | 3.2 | Day 6 |
| 66 | C | Rows, not files, within seconds: Snowpipe Streaming. | 3.2 | Day 6 |
| 67 | D | Storage integrations hold the cloud identity for external stages. | 3.3 | Days 5, 6 |
| 68 | B, E | JDBC and Go are drivers. The Kafka connector is a connector. Snowpipe Streaming is an ingestion service. | 3.3 | Day 6 |
| 69 | B | `ALTER GIT REPOSITORY … FETCH`. The repository object is read-only, so there's no push. | 3.3 | Day 6 |

## Domain 4 · Performance, Querying, and Transformation

| Q | Answer | Why | Objective | Lesson |
|---|---|---|---|---|
| 70 | A | Scanned ≈ total means the filter didn't prune. Fix with clustering, better filters or search optimization. | 4.1 | Day 3 |
| 71 | B | Far more rows out than in is an exploding join. | 4.1 | Day 3 |
| 72 | D | ACCOUNT_USAGE.QUERY_HISTORY keeps 365 days. The INFORMATION_SCHEMA function keeps 7 days, and Snowsight shows 14. | 4.1 | Day 3 |
| 73 | C | QUERY_ATTRIBUTION_HISTORY: credits per query, excluding idle time. | 4.1 | Day 3 |
| 74 | C | Query Acceleration offloads parts of outlier large-scan queries to serverless compute. | 4.2 | Day 3 |
| 75 | A | Search Optimization is for selective point lookups. | 4.2 | Day 3 |
| 76 | A | Reduce cardinality with `TO_DATE(event_ts)`. Clustering on a raw high-cardinality timestamp is expensive and ineffective. | 4.2 | Day 3 |
| 77 | A, D | Changed data or non-deterministic functions prevent reuse. The result cache lives in cloud services, so the warehouse doesn't matter. | 4.3 | Day 3 |
| 78 | B | 24 hours, reset each time it's reused, up to 31 days. | 4.3 | Day 3 |
| 79 | B | COUNT, MIN and MAX can be answered from micro-partition metadata, with no warehouse. | 4.3 | Day 3 |
| 80 | C | The warehouse cache is dropped on suspend. | 4.3 | Day 3 |
| 81 | A | Key names are case-sensitive, so `customer` doesn't match `Customer`. A missing path returns NULL, not an error. | 4.4 | Day 4 |
| 82 | C | OUTER => TRUE keeps rows whose array is empty, with NULLs. | 4.4 | Day 4 |
| 83 | D | VALUE holds the element. INDEX is its position and KEY is the key for objects. | 4.4 | Day 4 |
| 84 | B | DENSE_RANK: 1, 1, 2. RANK would give 1, 1, 3. | 4.4 | Day 4 |
| 85 | A | QUALIFY filters on window functions, the way HAVING filters on aggregates. | 4.4 | Day 4 |
| 86 | A | APPROX_COUNT_DISTINCT uses HyperLogLog. | 4.4 | Day 4 |
| 87 | B | ROLLUP (region, city) gives per-region subtotals and a grand total. CUBE would add per-city totals across regions. | 4.4 | Day 4 |
| 88 | B | Scoped URL: only the generating user, 24 hours. | 4.4 | Day 4 |
| 89 | D | Pre-signed URL: anyone with the link, until it expires. The stage needs SNOWFLAKE_SSE. | 4.4 | Day 4 |
| 90 | A, C | Maintenance is serverless and not controlled by resource monitors. Results are always current. MVs suit base tables that change rarely. | 4.2 | Day 3 |

## Domain 5 · Data Collaboration

| Q | Answer | Why | Objective | Lesson |
|---|---|---|---|---|
| 91 | B | 1 day by default on every edition. | 5.1 | Day 6 |
| 92 | A | With retention 0 there's no Time Travel, so UNDROP fails. Permanent tables still get 7 days of Fail-safe, recoverable only through Support. | 5.1 | Day 6 |
| 93 | A | 7 days, not configurable, permanent tables only, Snowflake Support only. | 5.1 | Day 6 |
| 94 | C | Zero-copy: only the changed micro-partitions in the clone are new storage. | 5.1 | Day 6 |
| 95 | D | CLONE accepts AT and BEFORE. There's no `COPY` clause on CREATE TABLE. | 5.1 | Day 6 |
| 96 | A | Provider pays storage, consumer pays compute. | 5.2 | Day 6 |
| 97 | B | Reader accounts are owned and paid for by the provider, and only consume that provider's shares. | 5.2 | Day 6 |
| 98 | B | Direct shares are same-region. Use replication or a listing with auto-fulfillment. | 5.2 | Day 6 |
| 99 | C | Public listings appear on the Snowflake Marketplace. Private listings go to named accounts. | 5.3 | Day 6 |
| 100 | A | Native Apps are installed and run in the consumer's account. | 5.3 | Day 6 |
