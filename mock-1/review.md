# Mock 1 · Review

Graded from commit `1f635e9`. A multi-select question counts only if both picks are right. Q60's `(D.?)` counts as D. Q92 counts as your marked answer, C, even though you also put a `?` next to A.

## Score

| Domain | Score | Target | |
|---|---|---|---|
| 1 · Features and Architecture | **26 / 31 (84%)** | 25 | ✓ |
| 2 · Account Management and Governance | **13 / 20 (65%)** | 16 | ✗ |
| 3 · Loading, Unloading, Connectivity | **10 / 18 (56%)** | 15 | ✗ |
| 4 · Performance, Querying, Transformation | **20 / 21 (95%)** | 17 | ✓ |
| 5 · Data Collaboration | **9 / 10 (90%)** | 8 | ✓ |
| **Total** | **78 / 100** | 80 | just under |

Weighted by the real exam's domain weights, this is also about 78%. That's a solid first full mock, two points under the 80% target. Domain 4 is nearly perfect, even though you learned it two weeks ago. Domains 1 and 5 are on target.

## What the misses say

**Domain 3 dropped from 13/13 on Day 5 to 10/18 here.** None of the misses is a new idea. Each one has a sibling option that sounds right: FORCE vs LOAD_UNCERTAIN_FILES, PURGE vs TRUNCATE, Snowpipe vs Snowpipe Streaming, dynamic tables vs streams and tasks, drivers vs connectors. Nine days passed with no review in between, so the facts were still there but the distinctions had blurred.

**Three Domain 2 misses repeat Day 5 misses exactly:** CIS Benchmarks (Day 5 A9), failover needing Business Critical (A13), and ACCESS_HISTORY (A14). Writing a miss down once isn't making it stick. These need to be drilled a few times on different days.

**Seven right answers were guesses** (marked `?`): 15, 32, 63, 74, 80, 88, 100. Treat them as half-known.

## Misses and the concept behind each

### Domain 1

| Q | You | Right | Concept | Lesson |
|---|---|---|---|---|
| 2 | Peer-to-peer, shared-nothing | **Shared-nothing, shared-disk** | Central storage that every warehouse reads is **shared-disk**. Independent compute clusters are **shared-nothing**. Snowflake is a hybrid of the two. | Day 1 · 1.1 |
| 3 | 16 MB compressed | **50–500 MB uncompressed** | 16 MB is the **unload** default file size, and 100–250 MB compressed is the recommended **load** file size. Micro-partitions are 50–500 MB of **uncompressed** data. | Day 1 · 1.5 |
| 4 | User-defined, updated in place | **Columnar, immutable** | Snowflake creates micro-partitions automatically, and they are **never changed**. An UPDATE writes new micro-partitions. This is why Time Travel and cloning are cheap. | Day 1 · 1.5 |
| 26 | The viewing user's | **The app owner role's** | Streamlit in Snowflake runs with **owner's rights** by default, like an owner's-rights stored procedure. | Day 2 · 1.6 |
| 30 | AI_CLASSIFY | **AI_FILTER** | The clue is "keeps rows … in a WHERE clause". AI_FILTER returns TRUE or FALSE. AI_CLASSIFY returns a category label. | Day 2 · 1.6 |

### Domain 2

| Q | You | Right | Concept | Lesson |
|---|---|---|---|---|
| 42 | Security Essentials | **CIS Benchmarks package** | **Repeat of Day 5 A9.** The question names the CIS benchmark, so the answer is the package named after it. Security Essentials is the free, always-on package (MFA, network policy). | Day 5 · §5 |
| 43 | Client-side encryption, Enterprise | **Tri-Secret Secure, Business Critical** | "A key held in their own cloud KMS that they can revoke" is Tri-Secret Secure. | Day 5 · §6 |
| 44 | Rotates every 30 days, all editions | **Re-encrypts data whose key was retired over a year ago, Enterprise** | Two different processes. **Rotation**: every 30 days, automatic, all editions, retired keys still decrypt old data. **Rekeying**: re-encrypts data so year-old keys stop being used at all, Enterprise. | Day 5 · §6 |
| 46 | A clone | **A failover group, Business Critical** | **Repeat of Day 5 A13.** A clone stays in the same account. "Promoted to accept writes" means failover, which needs Business Critical. | Day 5 · §8 |
| 47 | QUERY_HISTORY | **ACCESS_HISTORY** | **Repeat of Day 5 A14.** QUERY_HISTORY has the SQL text. ACCESS_HISTORY has the **columns** each query read, and sees through views. | Day 5 · §9 |
| 50 | Dropped objects, current database only | **Dropped objects, ~1 year** | ACCOUNT_USAGE covers the **whole account**. "One database" describes INFORMATION_SCHEMA. | Day 5 · §12 |
| 51 | SYSADMIN | **ACCOUNTADMIN** | Only ACCOUNTADMIN creates resource monitors. Lab section 6 shows SYSADMIN failing. | Day 5 · §10 |

### Domain 3

| Q | You | Right | Concept | Lesson |
|---|---|---|---|---|
| 53 | Tables share one stage | **No transformations during COPY** | Each table has **its own** table stage. It can't be dropped or granted, and COPY from it can't transform. | Day 5 · §13 |
| 54 | FORCE | **LOAD_UNCERTAIN_FILES** | FORCE reloads **everything**, including files known to be loaded, so it duplicates data. LOAD_UNCERTAIN_FILES only adds files whose status is **unknown** because they're older than 64 days. | Day 5 · §14 |
| 59 | Clears the load metadata | **Removes loaded files from the stage** | **PURGE** cleans the **stage**. **TRUNCATE** cleans the **table** and its load metadata. | Day 5 · §14 |
| 61 | CRON, EXECUTE PIPE | **REST API, event notifications** | Pipes have no schedule, and there's no EXECUTE PIPE command. They're triggered by the cloud's **event notification** (auto-ingest) or a **REST API** call. | Day 6 · §1 |
| 64 | Serverless, can't be scheduled | **Serverless, needs EXECUTE MANAGED TASK** | Serverless tasks are scheduled like any task. Running on Snowflake-managed compute needs the MANAGED privilege. | Day 6 · §4 |
| 65 | Dynamic table | **Streams and tasks** | IF/ELSE, a stored procedure, MERGE and CRON are all things a dynamic table can't do. Dynamic tables are one declarative SELECT. | Day 6 · §5 |
| 66 | Snowpipe with auto-ingest | **Snowpipe Streaming** | "Without staging files" and "within seconds" both rule out Snowpipe, which loads **files** in about a minute. | Day 6 · §2 |
| 68 | Kafka connector, JDBC | **Go, JDBC** | A **driver** lets code run SQL (JDBC, ODBC, Python, Go, Node.js, .NET). A **connector** moves data between systems (Kafka, Spark). | Day 6 · §6 |

### Domains 4 and 5

| Q | You | Right | Concept | Lesson |
|---|---|---|---|---|
| 83 | KEY | **VALUE** | VALUE is the element itself. KEY is only filled in when you flatten an **object** (it holds the field name). INDEX is the position in an array. | Day 4 |
| 92 | UNDROP | **Only Snowflake Support, from Fail-safe** | Retention 0 means **no Time Travel**, so UNDROP has nothing to restore. The table is permanent, so it still goes into its 7 days of Fail-safe. Your second instinct, A, was right. | Day 6 · §8–9 |

## Before Mock 2

The plan's next step is Day 7: about 90 minutes on your weakest areas, then **Mock 2** (the official Snowflake practice exam).

1. **Domain 3 (biggest gap):** reread Day 5 sections 13–15 and Day 6 sections 1–6. Focus on the pairs: FORCE vs LOAD_UNCERTAIN_FILES, PURGE vs TRUNCATE, Snowpipe vs Snowpipe Streaming, dynamic tables vs streams and tasks, drivers vs connectors.
2. **Domain 2:** Day 5 sections 5, 6, 8, 9, 10 and 12. Say the three repeat misses out loud once a day until the exam: *CIS → CIS package. Failover → Business Critical. Columns read → ACCESS_HISTORY.*
3. **Domain 1:** Day 1 sections 1.1 and 1.5 (architecture, micro-partitions).
