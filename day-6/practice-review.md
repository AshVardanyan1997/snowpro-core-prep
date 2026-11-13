# Day 6 practice questions: review

Graded from commit `89e8e6d`, using the answers marked in parentheses in [practice-questions.md](practice-questions.md). Your "should be" notes match the answer key, and there's one miss you didn't flag (A1).

## Score

| Part | Score |
|---|---|
| A · Automated ingestion (3.2) | **9 / 12 (75%)** |
| B · Connectors and integrations (3.3) | **4 / 5 (80%)** |
| C · Data collaboration (5.1 to 5.3) | **14 / 15 (93%)** |
| **Total** | **27 / 32 (84%)**, one question under the 85% bar |

Domain 5 was strong: Time Travel, Fail-safe, cloning, who pays in a share, reader accounts, and listings were all right. The misses are in the pipeline tools (streams and task graphs) plus two "which parts does it have" questions.

## Misses and the concept behind each

| Q | You | Right | Concept | Notes section | Tracker |
|---|---|---|---|---|---|
| A1 | A | **B** | "Files land in S3" plus "**without a warehouse**" means Snowpipe with AUTO_INGEST: serverless, triggered by the bucket's event notification. A task on a warehouse could work, but it breaks the one condition the question states. | 1 | 3.2.1 |
| A7 | C | **B** | An UPDATE to a row that existed **before** the stream's offset shows as **two rows**: a DELETE (old values) and an INSERT (new values), both with ISUPDATE = TRUE. The lab may have misled you: order 9000001 was inserted **and** updated after the offset, so the stream showed only the net result, one INSERT with ISUPDATE = FALSE. Order 2 (an old row) showed the pair. | 3 | 3.2.3 |
| A10 | A, D | **B, C** | Only the **root** task has a schedule. Children use **AFTER**. All tasks in a graph must have the **same owner, database and schema**. Suspend the root before changing any task. | 4 | 3.2.4 |
| B2 | B, C | **A, C** | **RECORD_CONTENT** (the message) and **RECORD_METADATA** (topic, partition, offset, and the message key). There's no separate RECORD_KEY column: the key lives inside RECORD_METADATA. | 6 | 3.3.2 |
| C15 | A, E | **A, B** | Application package = **manifest file + setup script** (plus code and data). A storage integration has nothing to do with Native Apps. | 15 | 5.3.3 |

## Your questions from the notes

**"Did not really get the difference between append-only and insert-only."**
Both track only inserts. The difference is **which object they sit on**. Append-only streams are for normal Snowflake tables (and views, dynamic tables). Insert-only streams are for **external tables** and externally managed Iceberg tables, whose files live in your cloud bucket. Snowflake can see when a new file appears there, but it can't reliably track rows being removed from those files, so only inserts are offered. Rule of thumb: **external → insert-only**, everything else → standard or append-only.

**"Don't really remember the optimizer topic" (materialized views).**
A materialized view stores the result of a query on one table. "Query rewrite" means you **don't have to query the materialized view by name**. Say there's a materialized view `daily_sales_mv` with `SELECT order_date, SUM(amount) FROM orders GROUP BY order_date`. An analyst who has never heard of it writes that same aggregation directly against `orders`. The optimizer notices the materialized view already has the answer and reads it instead of scanning `orders`, so the query is faster without anyone changing their SQL. Dynamic tables never do this: you get the benefit only by querying the dynamic table itself.

**"Then why would people even need COPY over CLONE?"**
They do different jobs. **COPY INTO** loads **files** from a stage into a table, so it's how data gets into Snowflake in the first place. CLONE copies an object that's **already in Snowflake**. If you meant "a physical copy" (CREATE TABLE … AS SELECT): use CTAS when the new table should be **different**, such as filtered, reshaped or joined. Use CLONE when you want an **identical** copy instantly, like a test database or a snapshot before a risky change. Also, a clone only stays nearly free while both copies are mostly unchanged. As they drift apart, the changed micro-partitions are stored separately.

**"Internal stage is within Snowflake, external is a provider like Azure or AWS?"**
Yes, exactly. An **internal** stage is storage that Snowflake manages for you (you PUT files into it). An **external** stage is a pointer to **your own** bucket in AWS S3, Azure or Google Cloud Storage. Since the clone rule follows from that: cloning an external stage just copies the pointer, so its pipe can be cloned too. Internal stages and their files aren't cloned by default, so a pipe reading from one isn't either.

**"What is a database role, how is it different from an ordinary role, what's the use case?"**
An ordinary (account) role lives at the **account** level, can be granted to users, can be activated with USE ROLE, and can hold privileges on anything in the account. A **database role** lives **inside one database**, can only hold privileges on objects in **that** database, and **can't be activated directly**. You grant it to an account role, or to a share.
The main use case is **sharing**. Say Sevan shares a database with two schemas, SALES and FINANCE, with Ararat. Without database roles, Ararat's admin gets the whole share as one block (IMPORTED PRIVILEGES): any role they give it to sees everything. With database roles, Sevan creates `SALES_READER` and `FINANCE_READER` inside the shared database and grants both to the share. Ararat's admin then gives `SALES_READER` to the planners and `FINANCE_READER` only to their accountants. The provider defines the slices, and the consumer decides who gets which slice. A second use case is **delegating access inside one database**: the database owner manages its own roles without needing account-level role admin, and the roles travel with the database when it's cloned or replicated.

**"Can the consumer set up an unload task to save the shared data as CSV somewhere?"**
Yes. Anyone who can SELECT shared data can COPY it **into their own stage** (`COPY INTO @my_stage FROM sevan_sales.public.bean_sales_v`), or CREATE TABLE … AS SELECT it into their own database. The "no resharing" rule only blocks passing it on **through Snowflake sharing**. It's not copy protection. A provider who worries about this shares only what's needed (secure views with aggregated or filtered data), relies on the contract, or uses aggregation and projection policies or a **data clean room** so that raw rows never reach the consumer.

**"Replication recap: need to read one more time."** Day 5 section 8 is the full version. It's 5 minutes, and A13 on Day 5 was a replication miss, so it's worth doing.

## Pattern to watch

A1 and A10 are the "sibling" trap again: an answer that would work, or is true for a related thing (a task can load files; children in a graph do run on a schedule, just their root's). The fix is the same as last time: **underline the condition in the question** ("without a warehouse", "every task") and check each option against it.

## Before Mock 1

1. Reread notes sections 3 and 4 (streams and tasks), about 15 minutes, and Day 5 section 8 (replication).
2. Add the five misses to your error log.
3. Then do Mock 1 (100 questions, 115 minutes, timed) when you have a quiet two hours, and send me the score per domain.
