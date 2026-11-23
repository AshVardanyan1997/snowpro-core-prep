# Mock 1 · Review, question by question

Graded from commit `1f635e9`. This review lists **every question you got wrong**, then **every question you got right but marked with `?`**. Each one shows the full question, your answer, the correct answer, why, its domain and objective, and where it's covered in the lessons.

## Score

| Domain | Score | Target (80%) |
|---|---|---|
| Domain 1 · Features and Architecture | **26 / 31** | 25 |
| Domain 2 · Account Management and Governance | **13 / 20** | 16 |
| Domain 3 · Loading, Unloading, Connectivity | **10 / 18** | 15 |
| Domain 4 · Performance, Querying, Transformation | **20 / 21** | 17 |
| Domain 5 · Data Collaboration | **9 / 10** | 8 |
| **Total** | **78 / 100** | 80 |

**22 wrong** and **8 right but unsure**. Marking `(D.?)` on Q60 counts as D. On Q92 you marked C with a `?` and also put a `?` next to A, so C is graded as your answer.

**How to use this:** read each card, then cover the "Correct" line and answer it again. The three cards marked **Repeat** (Q42, Q46, Q47) are concepts you also missed on Day 5, so go over those twice.

---

## Part 1 · Answered incorrectly

## Domain 1 · Features and Architecture

### Q2 · ❌ Wrong

**Domain 1 · Features and Architecture** · objective 1.1 · covered in [Day 1](../day-1/notes.md), section "1.1 Architecture"

Snowflake's architecture is often described as a hybrid of which two traditional designs? (Select TWO)

- A. Peer-to-peer  **← your answer (marked ?)**
- B. Shared-memory
- C. Shared-nothing  **← your answer (marked ?)** · ✅ **correct**
- D. Shared-disk  ✅ **correct**
- E. Master-slave replication

**Correct:** C, D. **Why:** Snowflake keeps **one central copy of the data** that every warehouse can read. That part is **shared-disk**. Each warehouse is an **independent compute cluster** that doesn't share CPU or memory with others. That part is **shared-nothing**. "Hybrid" means both at once.

### Q3 · ❌ Wrong

**Domain 1 · Features and Architecture** · objective 1.5 · covered in [Day 1](../day-1/notes.md), section "1.5 Storage concepts → Micro-partitions"

What size are Snowflake micro-partitions?

- A. 1 GB each
- B. 100 to 250 MB compressed
- C. 16 MB compressed  **← your answer**
- D. 50 to 500 MB of uncompressed data  ✅ **correct**

**Correct:** D. **Why:** Three different sizes are easy to mix up. **Micro-partitions: 50–500 MB uncompressed.** Files to load: 100–250 MB compressed. Unloaded files: 16 MB by default.

### Q4 · ❌ Wrong

**Domain 1 · Features and Architecture** · objective 1.5 · covered in [Day 1](../day-1/notes.md), section "1.5 Storage concepts → Micro-partitions"

Which statements about micro-partitions are TRUE? (Select TWO)

- A. Users define them with PARTITION BY when creating a table  **← your answer**
- B. Each table has exactly one micro-partition per day
- C. Data inside them is stored by column  ✅ **correct**
- D. They are immutable  ✅ **correct**
- E. They can be updated in place  **← your answer (marked ?)**

**Correct:** C, D. **Why:** Snowflake creates micro-partitions **automatically** as data arrives, so there is no PARTITION BY. They are **immutable**: an UPDATE writes new micro-partitions instead of changing old ones, and the old ones are kept for Time Travel. Inside each one, data is stored **by column**.

### Q26 · ❌ Wrong

**Domain 1 · Features and Architecture** · objective 1.6 · covered in [Day 2](../day-2/notes.md), section "1.6 → Streamlit in Snowflake"

By default, whose privileges does a Streamlit in Snowflake app use when it queries data?

- A. PUBLIC's
- B. ACCOUNTADMIN's
- C. The viewing user's  **← your answer**
- D. The app owner role's  ✅ **correct**

**Correct:** D. **Why:** Streamlit in Snowflake apps run with **owner's rights** by default. They use the owner role's privileges and warehouse, so viewers can see data through the app that they couldn't query themselves. The owner grants USAGE on the app to decide who can open it.

### Q30 · ❌ Wrong

**Domain 1 · Features and Architecture** · objective 1.6 · covered in [Day 2](../day-2/notes.md), section "1.6 → Snowflake Cortex" (the AI SQL functions table)

Which function keeps only the rows that match a natural-language condition, used in a WHERE clause?

- A. AI_FILTER  ✅ **correct**
- B. AI_EMBED
- C. AI_AGG
- D. AI_CLASSIFY  **← your answer**

**Correct:** A. **Why:** The clue is "**keeps only the rows** … in a **WHERE** clause". That needs a TRUE or FALSE answer, which is what **AI_FILTER** returns. AI_CLASSIFY returns a category label, which you would put in the SELECT list.

## Domain 2 · Account Management and Governance

### Q42 · ❌ Wrong · **Repeat of a Day 5 miss**

**Domain 2 · Account Management and Governance** · objective 2.2 · covered in [Day 5](../day-5/notes.md), Part 1 §5 "Are we configured safely?": the Trust Center

A security team wants to check the account against the Center for Internet Security's benchmark for Snowflake. What should they turn on?

- A. Periodic rekeying
- B. Security Essentials in Trust Center  **← your answer**
- C. The CIS Benchmarks scanner package in Trust Center  ✅ **correct**
- D. A row access policy

**Correct:** C. **Why:** **This repeats Day 5 A9.** The question names the **CIS** benchmark, and there is a scanner package with exactly that name. **Security Essentials** is a different package: free, always on, and it checks MFA and network policies.

### Q43 · ❌ Wrong

**Domain 2 · Account Management and Governance** · objective 2.2 · covered in [Day 5](../day-5/notes.md), Part 1 §6 "Who holds the keys?": encryption key management

A customer wants to be able to revoke a key held in their own cloud key-management service, so Snowflake can no longer decrypt their data. Which feature is this, and what edition does it need?

- A. Periodic rekeying, Enterprise
- B. Client-side encryption, Enterprise  **← your answer**
- C. Automatic key rotation, Standard
- D. Tri-Secret Secure, Business Critical  ✅ **correct**

**Correct:** D. **Why:** "A key in **their own** cloud KMS that **they can revoke**" describes **Tri-Secret Secure**. Snowflake combines your key with its own, so revoking yours locks the data. It needs **Business Critical**.

### Q44 · ❌ Wrong

**Domain 2 · Account Management and Governance** · objective 2.2 · covered in [Day 5](../day-5/notes.md), Part 1 §6 "Who holds the keys?": encryption key management

What does periodic rekeying do?

- A. Encrypts data in transit
- B. Re-encrypts data whose key was retired more than a year ago, on Enterprise or higher  ✅ **correct**
- C. Lets customers bring their own key
- D. Rotates keys every 30 days on all editions  **← your answer (marked ?)**

**Correct:** B. **Why:** These are two separate processes. **Rotation**: every 30 days on all editions, new data gets a new key, and old keys still decrypt old data. **Periodic rekeying** (Enterprise): data whose key was **retired over a year ago** is re-encrypted, so old keys stop being used at all.

### Q46 · ❌ Wrong · **Repeat of a Day 5 miss**

**Domain 2 · Account Management and Governance** · objective 2.2 · covered in [Day 5](../day-5/notes.md), Part 1 §8 "What if the whole region goes down?": replication and failover

A company wants a secondary account in another region that can be promoted to accept writes if the primary region fails. What does it need?

- A. A clone of the database  **← your answer**
- B. A replication group on Standard edition
- C. A direct share
- D. A failover group, which needs Business Critical  ✅ **correct**

**Correct:** D. **Why:** **This repeats Day 5 A13.** A clone lives in the **same account**, so it doesn't help if the region fails. "**Promoted to accept writes**" is the definition of a **failover group**, which needs **Business Critical**.

### Q47 · ❌ Wrong · **Repeat of a Day 5 miss**

**Domain 2 · Account Management and Governance** · objective 2.2 · covered in [Day 5](../day-5/notes.md), Part 1 §9 "Where did this number come from?": lineage and access history

Auditors ask who read the `salary` column last month, including reads through views. Which ACCOUNT_USAGE view answers this?

- A. TAG_REFERENCES
- B. ACCESS_HISTORY  ✅ **correct**
- C. LOGIN_HISTORY
- D. QUERY_HISTORY  **← your answer**

**Correct:** B. **Why:** **This repeats Day 5 A14.** QUERY_HISTORY stores the **SQL text** of each query. It doesn't list the **columns** that were read, and it can't see through a view to the table behind it. **ACCESS_HISTORY** does both (`base_objects_accessed`).

### Q50 · ❌ Wrong

**Domain 2 · Account Management and Governance** · objective 2.3 · covered in [Day 5](../day-5/notes.md), Part 2 §12 "Show me the history": the ACCOUNT_USAGE schema

Which statements about the ACCOUNT_USAGE schema are TRUE? (Select TWO)

- A. Most views keep about 1 year of history  ✅ **correct**
- B. It has no latency
- C. It includes dropped objects  **← your answer** · ✅ **correct**
- D. Only SYSADMIN can query it
- E. It covers only the current database  **← your answer**

**Correct:** A, C. **Why:** ACCOUNT_USAGE covers the **whole account**, including dropped objects, keeps about **1 year**, and is 45 minutes to 3 hours behind. "Only the current database" describes **INFORMATION_SCHEMA**, which is the opposite on every point.

### Q51 · ❌ Wrong

**Domain 2 · Account Management and Governance** · objective 2.3 · covered in [Day 5](../day-5/notes.md), Part 2 §10 "Last month cost three times the budget": resource monitors

Who can create a resource monitor?

- A. SECURITYADMIN
- B. Any role with CREATE WAREHOUSE
- C. ACCOUNTADMIN  ✅ **correct**
- D. SYSADMIN  **← your answer (marked ?)**

**Correct:** C. **Why:** **Only ACCOUNTADMIN** can create resource monitors. ACCOUNTADMIN can grant MONITOR or MODIFY on one, but not the right to create one. Lab section 6 showed SYSADMIN failing.

## Domain 3 · Loading, Unloading, Connectivity

### Q53 · ❌ Wrong

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.1 · covered in [Day 5](../day-5/notes.md), Part 3 §13 "The daily orders file": file formats and stages

Which statement about table stages (`@%table`) is TRUE?

- A. Several tables share one table stage  **← your answer (marked ?)**
- B. They don't support transformations during COPY  ✅ **correct**
- C. They can be dropped like named stages
- D. Privileges on them can be granted to any role

**Correct:** B. **Why:** Every table has **its own** table stage (`@%orders` belongs only to `orders`). It can't be dropped, altered or granted to other roles, and a COPY from it **can't transform** data. Use a named stage for transformations.

### Q54 · ❌ Wrong

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.1 · covered in [Day 5](../day-5/notes.md), Part 3 §14 "Running the load": COPY INTO and its memory

Files were staged long ago, and their load status is unknown because the load metadata has expired. Which COPY option loads them anyway?

- A. PURGE = TRUE
- B. FORCE = TRUE  **← your answer**
- C. VALIDATION_MODE = RETURN_ALL_ERRORS
- D. LOAD_UNCERTAIN_FILES = TRUE  ✅ **correct**

**Correct:** D. **Why:** **FORCE** reloads **every** file, including ones known to be loaded, so it creates duplicates. **LOAD_UNCERTAIN_FILES** loads only the files whose status is **unknown** because their load metadata (64 days) has expired.

### Q59 · ❌ Wrong

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.1 · covered in [Day 5](../day-5/notes.md), Part 3 §14 "Running the load": COPY INTO and its memory

What does PURGE = TRUE do in a COPY INTO <table> command?

- A. Deletes the target table's existing rows before loading
- B. Removes successfully loaded files from the stage  ✅ **correct**
- C. Clears the load metadata  **← your answer (marked ?)**
- D. Deletes files that failed to load

**Correct:** B. **Why:** **PURGE cleans the stage**: it deletes files after they load successfully. **TRUNCATE cleans the table** and its load metadata. The names don't help, so remember the pair.

### Q61 · ❌ Wrong

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.2 · covered in [Day 6](../day-6/notes.md), Part 1 §1 "Stop running COPY by hand": Snowpipe

What are the two ways to trigger Snowpipe? (Select TWO)

- A. A CRON schedule on the pipe  **← your answer**
- B. Calls to the Snowpipe REST API  ✅ **correct**
- C. Cloud storage event notifications (auto-ingest)  ✅ **correct**
- D. Running EXECUTE PIPE  **← your answer**
- E. A resource monitor

**Correct:** B, C. **Why:** A pipe has **no schedule**, and there's **no EXECUTE PIPE** command. It is triggered by the cloud **event notification** when a file lands (auto-ingest), or by your application calling the **REST API**. (EXECUTE TASK and EXECUTE ALERT exist. EXECUTE PIPE doesn't.)

### Q64 · ❌ Wrong

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.2 · covered in [Day 6](../day-6/notes.md), Part 1 §4 "Run it every hour, by itself": tasks

A task is created without a WAREHOUSE parameter. Which statements are TRUE? (Select TWO)

- A. The owner role needs the EXECUTE MANAGED TASK privilege  ✅ **correct**
- B. It runs on serverless compute managed by Snowflake  **← your answer** · ✅ **correct**
- C. It fails at creation
- D. It runs on the user's default warehouse
- E. It can't be scheduled  **← your answer (marked ?)**

**Correct:** A, B. **Why:** No WAREHOUSE means the task is **serverless**. It can still have a SCHEDULE or CRON. Using Snowflake-managed compute needs the **EXECUTE MANAGED TASK** privilege.

### Q65 · ❌ Wrong

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.2 · covered in [Day 6](../day-6/notes.md), Part 1 §5 dynamic tables (the "Which tool when?" table)

A pipeline needs IF/ELSE logic in a stored procedure, a MERGE, and a run at 02:00 every night (CRON). Which approach fits best?

- A. A materialized view
- B. A dynamic table  **← your answer**
- C. A secure view
- D. Streams and tasks  ✅ **correct**

**Correct:** D. **Why:** Every requirement rules out a dynamic table: **IF/ELSE in a procedure**, **MERGE** and a **CRON** time. A dynamic table is one declarative SELECT with a target lag. **Streams and tasks** handle all three.

### Q66 · ❌ Wrong

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.2 · covered in [Day 6](../day-6/notes.md), Part 1 §2 "Within seconds, not a minute": Snowpipe Streaming

IoT devices send small JSON events continuously, and they must be queryable within seconds without staging files. Which feature fits?

- A. Snowpipe with auto-ingest  **← your answer**
- B. An external table
- C. Snowpipe Streaming  ✅ **correct**
- D. Bulk COPY INTO

**Correct:** C. **Why:** Two clues rule out Snowpipe: "**without staging files**" (Snowpipe loads files) and "**within seconds**" (Snowpipe takes about a minute). **Snowpipe Streaming** sends rows directly through an SDK.

### Q68 · ❌ Wrong

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.3 · covered in [Day 6](../day-6/notes.md), Part 2 §6 "Our tools need to talk to Snowflake": drivers and connectors

Which of these are Snowflake drivers? (Select TWO)

- A. Snowpipe Streaming
- B. Go  ✅ **correct**
- C. The Kafka connector  **← your answer**
- D. Snowsight
- E. JDBC  **← your answer** · ✅ **correct**

**Correct:** B, E. **Why:** A **driver** lets your code or tool **run SQL** against Snowflake: JDBC, ODBC, Python, **Go**, Node.js, .NET. A **connector** **moves data** between Snowflake and another system: Kafka, Spark.

## Domain 4 · Performance, Querying, Transformation

### Q83 · ❌ Wrong

**Domain 4 · Performance, Querying, Transformation** · objective 4.4 · covered in [Day 4](../day-4/notes.md), section "4.4 → FLATTEN"

Which FLATTEN output column holds each array element?

- A. INDEX
- B. KEY  **← your answer**
- C. SEQ
- D. VALUE  ✅ **correct**

**Correct:** D. **Why:** **VALUE** is the element itself. **INDEX** is its position in an array. **KEY** is only filled in when you flatten an **object**, and holds the field name.

## Domain 5 · Data Collaboration

### Q92 · ❌ Wrong

**Domain 5 · Data Collaboration** · objective 5.1 · covered in [Day 6](../day-6/notes.md), Part 3 §8 Time Travel and §9 Fail-safe

A permanent table with DATA_RETENTION_TIME_IN_DAYS = 0 is dropped by mistake. How can it be recovered?

- A. Only through Snowflake Support, from Fail-safe  ← you marked this with ? · ✅ **correct**
- B. Query it with AT(OFFSET => -60)
- C. UNDROP TABLE  **← your answer (marked ?)**
- D. It can't be recovered at all

**Correct:** A. **Why:** Retention 0 means **no Time Travel**, so UNDROP has nothing to restore. The table is **permanent**, so it still gets its **7 days of Fail-safe**, which only Snowflake Support can recover from. You also put a `?` next to A: your second instinct was right.

---

## Part 2 · Right, but you marked them unsure

These were right, but a `?` means you weren't sure, so treat them as half-known.

### Q15 · ✅ Right, marked ?

**Domain 1 · Features and Architecture** · objective 1.2 · covered in [Day 2](../day-2/notes.md), section "1.2 Interfaces and tools"

Which clients can run the PUT command to upload a local file to an internal stage? (Select TWO)

- A. The Snowflake Marketplace
- B. SnowSQL  **← your answer (marked ?)** · ✅ **correct**
- C. Snowflake CLI  **← your answer** · ✅ **correct**
- D. Cortex Analyst
- E. A Snowsight SQL worksheet

**Correct:** B, C. **Why:** PUT runs from a client such as Snowflake CLI, SnowSQL or a driver, not from a Snowsight worksheet.

### Q32 · ✅ Right, marked ?

**Domain 2 · Account Management and Governance** · objective 2.1 · covered in [Day 4](../day-4/notes.md), section "2.1 → System-defined roles"

Which system role creates users and roles by default?

- A. ORGADMIN
- B. USERADMIN  **← your answer (marked ?)** · ✅ **correct**
- C. PUBLIC
- D. SYSADMIN

**Correct:** B. **Why:** USERADMIN has CREATE USER and CREATE ROLE.

### Q60 · ✅ Right, marked ?

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.2 · covered in [Day 6](../day-6/notes.md), Part 1 §1 "Stop running COPY by hand": Snowpipe

How is Snowpipe compute billed?

- A. On the warehouse named in the pipe
- B. A fixed charge per file regardless of size
- C. It isn't billed
- D. As serverless compute, based on the amount of data loaded  **← your answer (marked ?)** · ✅ **correct**

**Correct:** D. **Why:** Serverless, a fixed number of credits per GB loaded. No warehouse.

### Q63 · ✅ Right, marked ?

**Domain 3 · Loading, Unloading, Connectivity** · objective 3.2 · covered in [Day 6](../day-6/notes.md), Part 1 §3 "Process only what's new": streams (the vacation problem)

A table has DATA_RETENTION_TIME_IN_DAYS = 1, and its stream hasn't been consumed for some time. By default, how long can Snowflake extend the table's retention to keep the stream from going stale?

- A. 1 day
- B. 7 days
- C. 14 days  **← your answer (marked ?)** · ✅ **correct**
- D. 90 days

**Correct:** C. **Why:** Up to 14 days by default (MAX_DATA_EXTENSION_TIME_IN_DAYS).

### Q74 · ✅ Right, marked ?

**Domain 4 · Performance, Querying, Transformation** · objective 4.2 · covered in [Day 3](../day-3/notes.md), section "4.2 → Query Acceleration Service"

A warehouse runs mostly small queries, but occasional ad-hoc queries scan huge amounts of data and slow everything down. Which feature is designed for these outlier queries?

- A. Materialized views
- B. Automatic Clustering
- C. Query Acceleration Service  **← your answer (marked ?)** · ✅ **correct**
- D. Search Optimization Service

**Correct:** C. **Why:** Query Acceleration offloads parts of outlier large-scan queries to serverless compute.

### Q80 · ✅ Right, marked ?

**Domain 4 · Performance, Querying, Transformation** · objective 4.3 · covered in [Day 3](../day-3/notes.md), section "4.3 Caching → Warehouse cache"

What happens to the warehouse (local disk) cache when a warehouse suspends?

- A. It moves to the result cache
- B. It's kept for 24 hours
- C. It's dropped  **← your answer (marked ?)** · ✅ **correct**
- D. It's copied to remote storage

**Correct:** C. **Why:** The warehouse cache is dropped on suspend.

### Q88 · ✅ Right, marked ?

**Domain 4 · Performance, Querying, Transformation** · objective 4.4 · covered in [Day 4](../day-4/notes.md), section "4.4 → Unstructured data" (the three URL types)

Which type of URL lets only the user who generated it access a staged file, and expires after 24 hours?

- A. External URL
- B. Scoped URL  **← your answer (marked ?)** · ✅ **correct**
- C. File URL
- D. Pre-signed URL

**Correct:** B. **Why:** Scoped URL: only the generating user, 24 hours.

### Q100 · ✅ Right, marked ?

**Domain 5 · Data Collaboration** · objective 5.3 · covered in [Day 6](../day-6/notes.md), Part 3 §15 "Sell the software, not just the data": Native Apps

Where does a Snowflake Native App run after a consumer installs it?

- A. In the consumer's account  **← your answer (marked ?)** · ✅ **correct**
- B. Outside Snowflake, on the provider's servers
- C. In the provider's account, on the consumer's data copied there
- D. In a reader account

**Correct:** A. **Why:** Native Apps are installed and run in the consumer's account.

---

## The look-alike pairs to say out loud before Mock 2

| If the question says… | The answer is… | Not… |
|---|---|---|
| "names the **CIS** benchmark" | CIS Benchmarks package | Security Essentials (always on, free) |
| "**promoted** to accept writes" | Failover group, **Business Critical** | Replication group, clone |
| "which **columns** were read, through views" | **ACCESS_HISTORY** | QUERY_HISTORY |
| "own key they can **revoke**" | **Tri-Secret Secure**, Business Critical | Periodic rekeying |
| "re-encrypt data with **year-old** retired keys" | **Periodic rekeying**, Enterprise | 30-day rotation (all editions) |
| "**whole account**, dropped objects, 1 year" | ACCOUNT_USAGE | INFORMATION_SCHEMA (one database, real time) |
| "load files with **unknown** status" | LOAD_UNCERTAIN_FILES | FORCE (reloads everything) |
| "remove files **from the stage**" | PURGE | TRUNCATE (clears the table and load metadata) |
| "**rows**, **seconds**, no files" | Snowpipe Streaming | Snowpipe (files, about a minute) |
| Snowpipe is triggered by… | Event notifications or REST API | A schedule, EXECUTE PIPE |
| "IF/ELSE, MERGE, **CRON**" | Streams and tasks | Dynamic table (one declarative SELECT) |
| "run **SQL** from code" | Driver (JDBC, ODBC, Go, Python…) | Connector (Kafka, Spark move data) |
| "in a **WHERE** clause, natural language" | AI_FILTER | AI_CLASSIFY (returns a label) |
| Streamlit app privileges | **Owner's** rights | The viewer's |
| Micro-partition size | **50–500 MB uncompressed** | 100–250 MB compressed (load files), 16 MB (unload files) |
| Snowflake architecture | Shared-disk + shared-nothing | Peer-to-peer, shared-memory |
| Retention 0, permanent table dropped | Fail-safe, Snowflake Support only | UNDROP |
