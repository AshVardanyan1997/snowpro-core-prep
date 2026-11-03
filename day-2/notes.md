# Day 2 · Tue Nov 3 · Interfaces, Virtual Warehouses, AI/ML and App Development

**Covers:** objectives 1.2, 1.4 and 1.6 (Domain 1, 31% of the exam) · **Time:** about 3 hours

## What this lesson covered

These are the official COF-C03 domain and objective names, so you can look each one up in the [Snowflake documentation](https://docs.snowflake.com) for a second round.

**Domain 1.0: Snowflake AI Data Cloud Features and Architecture**
- 1.2 Use Snowflake interfaces and tools
  - Snowsight
  - Snowflake CLI
  - IDE integrations (e.g., Visual Studio Code)
- 1.4 Configure virtual warehouses
  - Types: Snowpark-optimized, Standard (Gen 1 and Gen 2), default warehouse for Notebooks (**not tested**)
  - Scaling policies
  - Warehouse type and configuration by use case: ad-hoc queries, data loading, BI and reporting
  - Best practices: sizing (up, down), scaling (in, out), auto-suspend, workloads (different teams, high concurrency, complex queries)
- 1.6 Explain AI/ML and application development features
  - Snowflake Notebooks
  - Streamlit in Snowflake
  - Snowpark
  - Snowflake Cortex: AI SQL functions, Cortex Search, Cortex Analyst
  - Snowflake ML

---

| Block | Time | What to do |
|---|---|---|
| Warm-up | 15 min | Reread the "Ten facts" in [day-1/notes.md](../day-1/notes.md) and your [Day 1 review](../day-1/practice-review.md) |
| Review set | 10 min | Answer [practice-questions.md](practice-questions.md) Part A (Day 1 weak spots) |
| Notes | 60 min | Read this file. Spend most of it on 1.4, which is the heaviest topic today |
| Lab | 50 min | Run [lab.sql](lab.sql) in a Snowsight worksheet |
| Practice | 35 min | Answer [practice-questions.md](practice-questions.md) Part B, then log every miss |

Free courses if you want to go further: *Badge 1: Data Warehousing Workshop* (start it), and the *Snowflake Cortex AISQL* / LLM functions quickstart.

---

## 1.2 Interfaces and tools

| Tool | What it is | What exam questions focus on |
|---|---|---|
| **Snowsight** | The web UI (the old Classic Console is retired) | SQL and Python **worksheets**, **Notebooks**, **dashboards**, **Query History** and **Query Profile**, cost management, the **lineage** graph, data previews, Marketplace, Trust Center, Streamlit apps, and Snowflake Copilot (an AI assistant that writes SQL). |
| **Snowflake CLI** (`snow`) | Open-source command-line tool, the **successor to SnowSQL** | Developer-focused: manage connections (`snow connection add`, `snow connection test`), run SQL (`snow sql -q "…"`), and deploy **Streamlit** apps (`snow streamlit deploy`), **Native Apps** (`snow app run`), **Snowpark** code (`snow snowpark build` / `deploy`), and work with stages and Git repositories. Settings live in `config.toml`. |
| **SnowSQL** | The legacy CLI client | Still works for running SQL and PUT/GET, but new work goes to Snowflake CLI. |
| **VS Code extension** | Official IDE integration | Run SQL and see results in the IDE, browse databases and objects, see query history, and develop Snowpark and Native App code. |

Exam traps:
- "Which tool deploys a Streamlit app or Native App from the command line?" **Snowflake CLI**, not SnowSQL.
- PUT and GET (moving files between your machine and an **internal** stage) are run from a client such as Snowflake CLI, SnowSQL or a driver. In Snowsight you'd normally upload files through the UI instead.
- Query Profile lives in **Snowsight** (Query History → a query → Query Profile). It's the main tool for objective 4.1 on Day 3.

---

## 1.4 Virtual warehouses

A virtual warehouse is a named cluster of compute that runs queries, DML and loading. It needs to be **running** to do that. Metadata-only queries, DDL and the result cache don't need one (Day 1).

### Sizes and credits

| Size | XS | S | M | L | XL | 2XL | 3XL | 4XL | 5XL | 6XL |
|---|---|---|---|---|---|---|---|---|---|---|
| Credits per hour (Standard Gen 1) | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 | 256 | 512 |

- Each size up **doubles** both the compute and the credit rate. A query that takes 10 minutes on S and 5 minutes on M costs the same.
- Billing is **per second**, with a **60-second minimum** each time the warehouse starts or resumes. Suspending and resuming every 30 seconds therefore wastes money.
- A multi-cluster warehouse bills each running cluster separately.

### Types (1.4.1)

| Type | What it is | When to use it |
|---|---|---|
| **Standard Gen 1** | The default | General SQL workloads |
| **Standard Gen 2** | Newer hardware and software optimizations. Faster, especially for **DML-heavy work** (UPDATE, DELETE, MERGE) and large scans. A higher credit rate per hour, but often a lower cost per query. Set with `RESOURCE_CONSTRAINT = STANDARD_GEN_2`. | Same workloads as Gen 1, when you want them to finish faster |
| **Snowpark-optimized** | **16x the memory per node** of a standard warehouse, plus a larger local cache. `WAREHOUSE_TYPE = 'SNOWPARK-OPTIMIZED'`. A higher credit rate. | **Memory-heavy** work: ML training in Snowpark stored procedures, large UDFs and UDTFs |
| Default warehouse for Notebooks | **Not tested** until it is generally available. Skip it. | |

### Sizing up vs scaling out (the most-tested idea today)

| | **Scale up** (resize: bigger size) | **Scale out** (multi-cluster: more clusters) |
|---|---|---|
| Fixes | **Slow, complex queries**, and **spilling** to local or remote storage | **Queuing**: many concurrent users or queries waiting to start |
| How | `ALTER WAREHOUSE … SET WAREHOUSE_SIZE = LARGE` | `MIN_CLUSTER_COUNT` and `MAX_CLUSTER_COUNT` |
| Edition | Any | **Enterprise and above** |
| Effect on running queries | Queries already running finish on the old size. New and queued queries use the new size. | New clusters take new queries. A single query never spans clusters. |

Memory hook: **"Spill → size, Queue → clusters."** This is exactly A2 and A7 from your Day 1 diagnostic.

Scaling **down** (smaller size) and scaling **in** (fewer clusters) are how you save credits once the load drops. Auto-scale mode scales in for you.

### Multi-cluster warehouses and scaling policies (1.4.2)

Two modes:
- **Maximized:** MIN_CLUSTER_COUNT = MAX_CLUSTER_COUNT (for example 3 and 3). All clusters start with the warehouse. Use it for a steady, known high concurrency.
- **Auto-scale:** MIN_CLUSTER_COUNT < MAX_CLUSTER_COUNT (for example 1 and 4). Snowflake starts and stops clusters as load changes. The scaling policy decides how eagerly.

| Scaling policy | Starts a new cluster | Shuts a cluster down | Choose it when |
|---|---|---|---|
| **Standard** (the default) | **As soon as a query queues**, or the system detects more queries than the running clusters can handle. Each extra cluster starts about 20 seconds after the previous one. | After 2 to 3 consecutive checks (one a minute) show the load fits on fewer clusters | **Performance** matters most: minimize queuing |
| **Economy** | Only if the system estimates the new cluster would stay busy for at least **6 minutes** | After 5 to 6 consecutive checks | **Cost** matters most: some queuing is acceptable |

This matches the guide's sample question: "cost matters more than queuing" → **Economy**.

### Auto-suspend and auto-resume

- `AUTO_SUSPEND` is in **seconds** of inactivity. A new warehouse created with SQL defaults to **600** (10 minutes). `0` or `NULL` means it never suspends.
- `AUTO_RESUME = TRUE` (the default) starts the warehouse when a query arrives.
- Suspending a warehouse **drops its local disk cache**. That's the trade-off:
  - **Ad-hoc and loading:** suspend quickly (around 60 seconds). The cache doesn't matter much.
  - **BI and reporting:** a longer auto-suspend (several minutes) keeps the cache warm for repeated dashboard queries.
- `INITIALLY_SUSPENDED = TRUE` creates the warehouse without starting it (and without billing).

### Configuring by use case (1.4.3)

| Use case | Typical configuration |
|---|---|
| **Ad-hoc queries** (analysts, data science) | Small to medium size, short auto-suspend, auto-resume on. Separate from production pipelines so a bad query can't slow them down. Query Acceleration (Day 3) can help unpredictable large scans. |
| **Data loading** | Usually **small** (XS to M). Load speed depends on the **number and size of files** (aim for 100 to 250 MB compressed), more than on warehouse size. A bigger warehouse only helps if there are many files to load in parallel. Its own warehouse, short auto-suspend. Snowpipe is serverless and needs no warehouse. |
| **BI and reporting** | **Multi-cluster** (auto-scale) for many concurrent dashboard users, Standard policy if users notice queuing, and a longer auto-suspend to keep the cache warm. |

### Best practices for workloads (1.4.4.4)

- **Different teams or workloads → different warehouses.** Isolation stops one team's heavy jobs from queuing another's, and makes cost attribution simple (credits are reported per warehouse).
- **High concurrency → scale out** (multi-cluster).
- **Complex queries → scale up** (bigger size), and check Query Profile for spilling.
- Use **resource monitors** (Day 5) to cap credits per warehouse.
- Useful parameters:
  - `STATEMENT_TIMEOUT_IN_SECONDS`: cancel queries that run too long (default 2 days).
  - `STATEMENT_QUEUED_TIMEOUT_IN_SECONDS`: cancel queries that wait in the queue too long (default 0, which means never).
  - `MAX_CONCURRENCY_LEVEL`: how many queries a cluster runs at once before queuing (default 8).

### Privileges on a warehouse (preview of Day 4)

| Privilege | Allows |
|---|---|
| **USAGE** | Running queries on it (and resuming it through auto-resume) |
| **OPERATE** | Starting, suspending and resuming it, and aborting its queries |
| **MODIFY** | Changing properties, such as the size |
| **MONITOR** | Seeing its queries and usage |
| **OWNERSHIP** | Everything, including dropping it |

Creating a warehouse needs the account-level **CREATE WAREHOUSE** privilege, which **SYSADMIN** has.

---

## 1.6 AI/ML and application development

### Snowflake Notebooks (1.6.1)
- Built into **Snowsight**. Cells can be **Python, SQL or Markdown**.
- A cell can use another cell's result: in Python, `cell1.to_pandas()`; in SQL, `{{variable}}` refers to a Python variable.
- A notebook is a **schema-level object**, owned by a role and governed by RBAC like any other object.
- Two runtimes: the **warehouse runtime** (runs on a virtual warehouse) and the **container runtime** (runs on Snowpark Container Services compute pools, including GPUs, for ML work).
- Notebooks can be synced with a **Git** repository and **scheduled** (they run as tasks).

### Streamlit in Snowflake (1.6.2)
- Python data apps built with the open-source Streamlit library, **hosted inside Snowflake**. Data never leaves Snowflake.
- A Streamlit app is a **schema-level object** (`CREATE STREAMLIT`). Its queries run on a **warehouse** you choose.
- Apps run with **owner's rights**: they use the privileges of the role that owns the app. Share an app by granting **USAGE** on it to other roles.
- Python packages come from the Snowflake Anaconda channel.

### Snowpark (1.6.3)
- A library and runtime for **Python, Java and Scala**.
- **DataFrame API:** you write DataFrame code; Snowpark turns it into **SQL** that runs on a **warehouse** (pushdown). Data doesn't move to the client.
- DataFrames are **lazy**: nothing runs until an action such as `collect()`, `show()`, `count()` or `save_as_table()`.
- You can also write:
  - **UDFs** (scalar: one row in, one value out), **UDTFs** (table functions: rows out), **UDAFs** (aggregates).
  - **Stored procedures**: procedural logic, also in SQL (Snowflake Scripting) or JavaScript.
  - **Vectorized (pandas) UDFs**, which process batches of rows for speed.
- Memory-hungry Snowpark work (ML training) → **Snowpark-optimized warehouse**.
- Third-party packages come from the **Anaconda** channel, at no extra licence cost.

### Snowflake Cortex (1.6.4)

Fully managed AI, running inside Snowflake so data stays under its governance.

**AI SQL functions (1.6.4.1).** Call large language models from SQL. Main ones:

| Function | Does |
|---|---|
| `AI_COMPLETE` | Sends a prompt to an LLM you choose (Snowflake-hosted models such as Llama, Mistral, Claude and others) and returns the generated text |
| `AI_CLASSIFY` | Sorts text (or images) into categories you give it |
| `AI_FILTER` | Returns TRUE or FALSE for a natural-language condition, for use in WHERE or JOIN |
| `AI_AGG` / `AI_SUMMARIZE_AGG` | Aggregate across many rows: an answer or a summary over a whole column |
| `AI_SENTIMENT` | Sentiment of text |
| `AI_EXTRACT` | Pulls specific information out of text or documents |
| `AI_TRANSLATE` | Translates between languages |
| `AI_EMBED` / `AI_SIMILARITY` | Vector embeddings and similarity scores |
| `AI_PARSE_DOCUMENT` | Extracts text and layout from documents (PDFs) in a stage |
| `AI_TRANSCRIBE` | Transcribes audio and video files |
| `AI_REDACT` | Removes personal information (PII) from text |

- The older, task-specific forms live in the `SNOWFLAKE.CORTEX` schema: `SNOWFLAKE.CORTEX.COMPLETE`, `SENTIMENT` (returns a score from -1 to 1), `SUMMARIZE`, `TRANSLATE`, `EXTRACT_ANSWER`. Either form can appear on the exam.
- **Billing:** per **token** processed, charged as AI Services credits. No warehouse size makes them cheaper, but the query that calls them still runs on a warehouse.
- **Access:** the **SNOWFLAKE.CORTEX_USER** database role. By default it is granted to PUBLIC, so every user has it unless an admin revokes it.
- Not every model is in every region. **Cross-region inference** (the account parameter `CORTEX_ENABLED_CROSS_REGION`) lets a request run in another region.

**Cortex Search (1.6.4.2).** A managed **search service** over **unstructured text**.
- **Hybrid search:** vector (semantic) plus keyword, with re-ranking.
- `CREATE CORTEX SEARCH SERVICE … ON <text column> ATTRIBUTES <filter columns> WAREHOUSE = … TARGET_LAG = … AS <query>`. It refreshes like a dynamic table.
- The main use is **RAG** (retrieval-augmented generation): find the relevant chunks, then pass them to AI_COMPLETE. Also enterprise search boxes.

**Cortex Analyst (1.6.4.3).** **Natural language → SQL** over **structured data**.
- Driven by a **semantic model** (a YAML file in a stage) or a **semantic view**, which maps business terms ("revenue", "region") to tables, columns and metrics.
- Used through a REST API, often from a Streamlit app.
- Search vs Analyst: **"documents, text, RAG" → Cortex Search**; **"business question over tables, text-to-SQL" → Cortex Analyst**. **Cortex Agents** (and Snowflake Intelligence) combine both.

### Snowflake ML (1.6.5)
- **ML Functions:** SQL-callable, no ML expertise needed. **FORECAST** (time series), **ANOMALY_DETECTION**, **TOP_INSIGHTS** (why a metric changed) and **CLASSIFICATION**.
- **Snowpark ML Modeling:** train scikit-learn, XGBoost and LightGBM models with Snowpark, with preprocessing pushed down.
- **Feature Store:** define, manage and reuse ML features. Feature views can refresh like dynamic tables.
- **Model Registry:** store, version and govern models as schema-level objects, then run inference in SQL or Python (`model!PREDICT(…)`).
- **Container runtime and ML Jobs:** run training on CPU or GPU compute pools.

---

## Ten facts to know cold by tonight
1. **Spill → bigger size (scale up). Queue → more clusters (scale out).**
2. Each size up **doubles** credits per hour: XS = 1, S = 2, M = 4, L = 8, XL = 16.
3. Billing is **per second**, with a **60-second minimum** on each resume.
4. **Multi-cluster warehouses need Enterprise.** Maximized: min = max. Auto-scale: min < max.
5. **Standard** scaling policy starts clusters as soon as queries queue; **Economy** waits until a cluster would be busy for **6 minutes**. Economy = cost first.
6. Suspending a warehouse **drops its local disk cache**. Short auto-suspend for loading and ad-hoc, longer for BI.
7. **Snowpark-optimized** = **16x memory** per node, for ML training and big UDFs. **Gen 2** = faster standard warehouse, especially for DML.
8. Loading speed depends on **file count and size** (100 to 250 MB compressed), so loading warehouses can stay small.
9. **Snowflake CLI** (`snow`) replaced SnowSQL and deploys Streamlit, Native Apps and Snowpark. Snowpark DataFrames are **lazy** and **push down** to SQL on a warehouse.
10. **Cortex Search = text and RAG. Cortex Analyst = natural language to SQL with a semantic model.** Cortex functions are billed **per token**, and access comes from **SNOWFLAKE.CORTEX_USER**.
