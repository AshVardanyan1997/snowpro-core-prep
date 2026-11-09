# Day 4 · Transformations and the Security Model

**Covers:** objectives 4.4 (Domain 4, 21% of the exam) and 2.1 (Domain 2, 20% of the exam) · **Time:** about 3 hours

**Written from the Snowflake documentation on Nov 9, 2026.** Each section ends with its sources. Where Snowflake changed something in 2025 or 2026, the notes say so, because the exam can lag the docs.

## What this lesson covered

These are the official COF-C03 domain and objective names, so you can look each one up in the [Snowflake documentation](https://docs.snowflake.com) for a second round.

**Domain 4.0: Performance Optimization, Querying, and Transformation**
- 4.4 Perform data transformation techniques
  - Using data: structured, semi-structured, unstructured
  - Aggregate functions
  - Applying SQL for query optimization
  - Window functions

**Domain 2.0: Account Management and Data Governance**
- 2.1 Explain Snowflake security model and principles
  - Role-based access control (RBAC), securable object hierarchy, discretionary access control (DAC)
  - Network policies
  - Authentication: MFA, federated authentication, SSO, OAuth, key-pair
  - System-defined roles; functional roles (account, database, custom); secondary roles
  - Account identifiers
  - Logging and tracing

---

| Block | Time | What to do |
|---|---|---|
| Notes, part 1 | 30 min | Read 4.4 below |
| Lab, part 1 | 30 min | Run sections 1 to 4 of [lab.sql](lab.sql) (JSON, FLATTEN, aggregates, windows) |
| Notes, part 2 | 40 min | Read 2.1 below. This is the heavier half: roles come up a lot on the exam |
| Lab, part 2 | 30 min | Run sections 5 to 8 of the lab (roles, secondary roles, managed access) |
| Practice | 40 min | Answer [practice-questions.md](practice-questions.md), then log every miss |

There's no review set today: you got all 8 repeat-miss questions right on Day 3.

---

## 4.4 Data transformation

### Structured, semi-structured and unstructured data (4.4.1)

| Kind | What it is | How you work with it |
|---|---|---|
| **Structured** | Rows and typed columns | Ordinary SQL. Also typed **structured types** such as `ARRAY(INTEGER)`, `OBJECT(city VARCHAR)` and `MAP(VARCHAR, VARCHAR)`, mainly for Iceberg tables |
| **Semi-structured** | JSON, Avro, ORC, Parquet, XML | Load into **VARIANT**, **OBJECT** or **ARRAY** columns; query with path notation and FLATTEN |
| **Unstructured** | Files such as PDFs, images, audio | Keep them in a **stage**; catalogue them with a **directory table**; access them with **file URLs**; process them with UDFs or Cortex AI functions |

### Semi-structured data types

| Type | Holds | Max size |
|---|---|---|
| **VARIANT** | A value of **any** type, including OBJECT and ARRAY | **128 MB** uncompressed |
| **OBJECT** | Key-value pairs: VARCHAR keys, VARIANT values (like a JSON object) | 128 MB |
| **ARRAY** | An ordered list of VARIANT values, **0-based** | 128 MB |

Building values: `PARSE_JSON('{"a":1}')` turns a JSON string into a VARIANT. `OBJECT_CONSTRUCT('a', 1, 'b', 2)` builds an OBJECT, and `ARRAY_CONSTRUCT(1, 2, 3)` builds an ARRAY. `TO_VARIANT(x)` or `x::VARIANT` converts any value.

**SQL NULL vs JSON null:** `PARSE_JSON(NULL)` is SQL NULL (the value is missing). `PARSE_JSON('null')` is a VARIANT **null value**, which is a real value.

The older limit you may see in study material is **16 MB** for VARIANT; since the 2025 size-limit change, the docs say 128 MB.

### Querying semi-structured data

Given a VARIANT column `src`:

| Syntax | Example | Notes |
|---|---|---|
| **Colon** for the first level | `src:dealership` | |
| **Dot** for nested levels | `src:salesperson.name` | Quote keys with spaces: `src:"company name"` |
| **Brackets** for keys | `src['salesperson']['name']` | |
| **Brackets** for array elements | `src:vehicle[0].price` | Arrays start at **0** |
| **Cast** with `::` | `src:vehicle[0].price::NUMBER` | Without a cast, a path returns **VARIANT**, so text shows in double quotes |
| **GET / GET_PATH** | `GET_PATH(src, 'vehicle[0].make')` | Same as path notation, as functions |

Exam traps:
- **Column names are case-insensitive, but key (element) names are case-sensitive.** `SRC:salesperson` works; `src:Salesperson` returns NULL if the key is `salesperson`.
- A path that doesn't exist returns **NULL**, not an error.

### FLATTEN

FLATTEN turns an array or object into **one row per element**. Use it with **LATERAL** so each output row is joined back to the row it came from:

```sql
SELECT s.src:customer_id::STRING AS customer,
       f.value:item::STRING      AS item,
       f.index                   AS position
FROM sales s,
     LATERAL FLATTEN(INPUT => s.src:items) f;
```

FLATTEN's output columns: **SEQ** (a number per input row), **KEY** (the key, for objects), **PATH**, **INDEX** (the position, for arrays), **VALUE** (the element itself) and **THIS** (the element being flattened).

Options:
- `RECURSIVE => TRUE` goes through **every** nested level, which is handy for listing all the keys in a document.
- `OUTER => TRUE` keeps the input row (with NULLs) even when the array is empty or missing. By default, such rows are dropped.

### Storing semi-structured data: when to extract columns

- If you don't yet know how you'll query it, **keep it in VARIANT**. For regular data with plain strings and numbers, VARIANT performs about as well as normal columns.
- **Extract into typed columns** when the data has **dates and timestamps** (stored as strings inside VARIANT, so slower and bigger), numbers stored as strings, or arrays you query often. Typed columns prune better.

### Unstructured data

- **Directory table:** a catalogue of the files on a stage (path, size, last modified, MD5, file URL). It's **part of the stage**, not a separate object. Turn it on with `DIRECTORY = (ENABLE = TRUE)` and query it with `SELECT * FROM DIRECTORY(@stage)`.
  - Refresh it **manually** with `ALTER STAGE … REFRESH` (small cloud services cost), or **automatically** with cloud event notifications (billed like Snowpipe).
- **Three kinds of URLs:**

| URL | Function | Who can use it | How long it lasts |
|---|---|---|---|
| **Scoped URL** | `BUILD_SCOPED_FILE_URL` | **Only the user who generated it** | Tied to the result cache, currently **24 hours** |
| **File URL** | `BUILD_STAGE_FILE_URL`, or the directory table's FILE_URL column | Roles with privileges on the stage (**READ** on an internal stage, **USAGE** on an external stage) | **Permanent** |
| **Pre-signed URL** | `GET_PRESIGNED_URL` | **Anyone** who has the URL, no Snowflake login needed | Set by an expiration time you choose |

- For URLs to work on an **internal stage**, it must use **server-side encryption** (`ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')`). The default client-side encryption doesn't allow URL access, and you can't change the encryption type after creating the stage.
- To share unstructured files with another account, share a **secure view** that returns scoped URLs.
- The **FILE** data type (`TO_FILE('@stage', 'path')`) represents a staged file; Cortex AI functions such as AI_PARSE_DOCUMENT accept it.

### Aggregate functions (4.4.2)

| Group | Functions |
|---|---|
| General | COUNT, COUNT_IF, SUM, AVG, MIN, MAX, **MEDIAN**, MODE, **MAX_BY**, **MIN_BY**, ANY_VALUE, LISTAGG |
| Semi-structured | **ARRAY_AGG**, OBJECT_AGG |
| **Estimation** (fast, approximate) | **APPROX_COUNT_DISTINCT** (or **HLL**, HyperLogLog) · **APPROX_TOP_K** (most frequent values) · **APPROX_PERCENTILE** (t-Digest) · **MINHASH** and APPROXIMATE_SIMILARITY (how similar two sets are) |
| Subtotals | **GROUPING**, GROUPING_ID |

Exam angles:
- "Count distinct visitors on a huge table, an estimate is fine, fast" → **APPROX_COUNT_DISTINCT** (HyperLogLog).
- "Most frequent values" → **APPROX_TOP_K**. "Similarity between two data sets" → **MINHASH**.
- An aggregate over several columns, such as `COUNT(x, y)`, **skips a row if any of those columns is NULL**. `COUNT(*)` counts every row.

**Subtotals with GROUP BY extensions:**
- `GROUP BY ROLLUP (state, city)`: one row per state and city, a **subtotal per state**, and a **grand total**. Order matters: put the higher level first. N columns give N + 1 grouping sets.
- `GROUP BY CUBE (a, b)`: subtotals for **every combination** of the columns, plus the grand total.
- `GROUP BY GROUPING SETS ((a), (b), ())`: exactly the groupings you list.
- Subtotal rows show **NULL** in the rolled-up columns. `GROUPING(col)` returns **1** when that NULL comes from the subtotal and **0** for a normal grouped row.

### Window functions (4.4.4)

An aggregate **collapses** rows into one per group. A window function **keeps every row** and adds a value computed over a "window" of related rows.

```sql
<function>(…) OVER (
    PARTITION BY <group columns>     -- which rows belong together
    ORDER BY <columns>               -- the order inside each partition
    <frame>                          -- which rows around the current row count
)
```

| Function | Gives |
|---|---|
| **ROW_NUMBER()** | 1, 2, 3, … with **no ties**: every row gets a different number |
| **RANK()** | Ties share a rank, then it **skips**: 1, 2, 3, 3, **5** |
| **DENSE_RANK()** | Ties share a rank, **no gaps**: 1, 2, 3, 3, **4** |
| **NTILE(n)** | Splits rows into n roughly equal buckets |
| **LAG(col, n)** / **LEAD(col, n)** | The value n rows before / after |
| **FIRST_VALUE** / **LAST_VALUE** / NTH_VALUE | A value from a position in the window |
| SUM, AVG, COUNT, … **OVER (…)** | Running or moving totals and averages |
| **RATIO_TO_REPORT** | Each row's share of the partition total |

**Frames:**
- **Cumulative** (running total): `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.
- **Sliding** (moving average): `ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING` (up to 7 rows).
- **ROWS** counts physical rows; **RANGE** uses ORDER BY values, so rows with the same value are included together. Snowflake recommends writing frames explicitly, and adding tie-breaker columns to ORDER BY so results don't change between runs.

**QUALIFY** filters on a window function result, the way HAVING filters on an aggregate. It runs after window functions, and saves you a subquery. The classic de-duplication:

```sql
SELECT *
FROM customers
QUALIFY ROW_NUMBER() OVER (PARTITION BY email ORDER BY updated_at DESC) = 1;
```

### Applying SQL for query optimization (4.4.3)

The habits that let Snowflake's pruning, caches and optimizer work for you (with Day 3's Query Profile to check them):
- **Select only the columns you need.** Storage is columnar, so unneeded columns are bytes you don't have to read. Avoid `SELECT *` on wide tables.
- **Filter early and on raw columns.** A filter like `WHERE order_date = '2026-01-01'` can prune micro-partitions; wrapping the column, as in `WHERE TO_CHAR(order_date) = …`, can't (you saw this in the Day 3 lab).
- **Use proper types:** DATE and TIMESTAMP, not strings, for dates. Extract frequently filtered VARIANT fields into typed columns.
- **Join on keys.** Missing or non-unique join conditions cause exploding joins. Query Insights flags joins with no condition.
- **UNION ALL instead of UNION** when you don't need duplicates removed. Remove DISTINCT and GROUP BY that don't change the result.
- **Use QUALIFY** instead of a subquery to filter on window functions.
- **Avoid LIKE with a leading wildcard** (`'%abc'`) on large tables unless search optimization is on.
- Only NOT NULL (and CHECK) constraints are **enforced** on standard tables. PRIMARY KEY, UNIQUE and FOREIGN KEY are informational, so they don't stop duplicates.

Sources: [Querying semi-structured data](https://docs.snowflake.com/en/user-guide/querying-semistructured) · [Semi-structured data types](https://docs.snowflake.com/en/sql-reference/data-types-semistructured) · [Supported semi-structured formats](https://docs.snowflake.com/en/user-guide/semistructured-data-formats) · [FLATTEN](https://docs.snowflake.com/en/sql-reference/functions/flatten) · [Table design considerations](https://docs.snowflake.com/en/en/user-guide/table-considerations) · [Introduction to unstructured data](https://docs.snowflake.com/en/user-guide/unstructured-intro) · [Directory tables](https://docs.snowflake.com/en/user-guide/data-load-dirtables-intro.html) · [Aggregate functions](https://docs.snowflake.com/en/sql-reference/functions-aggregation) · [GROUP BY ROLLUP](https://docs.snowflake.com/en/sql-reference/constructs/group-by-rollup) · [Window functions](https://docs.snowflake.com/en/user-guide/functions-window-using) · [RANK](https://docs.snowflake.com/en/sql-reference/functions/rank) · [QUALIFY](https://docs.snowflake.com/en/sql-reference/constructs/qualify) · [Query insights](https://docs.snowflake.com/en/user-guide/query-insights)

---

## 2.1 The security model

### Three access control models (2.1.1, 2.1.3)

| Model | Idea | In Snowflake |
|---|---|---|
| **DAC**, discretionary access control | Every object has an **owner**, and the owner decides who gets access | The owner role can grant privileges on its objects |
| **RBAC**, role-based access control | Privileges go to **roles**, and roles go to **users** | **The main model.** Users get access only through roles |
| UBAC, user-based access control | Privileges go straight to users | Considered only when **secondary roles are set to ALL**; meant for collaboration such as Streamlit development |

Snowflake combines DAC and RBAC.

**Ownership:**
- Every securable object has **exactly one owner role**, which holds the **OWNERSHIP** privilege. By default, that's the role that created it (the **primary** role of the session).
- Ownership moves with `GRANT OWNERSHIP ON … TO ROLE …`.
- **There is no super-user.** Even ACCOUNTADMIN can't use an object unless it has a privilege on it, directly or through the role hierarchy.

**To use an object you need USAGE on its database and schema too.** SELECT on a table without USAGE on the schema doesn't work.

### The securable object hierarchy (2.1.2)

```
ORGANIZATION
└── ACCOUNT ── users, roles, warehouses, databases, integrations, network policies, shares, …
    └── DATABASE
        └── SCHEMA ── tables, views, stages, file formats, functions, procedures, network rules, …
```

**Managed access schemas** (`CREATE SCHEMA … WITH MANAGED ACCESS`): object owners **lose** the ability to grant access. Only the **schema owner** or a role with **MANAGE GRANTS** can grant privileges on objects in it. This centralizes control.

**Future grants** (`GRANT SELECT ON FUTURE TABLES IN SCHEMA s TO ROLE r`) apply a privilege automatically to objects created later.

### System-defined roles (2.1.6)

```
            ACCOUNTADMIN
            /          \
     SECURITYADMIN    SYSADMIN
           |              |
       USERADMIN     (custom roles)
            \          /
              PUBLIC
```

| Role | What it does |
|---|---|
| **GLOBALORGADMIN** | Organization-level tasks (account lifecycle, organization usage). Exists only in the **organization account** |
| **ORGADMIN** | Organization-level tasks from a regular account. **Being phased out** in favour of GLOBALORGADMIN. Older exam questions use ORGADMIN |
| **ACCOUNTADMIN** | The **top role** in an account. Includes SYSADMIN and SECURITYADMIN |
| **SECURITYADMIN** | Has **MANAGE GRANTS**: can grant or revoke **any** privilege. Also manages users and roles. Inherits USERADMIN |
| **USERADMIN** | **CREATE USER** and **CREATE ROLE**. Manages the users and roles it owns |
| **SYSADMIN** | Creates **warehouses, databases** and other objects |
| **PUBLIC** | Granted **automatically to every user and role**. Anything PUBLIC owns or has access to is available to everyone |

ACCOUNTADMIN best practices (from the docs):
- Give it to **as few people as possible**, but to **at least two** users (so a lost password doesn't lock you out).
- Require **MFA** for everyone who has it.
- **Don't** use it to create objects, as a default role, or in automated scripts.

### Functional roles: account, database and custom roles (2.1.7)

- **Account roles** can hold privileges on any object in the account, and can be **activated** in a session (`USE ROLE`).
- **Database roles** are scoped to **one database**:
  - They **can't be activated** in a session. Grant them to an account role instead.
  - They can be granted to **shares**, so a provider can give different consumers different subsets of a shared database.
  - The database owner can create and manage them without account-level admins.
- **Custom roles:** created by USERADMIN (or any role with CREATE ROLE). A new role isn't granted to anyone.
  - **Best practice: grant every custom role hierarchy up to SYSADMIN.** Otherwise SYSADMIN (and even ACCOUNTADMIN) can't manage the objects those roles own.
  - **Access roles vs functional roles:** create access roles that hold object privileges (for example `SALES_READ`), grant them to functional roles that match jobs (for example `ANALYST`), and grant the functional roles to SYSADMIN.
- **Inheritance flows up:** a role gets every privilege of the roles granted to it. If role B is granted to role A, A can do everything B can. (Owning a role doesn't give you its privileges; being granted it does.)
- Also exist: **application roles** (Native Apps), **instance roles** (class instances such as ML models), service roles. Like database roles, these aren't activated directly.

### Primary and secondary roles (2.1.8)

- A session has **one primary role** and **any number of secondary roles**.
- At login: the user's **default role** becomes primary, and their **default secondary roles** are activated.
- `USE ROLE r` changes the primary role. `USE SECONDARY ROLES ALL` turns on every role granted to you; `USE SECONDARY ROLES NONE` turns them off; or name specific roles.
- **CREATE statements use only the primary role**, which also becomes the owner of the new object.
- **Everything else** (SELECT, INSERT, …) can be authorized by the primary **or any secondary** role. This lets you join tables from two databases that are granted to two different roles, without building a parent role.

### Network policies (2.1.4)

- Control **inbound** access to Snowflake (and, optionally, to internal stages). With no policy, users can connect from anywhere.
- A policy refers to **network rules**, which hold the actual identifiers (IPV4 or IPV6 ranges, AWS VPC endpoint IDs, Azure private link IDs). Rules are **schema-level** objects; they don't say allow or block, the policy's **allowed** or **blocked** list does.
  - The older `ALLOWED_IP_LIST` / `BLOCKED_IP_LIST` parameters still work, but the docs recommend network rules.
- **Blocked wins** when an address is on both lists. Allowing one IPv4 range already blocks all other IPv4 addresses.
- A policy does nothing until **activated** on the **account**, a **user** or a **security integration**. **The most specific wins: integration > user > account.** Only one policy can be active per account and per user.
- Created by **SECURITYADMIN** or higher (or the CREATE NETWORK POLICY privilege). Snowflake won't let you activate a policy that would block your own current IP.
- When a policy becomes active, users whose IP isn't allowed are **blocked from new logins and from running further queries**.

### Authentication (2.1.5)

| Method | What it is | Notes |
|---|---|---|
| **MFA** | Password plus a second factor (for example Duo) | **Required for all password users.** Snowflake has been retiring single-factor passwords through 2025–2026 (see below) |
| **Federated authentication / SSO** | An external **identity provider (IdP)** authenticates the user; Snowflake is the **service provider** | **SAML 2.0** (native support for **Okta** and **Microsoft Entra ID**; others such as Google Workspace, OneLogin and Ping via a custom app) or **OIDC** (preview in 2026). Set up with a **SAML2 security integration** |
| **OAuth** | A client app gets a **token** instead of a password | **Snowflake OAuth** (Snowflake issues the token; browser-based code flow, for interactive apps such as Tableau) or **External OAuth** (an external server such as Okta or Entra ID issues it; suits programmatic clients). Both set up with a **security integration** |
| **Key-pair** | The user's **public key** is stored in Snowflake; the client signs in with the **private key** | **At least 2048-bit RSA.** Set with `ALTER USER … ADD KEY PAIR` (recommended) or the `RSA_PUBLIC_KEY` property. Rotation: a user can have two keys (`RSA_PUBLIC_KEY` and `RSA_PUBLIC_KEY_2`), or use `ROTATE KEY PAIR`. Typical for **service users** and connectors |
| Programmatic access tokens (PATs) | Tokens that replace a password for tools that can't do MFA | Newer than the guide |
| Workload identity federation | Secretless, short-lived cloud credentials for services | Newer than the guide; the preferred method for SERVICE users |

**User types:** `TYPE = PERSON` (people: SSO, password + MFA, OAuth) and `TYPE = SERVICE` (applications: key-pair, External OAuth, workload identity; **no passwords**). `LEGACY_SERVICE` allowed passwords for old integrations and has been migrated to SERVICE in 2026.

**Single-factor password retirement (2025–2026):** MFA became mandatory for Snowsight password logins (from Sept 2025), then for new users (from May 2026), then for all human users, with LEGACY_SERVICE users moved to SERVICE (Aug–Oct 2026). Exam angle: "How should an automated ETL tool sign in?" → **key-pair** (or OAuth), never a single-factor password.

### Account identifiers (2.1.9)

You've practised this one, but the docs add detail:
- **Preferred:** `orgname-account_name`, for example `acme-sales_eu`. In URLs: `acme-sales_eu.snowflakecomputing.com`. Snowflake also accepts underscores replaced by hyphens (`acme-sales-eu`), which some tools such as Okta need.
- **In SQL** (for example when naming a share consumer), the same pair is written with a **period**: `acme.sales_eu`. Note the order: **organization first**, either way.
- **Legacy:** the **account locator**, such as `xy12345`, sometimes with region and cloud: `xy12345.us-east-2.aws`. It can't be changed.
- Functions: `CURRENT_ORGANIZATION_NAME()`, `CURRENT_ACCOUNT_NAME()` and `CURRENT_ACCOUNT()` (the locator).

### Logging and tracing (2.1.10)

- Telemetry from **stored procedures, UDFs** and other code goes into an **event table**, which follows the **OpenTelemetry** data model.
- The default event table is **SNOWFLAKE.TELEMETRY.EVENTS**, active unless you set another. Read it through **SNOWFLAKE.TELEMETRY.EVENTS_VIEW** (database role EVENTS_VIEWER) or manage it with EVENTS_ADMIN.
- Custom event table: `CREATE EVENT TABLE …` (no columns needed), then `ALTER ACCOUNT SET EVENT_TABLE = …` (or on a database, Enterprise only, which overrides the account one).
- What gets captured is set by parameters:
  - **LOG_LEVEL**: DEBUG, INFO, WARN, ERROR, FATAL, **OFF** (the default).
  - **TRACE_LEVEL**: ALWAYS, ON_EVENT, OFF.
  - **METRIC_LEVEL**: ALL, NONE.
  - Settable on the account, database, schema, procedure or function, and session. The lower level wins inside each hierarchy; if set in both the object and session hierarchies, **the more verbose level wins**.
- Collecting telemetry costs credits.

Sources: [Overview of access control](https://docs.snowflake.com/en/user-guide/security-access-control-overview) · [Access control best practices](https://docs.snowflake.com/en/user-guide/security-access-control-considerations) · [USE SECONDARY ROLES](https://docs.snowflake.com/en/sql-reference/sql/use-secondary-roles) · [Network policies](https://docs.snowflake.com/en/user-guide/network-policies) · [Overview of authentication](https://docs.snowflake.com/en/user-guide/security-authentication-overview) · [Deprecation of single-factor passwords](https://docs.snowflake.com/en/user-guide/security-mfa-rollout) · [Federated authentication and SSO](https://docs.snowflake.com/en/user-guide/admin-security-fed-auth-overview) · [Introduction to OAuth](https://docs.snowflake.com/en/user-guide/oauth-intro) · [Key-pair authentication](https://docs.snowflake.com/en/user-guide/key-pair-auth) · [Account identifiers](https://docs.snowflake.com/en/user-guide/admin-account-identifier) · [Event table overview](https://docs.snowflake.com/en/developer-guide/logging-tracing/event-table-setting-up) · [Telemetry levels](https://docs.snowflake.com/en/developer-guide/logging-tracing/telemetry-levels)

---

## Ten facts to know cold by tonight
1. **VARIANT** holds anything (up to **128 MB**). Paths: `col:key.sub[0]::TYPE`. **Key names are case-sensitive**; column names aren't.
2. **LATERAL FLATTEN** = one row per array element. Columns: VALUE, INDEX, KEY, PATH, SEQ, THIS. `OUTER => TRUE` keeps empty rows; `RECURSIVE => TRUE` goes all the way down.
3. **Scoped URL** = only the generating user, 24 h. **File URL** = permanent, needs stage privileges. **Pre-signed URL** = anyone, expires. Internal stages need **SNOWFLAKE_SSE** for URLs.
4. **APPROX_COUNT_DISTINCT** (HLL) for fast distinct counts; **APPROX_TOP_K** for frequent values; **ROLLUP** = subtotals + grand total; **GROUPING()** spots subtotal NULLs.
5. **ROW_NUMBER** never ties; **RANK** skips after ties (1, 1, 3); **DENSE_RANK** doesn't (1, 1, 2). **QUALIFY** filters on window functions.
6. **RBAC + DAC:** privileges → roles → users; every object has **one owner role**; there's no super-user. Using an object also needs **USAGE** on its database and schema.
7. **USERADMIN** creates users and roles; **SECURITYADMIN** manages all grants (MANAGE GRANTS); **SYSADMIN** creates warehouses and databases; **ACCOUNTADMIN** sits on top; **PUBLIC** goes to everyone. **Grant custom roles to SYSADMIN.**
8. **Database roles** can't be activated; grant them to account roles or shares. **Secondary roles** authorize everything except **CREATE**, which uses the primary role.
9. **Network policies:** rules on allowed/blocked lists; **blocked wins**; **user beats account** (and integration beats user).
10. **SSO** = SAML 2.0 IdP (Okta, Entra ID); **OAuth** = tokens (Snowflake or External); **key-pair** = 2048-bit RSA, for services, two keys for rotation; MFA required for passwords. **Event tables** hold logs and traces; LOG_LEVEL defaults to OFF.
