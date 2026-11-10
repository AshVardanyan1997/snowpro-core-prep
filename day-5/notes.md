# Day 5 · Governance, Cost Monitoring, and Data Loading

**Covers:** objectives 2.2 and 2.3 (Domain 2, 20% of the exam) and 3.1 (Domain 3, 18% of the exam) · **Time:** about 3 hours

**Written from the Snowflake documentation on Nov 10, 2026,** and rewritten the same day as a story with worked scenarios instead of a list of rules. Each section ends with its sources. Where Snowflake changed something recently, the notes say so, because the exam can lag the docs.

## How to read this lesson

Every topic follows the same company through a real problem. Read each one as a story: what went wrong, what the team built, and what they saw when they ran it. Don't try to memorize as you read. At the end of each part there's a short "What to keep" box with only the facts the exam actually tests. That's the part to learn.

The lesson has three parts. **Take a break after each one.**

- **Part 1:** Protecting and governing data (2.2). The longest part, about 60 minutes.
- **Part 2:** Watching the bill (2.3). About 25 minutes.
- **Part 3:** Getting files in and out (3.1). About 40 minutes.

## What this lesson covers

These are the official COF-C03 objective names.

- **2.2 Define data governance features and how they are used:** data masking (row-level and column-level security), object tagging, privacy policies, Trust Center, encryption key management, alerts, notifications, data replication and failover, data lineage.
- **2.3 Explain monitoring and cost management:** resource monitors, calculating virtual warehouse credit usage, the ACCOUNT_USAGE schema.
- **3.1 Perform data loading and unloading:** file formats; stages (internal, external, server-side encryption, directory tables); the COPY INTO command; error handling options.

| Block | Time | What to do |
|---|---|---|
| Part 1 | 60 min | Read, then run lab sections 1 to 5 ([lab.sql](lab.sql)) |
| Break | 10 min | |
| Part 2 | 25 min | Read, then run lab section 6 |
| Part 3 | 40 min | Read, then run lab sections 7 to 10 |
| Practice | 40 min | Answer [practice-questions.md](practice-questions.md), then log every miss |

---

## Meet the company

**Sevan Coffee** sells coffee online across Armenia, Georgia and Germany. Everything runs on one Snowflake account (Enterprise edition). The main table is:

```
CUSTOMERS (customer_id, name, email, phone, country, segment, balance)
```

Three groups use the data:

- **The support team** needs to look up customers, but shouldn't see full emails or phone numbers.
- **The country managers** (one in Yerevan, one in Tbilisi, one in Berlin) should see only their own country's customers.
- **The marketing analysts** want statistics: how many customers, average spend per country. They don't need to see any single person.

You've just joined as the data engineer. Your manager hands you the to-do list below, and each item turns out to be one exam topic.

---

# Part 1 · Protecting and governing data (2.2)

## 1. "Support must not see full emails": masking policies

**The problem.** The support team queries `CUSTOMERS` all day. Their tickets need the customer's name and the email domain (to tell gmail from a company address), but not the full email. The obvious fix, a second table with masked emails, means two copies to keep in sync, and someone will eventually query the wrong one.

**What Snowflake offers.** A **masking policy** is a small function you write once and attach to a column. Every time anyone queries that column, Snowflake runs the function on the way out and returns whatever the function returns. The table on disk is never changed. There is one table and one copy of the data, and what you see depends on who you are.

You write it like this:

```sql
CREATE MASKING POLICY email_mask AS (val STRING) RETURNS STRING ->
  CASE
    WHEN IS_ROLE_IN_SESSION('PII_READER') THEN val          -- trusted roles see it all
    ELSE REGEXP_REPLACE(val, '.+@', '*****@')               -- everyone else: *****@gmail.com
  END;

ALTER TABLE customers MODIFY COLUMN email SET MASKING POLICY email_mask;
```

**What happens next.** Anna from support runs `SELECT name, email FROM customers`. She gets `Lilit Petrosyan | *****@gmail.com`. You run the same query with the PII_READER role and see `lilit.p@gmail.com`. Same table, same query, two answers.

Now Anna runs `SELECT COUNT(*) FROM customers WHERE email = 'lilit.p@gmail.com'`, and gets **1**. The filter ran on the real value, because masking only changes what's *returned*, not what's *stored*. (This is why masking hides data from eyes, not from clever queries. That's acceptable for support staff, but it's the reason privacy policies exist for analysts, in section 4.)

**A trap with role functions.** Your first draft used `CURRENT_ROLE() = 'PII_READER'`. Then the support lead, whose role SUPPORT_LEAD *inherits* PII_READER, complained that they still saw stars. `CURRENT_ROLE()` returns only the one role that's active right now. `IS_ROLE_IN_SESSION('PII_READER')` asks "does this session have PII_READER, directly or through the hierarchy?", which is nearly always what you mean. The exam likes this difference.

**Two more things you discover.**

- You try to attach a second policy to `email` and get an error. **A column can have only one masking policy.**
- You expected the table owner (SYSADMIN) to see everything. It doesn't. **The policy decides, not ownership.** That's the point: the security team can protect a column without trusting every table owner. Attaching or removing a policy needs the **APPLY** privilege on it, so the security team can keep that power to itself (called **centralized** management).

> **What to keep**
> - A masking policy is column-level security, applied **at query time**. The stored data never changes.
> - It's a **schema-level object**, works on tables and views, needs **Enterprise** edition, and a column can have **only one**.
> - `IS_ROLE_IN_SESSION` respects the role hierarchy. `CURRENT_ROLE` sees only the active role.

## 2. "Each country manager sees only their country": row access policies

**The problem.** The Yerevan manager must see Armenian customers only. You could build three views, one per country, but next year there will be eight countries, and someone will query the base table directly anyway.

**What Snowflake offers.** A **row access policy** is attached to a table and returns TRUE or FALSE **for each row**. Rows that get FALSE simply don't exist for that user. Instead of hard-coding countries in the policy, you keep a small **mapping table** that says which role may see which country:

```sql
CREATE TABLE country_access (role_name STRING, country STRING);
INSERT INTO country_access VALUES
  ('MANAGER_AM', 'AM'), ('MANAGER_GE', 'GE'), ('MANAGER_DE', 'DE');

CREATE ROW ACCESS POLICY country_rap AS (c STRING) RETURNS BOOLEAN ->
  IS_ROLE_IN_SESSION('DATA_ADMIN')                 -- admins see every row
  OR EXISTS (SELECT 1 FROM country_access m
             WHERE m.role_name = CURRENT_ROLE() AND m.country = c);

ALTER TABLE customers ADD ROW ACCESS POLICY country_rap ON (country);
```

**What happens next.** The Yerevan manager runs `SELECT country, COUNT(*) FROM customers GROUP BY country` and sees one line: `AM | 41,200`. Berlin runs the same query and sees `DE | 18,900`. When Sevan opens in France, you insert one row into `country_access`. The policy doesn't change.

Notice that the managers can't read `country_access` themselves, yet the policy still works. **The policy body runs with the policy owner's privileges**, not the querying user's.

**Both policies at once.** Anna from support also has a country restriction. When she queries, Snowflake **first** removes the rows she can't see (row access policy), **then** masks the emails in the rows that are left (masking policy). Row access first, masking second. That order is a favourite exam question.

**What row access policies don't do.** They filter SELECT, and they limit which rows UPDATE, DELETE and MERGE can touch. They don't block INSERT. Anna could insert a German customer she then can't see.

**Sharing gotcha.** Later Sevan shares this table with a partner company's Snowflake account. Inside the partner's account, `CURRENT_ROLE()` returns NULL, because Sevan's roles don't exist there. Policies on shared tables use `CURRENT_ACCOUNT()` or database roles instead.

> **What to keep**
> - A row access policy is row-level security. It returns BOOLEAN per row. It's schema-level and needs **Enterprise**.
> - **Row access is evaluated before masking.**
> - Mapping tables keep policies short. The body runs as the **policy owner**.

## 3. "Find every PII column, and mask them all": tags

**The problem.** Sevan now has 400 tables. Your manager asks: "Which columns hold personal data? And can we mask all of them without writing 400 ALTER statements?"

**What Snowflake offers.** A **tag** is a label you create once and stick on objects, with a string value:

```sql
CREATE TAG pii ALLOWED_VALUES 'email', 'phone', 'name';
ALTER TABLE customers MODIFY COLUMN phone SET TAG pii = 'phone';
```

That answers the first question: a query on **ACCOUNT_USAGE.TAG_REFERENCES** lists every object with the `pii` tag. You don't even have to tag everything by hand: **automatic classification** scans columns, recognizes things like emails and phone numbers, and applies Snowflake's system tags for you.

For the second question, you **attach a masking policy to the tag itself**:

```sql
ALTER TAG pii SET MASKING POLICY phone_mask;
```

Now every column tagged `pii` (with a matching data type) is masked, **including columns tagged next month**. This is **tag-based masking**: you govern by label instead of column by column.

**Tags flow downward.** You tag the whole `customers` table with `pii`, and every column of it inherits the tag. A tag on a database is inherited by its schemas and tables. With **tag propagation** (Enterprise), a tag can even follow the data to new objects, such as a view built on a tagged table or a table made with CTAS.

**Tags for money, too.** Finance wants to know what each team spends. You tag each warehouse with `cost_center = 'marketing'` or `'finance'`, then group the credit usage by tag. Same feature, different job.

> **What to keep**
> - A tag is a **schema-level object**. Values are **strings**. Up to **50 tags per object**. Setting one needs **APPLY TAG**.
> - Tags are **inherited** down the hierarchy. **Tag-based masking** protects every tagged column, present and future.
> - Two main uses: **finding sensitive data** and **cost attribution**.

## 4. "Marketing wants statistics, not people": privacy policies

**The problem.** The marketing analysts want average spend by country. But what if one of them filters `WHERE city = 'Dilijan' AND age = 34` and the "average" is for exactly one person? That's a personal fact dressed up as a statistic. Masking can't stop this, because the analyst never asked for the email.

**Aggregation policy.** You attach an **aggregation policy** to the table:

```sql
CREATE AGGREGATION POLICY min_group_10 AS () RETURNS AGGREGATION_CONSTRAINT ->
  AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 10);
ALTER TABLE customers SET AGGREGATION POLICY min_group_10;
```

Now:
- `SELECT * FROM customers` **fails**. The analysts must aggregate.
- `SELECT country, AVG(balance) FROM customers GROUP BY country` works, since every country has thousands of rows.
- If they group so finely that some groups have fewer than 10 rows, those small groups are **folded together into one "remainder" group** with a NULL key, so no tiny group can be seen on its own.

**Projection policy.** Another case: marketing wants to match Sevan's customers against a partner's mailing list *by email*, but must never see an email. A **projection policy** on the `email` column means it **can't appear in the SELECT output**, yet can still be used in `WHERE` and `JOIN`. They get "8,412 customers matched" without a single address.

**Differential privacy.** The strongest option. A **privacy policy** makes Snowflake add a small amount of random **noise** to aggregate results, and gives each analyst a **privacy budget**. Repeating slightly different queries to cancel out the noise uses up the budget. Results stay accurate enough for trends, and no single person can be worked out from them.

> **What to keep**
> - **Aggregation policy:** must aggregate, with a minimum group size. Small groups merge into a remainder group.
> - **Projection policy:** the column can't be in the output, but can be used to filter or join.
> - **Differential privacy:** noise plus a privacy budget. All of these need Enterprise.

## 5. "Are we configured safely?": the Trust Center

**The problem.** Your manager asks whether the account follows security best practice. You could check dozens of settings by hand.

**What Snowflake offers.** The **Trust Center** page in Snowsight runs **scanners** against your account and lists **findings**. You open it and see:

- *High severity:* "3 users with passwords and no MFA." That's a **violation**: it stays on the list until you fix the setting.
- *Medium:* "No account-level network policy."
- Under a different tab, a **detection**: "Unusual login for user OLD_ETL_USER from a new country." That's a one-off event, not a setting.

These come from the **Security Essentials** scanner package. It's **on by default, free, and can't be turned off**. Your manager also wants Sevan measured against the industry **CIS Snowflake Benchmark**, so you enable the **CIS Benchmarks** package. You also enable **Threat Intelligence**, which looks for risky users and logins. Both of these are **off by default**, run daily once enabled, and **cost credits** (serverless compute).

To let the security team look without making them ACCOUNTADMIN, you grant them the **TRUST_CENTER_VIEWER** application role. TRUST_CENTER_ADMIN can also change scanner settings.

> **What to keep**
> - Trust Center = **scanners** grouped in **packages** producing **findings** (violations and detections).
> - **Security Essentials:** default, free, always on. **CIS Benchmarks** and **Threat Intelligence:** opt-in, cost credits.

## 6. "Who holds the keys?": encryption key management

**The question from a customer audit.** "Is our data encrypted, and who controls the keys?"

**The default answer.** Everything Sevan stores is **encrypted automatically** (AES-256 at rest, TLS in transit). You did nothing to set this up, and you can't turn it off.

The keys are arranged like a building's keys. A master key opens the room holding the floor keys, and each floor key opens the room holding that floor's door keys:

```
Root key (kept in a hardware security module)
  └─ Account master key (one per account)
       └─ Table master key (one per table)
            └─ File key (one per data file)
```

Each key encrypts the keys under it. Because of this, a single file key leaking exposes one file, not the account.

**Keys get old.** Snowflake **rotates keys automatically**: any key older than **30 days** is retired. A retired key is never used to encrypt new data, only to decrypt data it encrypted before. With **periodic rekeying** (**Enterprise**), data still protected by a key retired **more than a year ago** is re-encrypted with a fresh key, so no key stays in use forever. You turn it on with `ALTER ACCOUNT SET PERIODIC_DATA_REKEYING = TRUE`.

**"But we want our own key."** A bank customer insists that Sevan's data about them must be lockable by Sevan itself, even against Snowflake. That's **Tri-Secret Secure**: Sevan creates a key in its own cloud key service (AWS KMS, Azure Key Vault or Google Cloud KMS). Snowflake combines it with its own key to make a **composite master key**. If Sevan revokes its key, Snowflake can no longer decrypt the data. It needs **Business Critical** edition, so Sevan would have to upgrade.

> **What to keep**
> - Always on. Hierarchy: **root → account master → table master → file**.
> - Automatic rotation at **30 days**. **Periodic rekeying** of keys retired over a year ago needs **Enterprise**.
> - **Tri-Secret Secure** = customer key + Snowflake key, needs **Business Critical**.

## 7. "Tell me when something's wrong": alerts and notifications

**The problem.** Last Friday a bug set a customer's balance to 1,000,000 and nobody noticed until Monday. Your manager wants to be told when that happens.

**What Snowflake offers.** An **alert** is three things: a **condition** (a SQL query), an **action** (SQL to run if the query returns any rows), and a **schedule**.

```sql
CREATE ALERT huge_balance
  SCHEDULE = '60 MINUTE'
  IF (EXISTS (SELECT 1 FROM customers WHERE balance > 100000))
  THEN CALL SYSTEM$SEND_EMAIL('ops_email_int', 'data-team@sevan.am',
         'Balance alert', 'A customer balance is over 100,000.');
```

Every hour, Snowflake runs the query. If any row comes back, it sends the email.

You create it, wait an hour, and nothing happens. That's because **an alert is created suspended**, like a task. You run `ALTER ALERT huge_balance RESUME`, and now it runs. (To test it once without waiting, `EXECUTE ALERT huge_balance`.) Because you didn't name a warehouse, it runs on **serverless compute**. You could give it a warehouse instead. Creating alerts needs the **EXECUTE ALERT** privilege, which ACCOUNTADMIN grants.

**Where the message goes.** `'ops_email_int'` is a **notification integration**, an account object that says where messages may be sent. There are three kinds:
- **Email**, to verified addresses.
- **Queues**: Amazon SNS, Azure Event Grid, Google Cloud Pub/Sub, for other systems to pick up.
- **Webhooks**: Slack, Microsoft Teams, PagerDuty.

Alerts, tasks and budgets all use the same integrations.

> **What to keep**
> - Alert = **condition + action + schedule**. Created **suspended**, so RESUME it. Serverless or a warehouse.
> - Notifications go through a **notification integration**: email, queue, or webhook.

## 8. "What if the whole region goes down?": replication and failover

**The problem.** Sevan's account lives in AWS Frankfurt. The CEO asks what happens if Frankfurt has an outage on Black Friday.

**Step one: a copy.** You create a second Snowflake account in the same organization, in AWS Ireland. Then you create a **replication group** containing the `SALES` database and refresh it every 10 minutes (`REPLICATION_SCHEDULE = '10 MINUTE'`). Ireland now has a **secondary** copy of SALES that is never more than about 10 minutes behind. It's **read-only**: Irish users can query it, but nobody can write to it. All the objects in the group are refreshed together, so they're consistent with each other at the same point in time. **Database replication works on every edition**, including Standard.

**Step two: the outage.** Frankfurt goes down. Analysts can read the Irish copy, but the website needs to *write* orders. A read-only copy isn't enough. You need a **failover group**: the same idea as a replication group, but its secondary can be **promoted to primary**, becoming the writable one. Failover requires **Business Critical**. So does replicating **account objects**: users, roles, warehouses, resource monitors, network policies and integrations. Without them, the Irish account would have the data but none of the users or permissions.

**Step three: no code changes.** Applications connect to `sevan-frankfurt.snowflakecomputing.com`. After failover, they'd all need a new URL. **Client Redirect** gives you a **connection** URL that you point at whichever account is primary, so apps follow the failover automatically.

**What doesn't travel.** Temporary tables, external tables, hybrid tables, event tables, and databases created *from* a share you received.

> **What to keep**
> - **Replication group:** read-only secondaries. **Failover group:** a secondary can be promoted.
> - Databases and shares replicate on **any edition**. **Account objects and failover need Business Critical.**
> - Secondaries are read-only. All accounts must be in the **same organization**, but can be in different regions and clouds.

## 9. "Where did this number come from?": lineage and access history

**The problem.** The CFO's dashboard shows revenue of €2.1M, finance says €1.9M, and you need to know which tables fed the dashboard's table.

**What Snowflake offers.** Open the table in Snowsight and click **Lineage**. You see a graph: `RAW.ORDERS` → (a CTAS) → `STAGING.ORDERS_CLEAN` → (a MERGE) → `MART.REVENUE` → (a view) → `DASHBOARD.REVENUE_V`. You can also click a single column and follow it upstream. You find that `ORDERS_CLEAN` was rebuilt yesterday from the wrong source. Lineage is recorded by operations that move data: **CTAS, INSERT … SELECT, MERGE, UPDATE … FROM, COPY INTO, CLONE, views and materialized views**. It's kept for **one year**, and needs **Enterprise**.

**The audit question.** A month later, legal asks: "Who read the `salary` column in the HR table in October?" That's **ACCESS_HISTORY** in ACCOUNT_USAGE (Enterprise). It has one row per query, listing which tables and **columns** were read and written. If someone read salaries through a view, `direct_objects_accessed` shows the view and `base_objects_accessed` shows the HR table behind it. So a view doesn't hide the trail.

> **What to keep**
> - **Lineage** (Snowsight, Enterprise): upstream and downstream objects and columns, kept 1 year.
> - **ACCESS_HISTORY:** who read and wrote which columns; `base_objects_accessed` sees through views.

Sources for Part 1: [Dynamic Data Masking](https://docs.snowflake.com/en/user-guide/security-column-ddm-intro) · [Column-level security](https://docs.snowflake.com/en/user-guide/security-column-intro) · [Tag-based masking](https://docs.snowflake.com/en/user-guide/tag-based-masking-policies) · [Row access policies](https://docs.snowflake.com/en/user-guide/security-row-intro) · [Object tagging](https://docs.snowflake.com/en/user-guide/object-tagging/introduction) · [Privacy in Snowflake](https://docs.snowflake.com/en/guides-overview-privacy) · [Aggregation policies](https://docs.snowflake.com/en/user-guide/aggregation-policies) · [Projection policies](https://docs.snowflake.com/en/user-guide/projection-policies) · [Trust Center](https://docs.snowflake.com/en/user-guide/trust-center/overview) · [Encryption key management](https://docs.snowflake.com/en/user-guide/security-encryption-manage) · [Tri-Secret Secure](https://docs.snowflake.com/en/user-guide/security-encryption-tss) · [Alerts](https://docs.snowflake.com/en/user-guide/alerts) · [Snowflake notifications](https://docs.snowflake.com/en/user-guide/notifications/snowflake-notifications) · [Replication and failover](https://docs.snowflake.com/en/user-guide/account-replication-intro) · [Data lineage](https://docs.snowflake.com/en/user-guide/ui-snowsight-lineage) · [Access History](https://docs.snowflake.com/en/user-guide/access-history)

**Break time.** Run lab sections 1 to 5, then take 10 minutes away from the screen.

---

# Part 2 · Watching the bill (2.3)

## 10. "Last month cost three times the budget": resource monitors

**The story.** On the 1st of the month, finance forwards Sevan's Snowflake invoice with one line: "Why?" You dig in and find an analyst who started a 2X-Large warehouse for a one-off query, then went on holiday. The warehouse had auto-suspend switched off and ran for nine days.

**What you set up.** A **resource monitor** is a credit budget with consequences, for warehouses. Only **ACCOUNTADMIN** can create one. You give the analysts' warehouse its own monitor:

```sql
CREATE RESOURCE MONITOR analysts_rm
  WITH CREDIT_QUOTA = 300           -- credits per interval
       FREQUENCY = MONTHLY          -- the default; resets at 12:00 AM UTC
  TRIGGERS ON 75 PERCENT DO NOTIFY
           ON 100 PERCENT DO SUSPEND
           ON 110 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE analysts_wh SET RESOURCE_MONITOR = analysts_rm;
```

Follow the month through:
- **225 credits (75%):** you get an email. Nothing stops.
- **300 credits (100%):** `SUSPEND`. The warehouse accepts no new queries, but **queries already running are allowed to finish**. A long query can push usage past 300.
- **330 credits (110%):** `SUSPEND_IMMEDIATE`. Anything still running is **cancelled**. That's why the safety-net threshold is set **above 100%**, which is allowed.
- The warehouse stays suspended until the next month starts, you raise the quota, or you remove it from the monitor.

You also create an **account-level monitor** for the whole account, as a final ceiling. An account can have **only one** of those. A warehouse can belong to **only one** warehouse-level monitor, though one monitor can cover many warehouses.

**What a monitor can't watch.** A month later the bill is up again, and the monitor never fired. The extra spend was **Snowpipe** and **Automatic Clustering**, which run on **serverless** compute, not on your warehouses. Resource monitors only see warehouses. For serverless features you use a **budget**: a monthly spending limit for the account or for a chosen group of objects, serverless included. A budget **only notifies** (email, queue, webhook). It never suspends anything on its own.

> **What to keep**
> - Resource monitors: **ACCOUNTADMIN** creates them, **warehouses only**.
> - Actions: **Notify**, **Suspend** (running queries finish), **Suspend Immediately** (running queries cancelled). Thresholds can exceed 100%.
> - **One** account-level monitor. A warehouse is in **one** warehouse monitor. Default frequency monthly, reset at 12:00 AM UTC.
> - **Budgets** cover serverless, but only notify.

## 11. "How much will this cost?": calculating warehouse credits

**The rule, as a story.** A warehouse is like a taxi with a meter. The size sets the rate per hour, and each size **doubles** the previous one: X-Small 1 credit per hour, Small 2, Medium 4, Large 8, X-Large 16, and so on. The meter runs **per second while the warehouse is running**, whether or not it's doing work. Every time the taxi starts, there's a **minimum fare of 60 seconds**.

Work through these, then check the answers below them:

1. A **Large** warehouse runs a 15-minute job.
2. An **X-Small** warehouse resumes, runs a 20-second query, and you suspend it by hand right away.
3. The same X-Small resumes, runs a 20-second query, and **auto-suspend is 60 seconds**.
4. A **Medium multi-cluster** warehouse has **3 clusters** running for 2 hours.
5. On Tuesday, warehouses used **100** credits, and cloud services (logins, compiling queries, metadata) used **12**.

Answers:
1. 8 credits/hour × 0.25 hours = **2 credits**.
2. Only 20 seconds of work, but the 60-second minimum applies: **1/60 of a credit**.
3. 20 seconds of work plus 60 seconds of idle waiting before auto-suspend kicks in = **80 seconds**. Idle time costs money too. That's why a short auto-suspend matters.
4. Each cluster has its own meter: 4 × 3 clusters × 2 hours = **24 credits**.
5. Cloud services are free up to **10% of that day's warehouse credits** (10 here). Only the extra **2 credits** are billed.

> **What to keep**
> - Credits = **rate for the size × hours running × clusters running**. Per second, **60-second minimum** on each start.
> - Cloud services billed only above **10%** of daily warehouse credits.

## 12. "Show me the history": the ACCOUNT_USAGE schema

**The problem.** Finance wants a chart of credits per warehouse for the past six months. Security wants every failed login from the past four months, including logins by a contractor who left (and whose user you dropped).

**Two places to look.**
- Every database has an **INFORMATION_SCHEMA**. It's **real time**, but it only sees **that one database**, only **current** objects, and only short history (7 days to 6 months, depending on the view).
- The shared **SNOWFLAKE** database has **ACCOUNT_USAGE**. It sees **the whole account**, **includes dropped objects**, and keeps **one year** of history. The catch: its views are **45 minutes to 3 hours behind**.

So finance's six-month chart comes from `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY`. The contractor's logins come from `ACCOUNT_USAGE.LOGIN_HISTORY`: four months back, and the user is dropped, so INFORMATION_SCHEMA can't help. But if you want to see the credits of the query you ran **two minutes ago**, ACCOUNT_USAGE won't have it yet. Use the INFORMATION_SCHEMA table function instead.

**Who can read it.** By default only ACCOUNTADMIN. For finance you grant the SNOWFLAKE database role **USAGE_VIEWER**. For security, **SECURITY_VIEWER**. (The older way is granting IMPORTED PRIVILEGES on the SNOWFLAKE database, which gives everything.)

The views worth recognizing by name: **WAREHOUSE_METERING_HISTORY**, **METERING_DAILY_HISTORY** (includes the cloud services adjustment), **STORAGE_USAGE**, **QUERY_HISTORY**, **LOGIN_HISTORY**, **COPY_HISTORY**, **ACCESS_HISTORY**, **TAG_REFERENCES**, **POLICY_REFERENCES**.

> **What to keep**
> - **ACCOUNT_USAGE:** whole account, dropped objects included, **45 min to 3 h** latency, **1 year**.
> - **INFORMATION_SCHEMA:** one database, real time, 7 days to 6 months.

Sources for Part 2: [Resource monitors](https://docs.snowflake.com/en/user-guide/resource-monitors) · [Budgets](https://docs.snowflake.com/en/user-guide/budgets) · [Overview of warehouses](https://docs.snowflake.com/en/user-guide/warehouses-overview) · [Understanding compute cost](https://docs.snowflake.com/en/user-guide/cost-understanding-compute) · [Account Usage](https://docs.snowflake.com/en/sql-reference/account-usage)

**Break time.** Run lab section 6, then take a short break.

---

# Part 3 · Getting files in and out (3.1)

## 13. The daily orders file: file formats and stages

**The story.** Sevan's website produces one CSV file of orders every night: `orders_2026-11-09.csv.gz`. Your job is to get it into the `ORDERS` table. In Snowflake, loading always has the same two steps: **put the file somewhere Snowflake can reach (a stage), then run COPY INTO.**

**Step 1: describe the file.** The file has a header row, commas between fields, and the text `NULL` for missing values. Rather than repeating that in every command, you save it once as a **named file format**:

```sql
CREATE FILE FORMAT csv_orders
  TYPE = CSV  SKIP_HEADER = 1  FIELD_DELIMITER = ','  NULL_IF = ('NULL');
```

Snowflake can **load** CSV, JSON, Avro, ORC, Parquet and XML. It can **unload** only **CSV, JSON and Parquet**. One JSON tip: if the website sends one big `[ {...}, {...} ]` array, set `STRIP_OUTER_ARRAY = TRUE` so each element becomes its own row instead of one giant row.

**Step 2: choose a stage.** A stage is a folder Snowflake can read. You have three kinds of **internal** stage (inside Snowflake's storage) to choose from:

- **Your user stage, `@~`.** Every user has one, and only that user can use it. It's fine for a one-off file you're experimenting with, but your colleague can't load from it.
- **The table stage, `@%orders`.** Every table has one, meant for loading into that table only. It can't be shared through grants, and **COPY transformations aren't allowed** from it.
- **A named stage, `@orders_stage`.** You create it, and you can grant access to any role. This is **the recommended choice** for a regular pipeline.

```sql
CREATE STAGE orders_stage FILE_FORMAT = csv_orders;
```

The nightly job uploads with **PUT** from Snowflake CLI or a driver (PUT gzip-compresses the file by default). Later you can see what's there with **LIST**, download with **GET**, and delete with **REMOVE**.

**Plot twist: the files are already in S3.** The web team says the files already land in Sevan's S3 bucket. No need to copy them anywhere. You create an **external stage** pointing at the bucket. To avoid pasting AWS keys into SQL, you first ask an admin to create a **storage integration**, an account object holding an AWS IAM role that Snowflake assumes:

```sql
CREATE STAGE orders_s3
  URL = 's3://sevan-exports/orders/'
  STORAGE_INTEGRATION = s3_int
  FILE_FORMAT = csv_orders;
```

You can't PUT into an external stage. The web team writes to S3 with their own tools.

**Encryption on stages.** Files in internal stages are encrypted by default with `SNOWFLAKE_FULL` (encrypted on the client during PUT, plus on the server). Later, marketing wants to send **presigned URLs** so partners can download files without logging in. That only works if the stage uses `SNOWFLAKE_SSE` (server-side only). Since a stage's encryption type **can't be changed after creation**, you create a new stage with `ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')`. For an S3 external stage, encryption is the bucket's own, such as `AWS_SSE_S3` or `AWS_SSE_KMS`.

**Directory tables.** Marketing also wants a list of every file in the stage with its size and date. Turn on a **directory table** with `DIRECTORY = (ENABLE = TRUE)` (it's off by default), and query it with `SELECT * FROM DIRECTORY(@orders_stage)`. Refresh it with `ALTER STAGE … REFRESH`, or automatically through cloud event notifications for external stages.

**File size.** Months later, the web team switches to one 60 GB file per month, and loading becomes slow. Snowflake loads **files in parallel, and the number of parallel loads can't exceed the number of files**, so one huge file keeps most of the warehouse idle. Aim for files of about **100–250 MB compressed**. Millions of tiny files are the opposite problem: overhead per file.

> **What to keep**
> - `@~` user stage, `@%table` table stage (no transformations), `@name` named stage (recommended, grantable).
> - External stages: use a **storage integration**, not keys. No PUT.
> - Internal stage default encryption **SNOWFLAKE_FULL**. Presigned URLs need **SNOWFLAKE_SSE**, set at creation.
> - Load: CSV, JSON, Avro, ORC, Parquet, XML. **Unload: CSV, JSON, Parquet.** Files about 100–250 MB compressed.

## 14. Running the load: COPY INTO and its memory

**The first load.**

```sql
COPY INTO orders FROM @orders_stage;
```

It loads all 30 files in the stage. Tomorrow the nightly job adds file 31 and runs **the exact same command**. Will you get the first 30 files twice? **No.** For each table, Snowflake keeps **load metadata**: which files (by name and checksum) it has already loaded, for **64 days**. COPY quietly skips them and loads only file 31. That's what makes the same COPY safe to re-run.

**Choosing files.** You can name files (`FILES = ('orders_2026-11-09.csv.gz')`) or match them with a regex (`PATTERN = '.*2026-11.*'`).

**When you *want* to reload.** A bug in the target table forces you to load November's files again. Three ways to think about it:
- **`DELETE FROM orders` and COPY again:** the table is empty, but the load metadata still remembers the files, so COPY skips them all. **Nothing loads.**
- **`FORCE = TRUE`:** COPY ignores the metadata and loads everything. That's fine for an empty table, but on a table that still has the old rows it **duplicates** them.
- **`TRUNCATE TABLE orders`, then COPY:** TRUNCATE empties the table **and clears its load metadata**, so the files load once, cleanly. This is the study guide's own sample question, and the answer is TRUNCATE.

Files older than 64 days have an unknown load status, and COPY skips them by default. `LOAD_UNCERTAIN_FILES = TRUE` loads them anyway.

**Cleaning up.** Files pile up in the stage. `PURGE = TRUE` deletes each file after it loads successfully. If the delete fails, COPY doesn't report an error, so check the stage now and then.

**Reshaping while loading.** The file has 12 columns and the table needs 4, in a different order. A **transformation** picks columns by position:

```sql
COPY INTO orders (order_id, order_date, total)
FROM (SELECT $1, TO_DATE($5), $9 FROM @orders_stage);
```

(Remember, this doesn't work from a table stage.) For Parquet or JSON whose field names match your columns, `MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE` does the matching for you.

**History.** To see what loaded and when: `COPY_HISTORY` (the ACCOUNT_USAGE view, or the INFORMATION_SCHEMA table function for the last 14 days).

> **What to keep**
> - Load metadata, kept **64 days**, makes COPY **skip files already loaded**.
> - **FORCE** reloads and can duplicate. **TRUNCATE** clears the load metadata. **DELETE** doesn't.
> - **PURGE** removes loaded files. Transformations use `$1, $2, …` and don't work from table stages.

## 15. The night a bad file arrived: error handling

**The story.** One morning the dashboard is empty. Last night's file had one row with `price = 'N/A'` in a number column. COPY's default behavior is **`ON_ERROR = ABORT_STATEMENT`**: one bad row **stopped the whole load**, so none of the night's 31 files loaded, not even the 30 good ones.

You have four choices, depending on what the business wants:

| ON_ERROR | What last night would have looked like |
|---|---|
| **ABORT_STATEMENT** (default for COPY) | Nothing loaded. Safe, but the dashboard is empty |
| **CONTINUE** | All 31 files loaded, except the one bad row. Fastest recovery, but bad rows silently go missing |
| **SKIP_FILE** | 30 good files loaded, the whole bad file skipped |
| **SKIP_FILE_10** or **'SKIP_FILE_5%'** | Skip a file only if it has at least 10 bad rows (or 5% bad rows). Otherwise load its good rows |

Sevan picks `SKIP_FILE`, so a broken file is set aside for someone to look at, and the good files still load. That's also what **Snowpipe** does by default: its default is **SKIP_FILE**, not ABORT_STATEMENT. This is a classic exam trap.

**Checking before loading.** After that night, you add a step that runs **before** each load:

```sql
COPY INTO orders FROM @orders_stage VALIDATION_MODE = RETURN_ERRORS;
```

**VALIDATION_MODE loads nothing.** It only checks. `RETURN_ERRORS` lists every error in the files. `RETURN_10_ROWS` shows what the first 10 rows would look like after parsing. It can't be combined with a transformation.

And when a load with `CONTINUE` has already happened, `SELECT * FROM TABLE(VALIDATE(orders, JOB_ID => '_last'))` shows exactly which rows were rejected.

> **What to keep**
> - **ON_ERROR default: ABORT_STATEMENT for COPY, SKIP_FILE for Snowpipe.**
> - CONTINUE = skip bad rows. SKIP_FILE = skip bad files.
> - **VALIDATION_MODE** checks without loading.

## 16. Sending data out: unloading

**The story.** Sevan's accountants want last year's orders as files. Unloading is COPY in reverse: **table (or query) → stage → GET** (or the cloud's tools for an external stage).

```sql
COPY INTO @orders_stage/export/orders_
FROM (SELECT * FROM orders WHERE YEAR(order_date) = 2025)
FILE_FORMAT = (TYPE = CSV)
HEADER = TRUE;
```

You expected one file and find 140, named `orders_0_0_0.csv.gz`, `orders_0_1_0.csv.gz`, … That's the default behavior:
- Output is **split into many files** (`SINGLE = FALSE`), written in parallel, each up to **MAX_FILE_SIZE**, which defaults to **16 MB** (max 5 GB).
- Files are **compressed** by default: **gzip** for CSV and JSON, **Snappy** for Parquet.
- Without `HEADER = TRUE`, there would be no column names.

For one file, add `SINGLE = TRUE` (and maybe a bigger MAX_FILE_SIZE). To get a folder per month, use `PARTITION BY ('month=' || TO_CHAR(order_date, 'YYYY-MM'))`.

The data team prefers JSON, and the first try fails: **JSON can only be unloaded from a single VARIANT column.** Wrapping the row in `OBJECT_CONSTRUCT(*)` makes one:

```sql
COPY INTO @orders_stage/export/json/
FROM (SELECT OBJECT_CONSTRUCT(*) FROM orders)
FILE_FORMAT = (TYPE = JSON);
```

Finally, the accountant downloads the files with `GET @orders_stage/export/ file:///home/accountant/`. GET runs from Snowflake CLI, SnowSQL or a driver, not from a Snowsight worksheet.

> **What to keep**
> - Unload = COPY INTO a stage, then GET. Source can be a **query**.
> - Defaults: **multiple files**, **16 MB** each, **gzip** (CSV, JSON) or **Snappy** (Parquet), no header.
> - JSON needs a **VARIANT** column.

Sources for Part 3: [COPY INTO <table>](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table) · [Preparing your data files](https://docs.snowflake.com/en/user-guide/data-load-considerations-prepare) · [Choosing an internal stage](https://docs.snowflake.com/en/user-guide/data-load-local-file-system-create-stage) · [CREATE STAGE](https://docs.snowflake.com/en/sql-reference/sql/create-stage) · [TRUNCATE TABLE](https://docs.snowflake.com/en/sql-reference/sql/truncate-table) · [Overview of data unloading](https://docs.snowflake.com/en/user-guide/data-unload-overview) · [File formats for unloading](https://docs.snowflake.com/en/user-guide/data-unload-prepare) · [COPY INTO <location>](https://docs.snowflake.com/en/sql-reference/sql/copy-into-location)

Run lab sections 7 to 10 now. Section 8 replays the "bad file night" from section 15 with a real file.

---

## The whole day in one picture

| Sevan's problem | Snowflake feature | Edition |
|---|---|---|
| Support must not see emails | Masking policy | Enterprise |
| Managers see only their country | Row access policy | Enterprise |
| Find and protect every PII column | Tags + tag-based masking | Tags: all. Tag masking: Enterprise |
| Statistics without individuals | Aggregation, projection, differential privacy | Enterprise |
| "Are we configured safely?" | Trust Center | All |
| "We want our own key" | Tri-Secret Secure | Business Critical |
| "Tell me when it breaks" | Alert + notification integration | All |
| Copy of the data in another region | Replication group | All |
| Take over writes if a region dies | Failover group | Business Critical |
| Where did this number come from? | Lineage, ACCESS_HISTORY | Enterprise |
| Stop a runaway warehouse | Resource monitor | All |
| Track serverless spend | Budget | All |
| Six months of history | ACCOUNT_USAGE | All |
| A bad row in a nightly file | ON_ERROR, VALIDATION_MODE | All |
| Reload the same files | TRUNCATE, then COPY | All |
