# SnowPro Core (COF-C03): 7-Day Plan

**Exam:** Monday, Oct 19, 2026 · **Study window:** Mon Oct 12 to Sun Oct 18 · **Budget:** about 3 hours a day (4 on the weekend), roughly 23 hours in total
**Checked against:** the official COF-C03 Exam Study Guide (last updated July 8, 2026)

## 1. The exam

| | |
|---|---|
| Questions | 100, single answer and multiple select |
| Time | 115 minutes (about 69 seconds per question) |
| Passing score | 750 on a 0 to 1000 scale |
| Delivery | Pearson VUE, online proctored or test centre |

The official guide doesn't give the question count, time or passing score. Those figures come from third-party sites, so check them on the registration page when you book.

| # | Domain (official) | Weight | Hours | Days |
|---|---|---|---|---|
| 1 | Snowflake AI Data Cloud Features and Architecture | **31%** | 6.5 | 1, 2 |
| 4 | Performance Optimization, Querying, and Transformation | **21%** | 5 | 3, 4 |
| 2 | Account Management and Data Governance | **20%** | 4.5 | 4, 5 |
| 3 | Data Loading, Unloading, and Connectivity | **18%** | 4 | 5, 6 |
| 5 | Data Collaboration | **10%** | 2 | 6 |

**The guide marks two topics as not tested:** the default warehouse for Notebooks, and Openflow. They won't be tested until they are generally available, so skip both.

## 2. Daily routine

Each day, **read the topic, then do it in a trial account, then answer 20 to 40 practice questions on it, then log every miss** in an error log (the topic, why you got it wrong, and the correct fact). The objective numbers below (such as 1.1) match the guide. Section 3 explains what each objective actually means.

### Day 1 · Mon Oct 12 · Domain 1, part 1 (3 h)
- Set up a 30-day trial account (choose Enterprise edition) and a Snowflake University login.
- **Diagnostic:** answer 30 mixed questions cold, including the 5 sample questions at the end of the guide.
- Cover 1.1 architecture and editions, 1.3 object hierarchy and parameters, and 1.5 storage, table types and view types.
- Free courses: *Level Up: Snowflake's Key Concepts*, *Level Up: Container Hierarchy*, *Level Up: Accounts & Assurances*.

### Day 2 · Tue Oct 13 · Domain 1, part 2 (3 h)
- Cover 1.2 interfaces, 1.4 virtual warehouses, and 1.6 AI/ML and app development features.
- Lab: create an XS warehouse and a multi-cluster warehouse, try both scaling policies, and run AI_COMPLETE or AI_SENTIMENT on a table.
- Free courses: *Badge 1: Data Warehousing Workshop* (start it), and the *Snowflake x GenAI: LLM Functions* quickstart.

### Day 3 · Wed Oct 14 · Domain 4, part 1 (3 h)
- Cover 4.1 evaluating performance, 4.2 optimizing it, and 4.3 caching.
- Lab: run the same query twice and compare the two Query Profiles. Then set USE_CACHED_RESULT = FALSE and run it again. Run a large sort on an XS warehouse to make it spill.
- Free courses: *Level Up: Query History & Caching*, and the articles "Understand Result Caching" and "Local and Remote Disk Spilling".

### Day 4 · Thu Oct 15 · Domain 4, part 2, and the security model from Domain 2 (3 h)
- Cover 4.4 transformations (semi-structured data, unstructured data, aggregate functions, window functions) and 2.1 the security model.
- Lab: load a JSON file into a VARIANT column and LATERAL FLATTEN it. Build a role hierarchy with USERADMIN and SYSADMIN, and test USE SECONDARY ROLES ALL.

### Day 5 · Fri Oct 16 · Rest of Domain 2, then Domain 3 loading (3 h)
- Cover 2.2 governance, 2.3 monitoring and cost, and 3.1 loading and unloading.
- Lab: create a masking policy and a row access policy, a resource monitor, and a named stage. Run COPY INTO with VALIDATION_MODE, then with ON_ERROR, then with PURGE.
- Free courses: *Level Up: Resource Monitoring*, *Level Up: Data Loading*, and Getting Started modules 4, 5 and 9.

### Day 6 · Sat Oct 17 · Rest of Domain 3, Domain 5, then Mock 1 (4 h)
- Cover 3.2 automated ingestion, 3.3 connectors and integrations, and all of Domain 5 (5.1 to 5.3).
- Lab: build a stream and a task that consume it, then a dynamic table that does the same job. Clone a schema that contains a stream and check that the cloned stream is empty. Use Time Travel and UNDROP. Get a free Marketplace listing.
- **Mock 1:** 100 questions in 115 minutes, timed. Score it and log every miss.

### Day 7 · Sun Oct 18 · Gaps, then Mock 2 (4 h)
- Spend 90 minutes on your three weakest objectives from the error log.
- **Mock 2:** the official Snowflake practice exam, timed. **Target 80% or higher.** If you score under 75%, spend Sunday evening and Monday morning on the weakest domain only.
- Read sections 3 and 4 once, then stop by 9 pm.

### Exam day · Mon Oct 19
- Spend 20 minutes on the cheat sheet and your error log. Learn nothing new.
- Flag any question that takes longer than 90 seconds and come back to it. For multiple-select questions, pick exactly the number of answers they ask for.

## 3. Objective checklist: what the guide's bullets actually mean

The guide lists topic names only. Each line below says what you need to be able to answer about that topic.

### Domain 1 · Features and Architecture (31%)
- **1.1 Architecture.** Know the three layers and what each one does:
  - **Storage:** compressed, columnar micro-partitions.
  - **Compute:** virtual warehouses, which are independent and don't share CPU or cache.
  - **Cloud services:** authentication, metadata, query optimization and access control. It is billed only for the part of daily usage above 10% of warehouse credits.
  - **Editions:** Standard, Enterprise (multi-cluster warehouses, Time Travel up to 90 days, materialized views, masking and row access policies, Search Optimization, Query Acceleration), Business Critical (Tri-Secret Secure, PrivateLink, HIPAA and PCI support, failover), and VPS (Virtual Private Snowflake).
- **1.2 Interfaces.**
  - **Snowsight:** worksheets, dashboards, Query Profile, cost management and the lineage graph.
  - **Snowflake CLI (`snow`):** the replacement for SnowSQL. It manages connections and deploys Streamlit apps, Native Apps and Snowpark code.
  - **VS Code extension:** runs queries and browses objects from the IDE.
- **1.3 Object hierarchy.**
  - **Account-level objects:** users, roles, warehouses, resource monitors, integrations, network policies and databases.
  - **Schema-level objects:** tables, views, stages, file formats, UDFs, stored procedures, pipes, sequences, streams, tasks and ML models.
  - **Shares** are account-level objects. **Applications** (Native Apps) are installed at account level.
  - **Parameters:** account parameters are overridden by user parameters, which are overridden by session parameters. For objects, account settings are overridden by database, then schema, then table. The most specific setting wins.
  - Know the context functions: CURRENT_ROLE(), CURRENT_WAREHOUSE() and so on.
- **1.4 Warehouses.**
  - **Types:** Standard Gen1, Standard Gen2 (newer hardware, faster for DML-heavy work, higher credit rate), and Snowpark-optimized (16x memory per node, for ML training and large UDFs).
  - **Scale up** (bigger size) for complex queries and spilling. **Scale out** (more clusters) for high concurrency and queuing.
  - **Scaling policies:** Standard starts a new cluster as soon as any query queues. Economy starts one only if it estimates the cluster will stay busy for 6 minutes.
  - **Auto-suspend:** set it low (60 seconds or so) for ad-hoc and loading work. Leave it longer for BI work, so the warehouse cache stays warm.
  - Give different teams or workloads their own warehouses.
- **1.5 Storage.**
  - **Micro-partitions:** 50 to 500 MB uncompressed and immutable, with min/max metadata per column that makes pruning possible.
  - **Clustering depth:** check it with SYSTEM$CLUSTERING_INFORMATION.
  - **Table types** (Time Travel and Fail-safe):

    | Type | Time Travel | Fail-safe |
    |---|---|---|
    | Permanent | 0 to 90 days | 7 days |
    | Transient | 0 to 1 day | none |
    | Temporary | 0 to 1 day | none |

    Temporary tables last only for the session.
  - **Other table types:** external tables are read-only over files in a stage. Iceberg tables use an external volume and either the Snowflake catalog or an external one. Dynamic tables are defined by a query plus a target lag.
  - **View types:** a standard view is just a stored query. A materialized view stores precomputed results, is maintained serverlessly, covers a single table only and needs Enterprise edition. A secure view hides its definition and blocks optimizer leaks. Only secure views can be shared.
- **1.6 AI/ML and app development.**
  - **Notebooks:** Python and SQL cells in Snowsight.
  - **Streamlit in Snowflake:** Python apps that run inside Snowflake and follow its RBAC.
  - **Snowpark:** DataFrames, UDFs and stored procedures in Python, Java or Scala. Code is pushed down to the warehouse.
  - **Cortex AI SQL functions:** AI_COMPLETE, AI_CLASSIFY, AI_SENTIMENT, AI_SUMMARIZE_AGG, AI_TRANSLATE and others. The older forms are SNOWFLAKE.CORTEX.COMPLETE and so on. Billed per token. Access needs the SNOWFLAKE.CORTEX_USER database role.
  - **Cortex Search:** hybrid (vector plus keyword) search service for RAG.
  - **Cortex Analyst:** natural-language to SQL through a semantic model.
  - **Snowflake ML:** Feature Store, Model Registry and ML functions such as forecasting and anomaly detection.

### Domain 2 · Account Management and Governance (20%)
- **2.1 Security model.**
  - **RBAC:** privileges are granted to roles, and roles are granted to users.
  - **DAC:** the role that owns an object can grant access to it.
  - **Securable hierarchy:** organization, then account, then database, then schema, then object.
  - **System roles:**
    - ORGADMIN manages the organization.
    - ACCOUNTADMIN is the top role in an account. It sits above SECURITYADMIN and SYSADMIN.
    - SECURITYADMIN manages grants. It sits above USERADMIN.
    - USERADMIN creates users and roles.
    - SYSADMIN creates warehouses and databases.
    - PUBLIC is granted to everyone.
  - **Best practice:** grant custom roles to SYSADMIN.
  - **Database roles:** scoped to one database. You can't activate them in a session; you grant them to account roles. They're useful in shares.
  - **Secondary roles:** USE SECONDARY ROLES ALL adds the privileges of the user's other roles. Creating objects still uses the primary role.
  - **Network policies and rules:** IP allow and block lists, set at account, user or integration level.
  - **Authentication:** MFA, SSO through SAML (federated), OAuth (Snowflake OAuth or external), and key-pair for service users.
  - **Account identifiers:** `orgname-accountname` is preferred. The account locator is the legacy form and is tied to a region.
  - **Logging and tracing:** event tables, with the LOG_LEVEL and TRACE_LEVEL parameters.
- **2.2 Governance.**
  - **Masking policies** for column-level security, including tag-based masking. **Row access policies** for row-level security.
  - **Object tagging** and automatic classification.
  - **Privacy policies** (differential privacy), alongside aggregation and projection policies.
  - **Trust Center:** scanner packages such as CIS benchmarks, findings, and the compute cost of running scans.
  - **Encryption:** AES-256 with hierarchical keys, automatic key rotation, periodic rekeying (Enterprise and above), and Tri-Secret Secure (customer-managed key, Business Critical).
  - **Alerts:** a scheduled condition plus an action. **Notifications:** through notification integrations, either email or webhook.
  - **Replication and failover:** replication and failover groups. Failover needs Business Critical.
  - **Lineage:** the Snowsight lineage graph and ACCESS_HISTORY.
- **2.3 Monitoring and cost.**
  - **Resource monitors:** created by ACCOUNTADMIN. They can notify, suspend, or suspend immediately. They cover warehouses only, not serverless features.
  - **Credit maths:** XS = 1 credit per hour, and each size up doubles it. Billing is per second with a 60-second minimum each time the warehouse resumes. A multi-cluster warehouse multiplies that by the number of clusters running. For example, a Medium (4 credits per hour) running for 30 minutes uses 2 credits.
  - **ACCOUNT_USAGE vs INFORMATION_SCHEMA:**

    | | Latency | Retention | Dropped objects |
    |---|---|---|---|
    | ACCOUNT_USAGE | 45 minutes to 3 hours | 1 year | included |
    | INFORMATION_SCHEMA | real time | 7 days to 6 months | not included |

### Domain 3 · Loading, Unloading and Connectivity (18%)
- **3.1 Loading and unloading.**
  - **Stages:** user (`@~`), table (`@%t`), named internal and named external.
  - **Encryption on internal stages:** SNOWFLAKE_FULL (client-side plus server-side) or SNOWFLAKE_SSE (server-side only, needed to share files by URL).
  - **Directory tables:** a catalog of the files in a stage, refreshed automatically or manually.
  - **File formats:** CSV, JSON, Avro, ORC, Parquet and XML.
  - **COPY INTO options:**
    - ON_ERROR: CONTINUE, SKIP_FILE or ABORT_STATEMENT (the default for COPY).
    - VALIDATION_MODE: a dry run.
    - PURGE: deletes files from the stage after a successful load.
    - FORCE: reloads files that were already loaded.
    - MATCH_BY_COLUMN_NAME.
  - **Load metadata:** kept for 64 days. TRUNCATE clears it but DELETE doesn't.
  - **Unloading:** COPY INTO @stage, then GET. Use SINGLE, MAX_FILE_SIZE and PARTITION BY.
  - **File sizing:** aim for compressed files of roughly 100 to 250 MB.
- **3.2 Automated ingestion.**
  - **Snowpipe:** serverless, triggered by cloud event notifications (auto-ingest) or the REST API. Its load history is kept for 14 days.
  - **Snowpipe Streaming:** loads rows (not files) through the SDK or the Kafka connector, with the lowest latency.
  - **Streams:** standard, append-only and insert-only. They record an offset and nothing else. A stream goes stale if it isn't consumed within the source table's data retention period.
  - **Tasks:** run on a schedule or a CRON, either serverless or on a warehouse. A task graph has one root. Tasks are created suspended, so run ALTER TASK … RESUME.
  - **Dynamic tables:** declarative. You write the query and set TARGET_LAG (or DOWNSTREAM), and refreshes are incremental or full. Choose them over streams and tasks unless you need procedural logic.
- **3.3 Connectors and integrations.**
  - **Drivers:** JDBC, ODBC, Python, Go, Node.js, .NET and Spark.
  - **Connectors:** Kafka and Spark.
  - **Integrations:**
    - Storage integration: external stage access through an IAM role, with no keys in SQL.
    - API integration: used for external functions and Git.
    - Git integration: CREATE GIT REPOSITORY, then run files from a repository stage.

### Domain 4 · Performance, Querying and Transformation (21%)
- **4.1 Evaluating performance.** In Query Profile and Query Insights, learn what each problem looks like and how to fix it:

  | Problem | What you see | Fix |
  |---|---|---|
  | Spilling | "Bytes spilled to local or remote storage" | A bigger warehouse |
  | Inefficient pruning | Partitions scanned close to partitions total | A clustering key or a better filter |
  | Exploding join | More rows come out of the join than go in | Fix the join condition |
  | Queuing | Queries wait before running | Multi-cluster warehouse, or a separate warehouse |

  - Use QUERY_HISTORY, and QUERY_ATTRIBUTION_HISTORY for per-query credit cost (idle time not included).
  - Workload management: put similar workloads on the same warehouse.
- **4.2 Optimizing performance.**
  - **Query Acceleration:** offloads parts of large scans in unpredictable ad-hoc queries.
  - **Search Optimization:** for point lookups on selective filters, substring and VARIANT searches. It's serverless.
  - **Clustering keys:** for very large tables that are filtered on the same columns. Automatic Clustering is serverless and costs credits.
  - **Materialized views:** for expensive, repeated aggregations on one table.
- **4.3 Caching.**

  | Cache | Where it lives | How long | When it's used |
  |---|---|---|---|
  | Result cache | Cloud services | 24 hours, extended each time it's reused, up to 31 days | Same query text and unchanged data. No warehouse is needed. |
  | Metadata cache | Cloud services | Always available | COUNT, MIN and MAX answered without a warehouse |
  | Warehouse (local disk) cache | The warehouse | Lost when the warehouse suspends | Reused table data |

- **4.4 Transformations.**
  - **Semi-structured data:** the VARIANT, OBJECT and ARRAY types; `col:path.sub[0]::type` syntax; LATERAL FLATTEN; PARSE_JSON; OBJECT_CONSTRUCT; ARRAY_AGG.
  - **Unstructured data:** directory tables and scoped, file and presigned URLs.
  - **Aggregate functions:** GROUP BY, ROLLUP and CUBE.
  - **Window functions:** ROW_NUMBER, RANK, LAG, LEAD and running totals. Use QUALIFY to filter on them.
  - **SQL hygiene:** select only the columns you need, filter early, and avoid functions on columns you filter by.

### Domain 5 · Data Collaboration (10%)
- **5.1 Protection.**
  - **Time Travel:** query with AT or BEFORE, and recover with UNDROP. Set the period with DATA_RETENTION_TIME_IN_DAYS.
  - **Fail-safe:** 7 days, and only Snowflake Support can recover data from it.
  - **Zero-copy cloning:** a clone is metadata only until it changes. A cloned stream starts empty, and cloned tasks start suspended.
  - **Replication:** of databases and accounts, across regions and clouds.
- **5.2 Sharing.**
  - **Provider and consumer:** the consumer's access is read-only and no data is copied. The provider pays for storage and the consumer pays for compute.
  - **Reader accounts:** for consumers who don't have a Snowflake account. The provider pays for their compute.
  - **No resharing:** a consumer can't share a database it received through a share.
  - **Direct shares:** only within the same region. Other regions need replication or a listing.
  - **Data clean rooms:** let two parties analyse joined data without exposing the raw rows.
- **5.3 Marketplace and listings.**
  - **Private listings** go to named accounts. **Public listings** appear on the Marketplace.
  - **Cross-Cloud Auto-Fulfillment** delivers listings to other regions.
  - **Native Apps:** an application package with a manifest and a setup script. The consumer installs it and it runs in the consumer's account.

## 4. Patterns from the guide's sample questions

Each sample question in the guide tests one specific rule. Expect variations of these:
1. **Stored procedure privileges.** EXECUTE AS OWNER is the default. EXECUTE AS CALLER runs with the calling role's privileges.
2. **Cloning a stream.** A cloned stream starts at the moment of the clone, with no pending changes.
3. **Economy scaling policy.** Choose it when cost matters more than queuing.
4. **TRUNCATE vs DELETE.** To empty a table, TRUNCATE is a fast metadata operation. It also resets load metadata, so files can be reloaded.
5. **Stage cleanup.** To stop loaded files piling up, use PURGE = TRUE. FORCE would reload files, and ON_ERROR changes how errors are handled.

The pattern behind all five: one constraint in the question (cost, minimum privilege, "without reloading") rules out three of the four options. Underline that constraint before you read the answers.

## 5. Resources
- **Official, free:** the study guide's resources for each domain, used on the days listed above. That means Badge workshops 1 to 3, the Level Up modules, and Getting Started modules 1 to 10. Also the [docs](https://docs.snowflake.com) and the [quickstarts](https://quickstarts.snowflake.com).
- **Official, paid:** the SnowPro Core practice exam (linked from the guide), used as Mock 2.
- **Third-party practice:** [open-exam-prep](https://open-exam-prep.com/practice/snowflake-core), plus Udemy practice tests that are labelled COF-C03. Avoid dump sites.
