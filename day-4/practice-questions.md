# Day 4 Practice Questions

- **Part A: Transformations** (14 questions on objective 4.4).
- **Part B: Security model** (18 questions on objective 2.1).

32 questions, about 37 minutes at exam pace. Answer them after the notes and the lab. Mark your answers the same way as before. Answers and explanations are at the bottom. Cover them while you work, and add every miss to your error log.

---

## Part A · Transformations (4.4)

**A1.** A VARIANT column `src` holds `{"Customer": {"Name": "Ana"}}`. What does `SELECT src:customer.name FROM t` return?
A. "Ana"  B. Ana  (C.) NULL  D. An error, because the key doesn't exist

**A2.** What is the maximum size of a single VARIANT value, according to the current documentation?
A. 16 KB  B. 16 MB  (C.) 128 MB uncompressed  D. 1 GB

**A3.** Which expression returns the second element's `sku` as a string from the array `src:items`?
A. `src:items[2].sku::STRING`  (B. )`src:items[1].sku::STRING`  C. `src.items(1).sku`  D. `FLATTEN(src:items, 2)`

**A4.** Why is `LATERAL` used with `FLATTEN` in `FROM t, LATERAL FLATTEN(INPUT => t.src:items) f`?
(A.) So that each output row can refer to columns of the row it was flattened from  B. To make FLATTEN run on a larger warehouse  C. To sort the elements  D. To remove NULL elements

**A5.** Some orders have an empty `items` array, and you still want one row for each of them in the flattened output. Which option do you add?
A. `RECURSIVE => TRUE`  (B.) `OUTER => TRUE`  C. `MODE => 'ARRAY'`  D. `PATH => ''`

**A6.** Which FLATTEN output columns are real? (Choose two.)
(A.) VALUE  (B.) INDEX  C. ELEMENT_ID  D. PARENT_ROW

**A7.** You need a URL to a PDF on an internal stage that a partner without a Snowflake login can open for the next 10 minutes. Which function?
A. BUILD_SCOPED_FILE_URL  B. BUILD_STAGE_FILE_URL  (C.) GET_PRESIGNED_URL  D. RESULT_SCAN

**A8.** Which statements about scoped URLs are true? (Choose two.)
(A.) Only the user who generated the URL can use it  B. They never expire ( C.) Their lifetime is tied to the result cache (currently 24 hours)  D. Anyone with the link can open them

**A9.** File URLs on an internal stage return an error. The stage was created with default settings. What's the likely cause? -- should be A
A. The stage uses client-side encryption; URL access needs SNOWFLAKE_SSE  (B.) Directory tables only work on external stages  C. The warehouse is suspended  D. File URLs need Business Critical edition

**A10.** You need a fast, approximate count of distinct visitors in a 50-billion-row table. Which function?
A. COUNT(DISTINCT visitor_id)  (B.) APPROX_COUNT_DISTINCT(visitor_id)  C. APPROX_TOP_K(visitor_id)  D. MINHASH(visitor_id)

**A11.** `GROUP BY ROLLUP (region, city)` returns which rows? (Choose two.) --should be A and C
A. A subtotal row for each region  (B.) A subtotal row for each city across all regions  C. A grand total row  D. Only the detail rows

**A12.** Scores in descending order are 90, 85, 85, 80. What does DENSE_RANK return for the score 80?
(A.) 3  B. 4  C. 2  D. 5

**A13.** Which clause keeps only the latest row per customer, using a window function, without a subquery?
A. HAVING  (B.) QUALIFY  C. WHERE  D. GROUP BY

**A14.** Which practices help Snowflake prune micro-partitions? (Choose two.)
(A.) `WHERE order_date = '2026-01-01'` on a DATE column  B. `WHERE TO_CHAR(order_date, 'YYYY-MM-DD') = '2026-01-01'`  (C.) Storing dates as typed DATE columns instead of strings inside VARIANT  D. Using UNION instead of UNION ALL

---

## Part B · Security model (2.1)

**B1.** Which statement describes Snowflake's access control?
A. Privileges are granted directly to users only  (B.) Privileges are granted to roles, roles are granted to users, and each object has an owner role that can grant access  C. ACCOUNTADMIN can access any object without privileges  D. Access is controlled only by network policies

**B2.** Which system role should be used to create users and roles, following least privilege?
A. ACCOUNTADMIN  B. SECURITYADMIN  (C.) USERADMIN  D. SYSADMIN

**B3.** Which role can grant or revoke any privilege in the account, because it has MANAGE GRANTS? (Choose the most specific answer.)
A. USERADMIN  (B.) SECURITYADMIN  C. SYSADMIN  D. PUBLIC

**B4.** A team creates a custom role and builds objects with it, but SYSADMIN can't manage those objects. What was missed?
(A.) The custom role wasn't granted to SYSADMIN  B. The custom role wasn't granted to PUBLIC  C. MFA wasn't enabled  D. The objects weren't in a managed access schema

**B5.** Which statements about database roles are true? (Choose two.)--should be B and C
(A.) They can be activated with USE ROLE  (B.) They are scoped to a single database  C. They can be granted to shares  D. They can hold privileges on objects in any database

**B6.** A user's primary role is ANALYST, and `USE SECONDARY ROLES ALL` is active. Which statement is true?
A. CREATE TABLE is authorized by any of the user's roles  (B.) CREATE TABLE is authorized only by the primary role, which also owns the new table  C. Secondary roles can only be used for SELECT on views  D. Secondary roles replace the primary role

**B7.** In a managed access schema, who can grant SELECT on a table in that schema? (Choose two.)
A. The table's owner role  (B.) The schema owner  (C.) A role with MANAGE GRANTS  D. Any role with USAGE on the schema

**B8.** A role has SELECT on table `db.s.t` but queries fail with "does not exist or not authorized". What is most likely missing?
(A.) USAGE on the database and schema  B. OWNERSHIP of the table  C. MONITOR on the warehouse  D. The table must be secure

**B9.** Which role is automatically granted to every user and every role?
A. SYSADMIN  B. USERADMIN ( C.) PUBLIC  D. ORGADMIN

**B10.** Which are documented best practices for ACCOUNTADMIN? (Choose two.)
(A.) Assign it to at least two users  B. Make it every admin's default role  (C.) Require MFA for users who have it  D. Use it to run automated ETL scripts

**B11.** A network policy is active on the account allowing 10.0.0.0/8, and a different policy on user JO allows only 192.168.1.0/24. JO connects from 10.1.2.3. What happens? ---should be B
(A.) Allowed, because the account policy allows it  B. Blocked, because the user-level policy takes precedence  C. Allowed, because both policies are combined  D. Blocked, because user policies can't be set

**B12.** An IP address is in a network rule on the allowed list and also in a rule on the blocked list of the same policy. What happens?
A. It's allowed  (B.) It's blocked  C. The policy fails to activate  D. The first rule created wins

**B13.** Which statements about network rules are true? (Choose two.)
(A.) They are schema-level objects  (B.) They contain identifiers such as IPv4 ranges or VPC endpoint IDs  C. They decide on their own whether to allow or block  D. They must be activated on users directly

**B14.** A company wants employees to sign in to Snowsight through Okta. What should it configure?
A. Key-pair authentication  (B.) Federated authentication (SSO) with a SAML2 security integration  C. A network rule  D. External functions

**B15.** Which statements about key-pair authentication are true? (Choose two.)
(A.) It requires at least a 2048-bit RSA key pair  (B. )A user can have two public keys at once, to allow rotation  C. The private key is stored in Snowflake  D. It is only available on Business Critical

**B16.** How should a nightly ETL service account authenticate, following Snowflake's guidance?
A. A single-factor password  (B.) Key-pair (or OAuth / workload identity) with TYPE = SERVICE  C. Username plus Duo push  D. Sharing an admin's password

**B17.** What is the difference between Snowflake OAuth and External OAuth?
(A.) Snowflake OAuth uses Snowflake to issue tokens; External OAuth uses an external authorization server such as Okta or Entra ID  B. External OAuth is only for Snowsight  C. Snowflake OAuth doesn't need a security integration  D. There is no difference

**B18.** Where do logs and traces from stored procedures and UDFs go by default, and what controls how much is captured?
A. QUERY_HISTORY; STATEMENT_TIMEOUT_IN_SECONDS  (B.) The event table SNOWFLAKE.TELEMETRY.EVENTS; LOG_LEVEL and TRACE_LEVEL  C. A stage; AUTO_SUSPEND  D. ACCESS_HISTORY; MAX_CONCURRENCY_LEVEL

---

## Answers

### Part A
| Q | Answer | Why |
|---|---|---|
| A1 | C | **Key names are case-sensitive.** `customer` doesn't match `Customer`, so the path returns NULL (missing paths never error). |
| A2 | C | 128 MB uncompressed in the current docs. Older material says 16 MB. |
| A3 | B | Arrays are **0-based**, so the second element is `[1]`. |
| A4 | A | LATERAL lets the table function see the current row's columns, so each element row is joined back to its source row. |
| A5 | B | `OUTER => TRUE` keeps rows whose array is empty or missing (with NULLs). RECURSIVE goes through nested levels. |
| A6 | A, B | Output columns: SEQ, KEY, PATH, INDEX, VALUE, THIS. |
| A7 | C | Pre-signed URLs work for anyone with the link, until they expire. Scoped URLs only work for the user who made them; file URLs need Snowflake privileges. |
| A8 | A, C | Scoped URLs are for the generating user only and last as long as the result cache (24 hours). |
| A9 | A | Internal stages default to client-side encryption, which blocks URL access. Create the stage with `ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')`. |
| A10 | B | APPROX_COUNT_DISTINCT uses HyperLogLog: fast, low memory, close estimate. APPROX_TOP_K finds frequent values; MINHASH estimates similarity. |
| A11 | A, C | ROLLUP gives detail rows, a subtotal per higher-level column (region) and a grand total. Per-city-across-regions subtotals come from CUBE. |
| A12 | A | DENSE_RANK: 1, 2, 2, **3**. RANK would give 4. |
| A13 | B | QUALIFY filters on window function results, as HAVING does on aggregates. |
| A14 | A, C | Filtering a raw, typed column lets min/max metadata prune. Wrapping it in a function or keeping dates as strings in VARIANT prevents that. |

### Part B
| Q | Answer | Why |
|---|---|---|
| B1 | B | RBAC (privileges → roles → users) plus DAC (each object's owner can grant). There's no super-user. |
| B2 | C | USERADMIN has CREATE USER and CREATE ROLE. SECURITYADMIN can too (it inherits USERADMIN) but has more power than needed. |
| B3 | B | SECURITYADMIN holds MANAGE GRANTS. |
| B4 | A | Custom role hierarchies should roll up to SYSADMIN; otherwise system admins can't manage those objects. |
| B5 | B, C | Database roles are scoped to one database, can't be activated directly (grant them to account roles), and can be granted to shares. |
| B6 | B | CREATE uses only the primary role, which becomes the owner. Secondary roles authorize other actions. |
| B7 | B, C | In a managed access schema, object owners lose grant rights; only the schema owner or MANAGE GRANTS can grant. |
| B8 | A | Using an object also needs USAGE on its database and schema. |
| B9 | C | PUBLIC is granted automatically to every user and role. |
| B10 | A, C | At least two users, MFA required, not a default role, not for scripts or creating objects. |
| B11 | B | The most specific policy wins: a user-level policy overrides the account-level one. 10.1.2.3 isn't in JO's allowed range. |
| B12 | B | Blocked wins when an identifier is on both lists. |
| B13 | A, B | Network rules are schema-level containers of identifiers. Whether they allow or block depends on which list of the **policy** they're on, and policies (not rules) are activated. |
| B14 | B | Okta is a SAML 2.0 identity provider: federated authentication / SSO, set up with a SAML2 security integration. |
| B15 | A, B | Minimum 2048-bit RSA; `RSA_PUBLIC_KEY` and `RSA_PUBLIC_KEY_2` allow rotation. Only the **public** key is stored in Snowflake. Available on every edition. |
| B16 | B | Service users (TYPE = SERVICE) can't use passwords; key-pair, OAuth or workload identity federation are the recommended methods. |
| B17 | A | Snowflake OAuth: Snowflake is the authorization server. External OAuth: an external server (Okta, Entra ID, Ping, …) issues the tokens. Both use security integrations. |
| B18 | B | Telemetry goes to the active event table (default SNOWFLAKE.TELEMETRY.EVENTS). LOG_LEVEL (default OFF), TRACE_LEVEL and METRIC_LEVEL control what's captured. |

**Scoring:** 85% or more overall (28/32) means you're ready for Day 5. Under 70% (23/32) means you should reread the "Ten facts" in [notes.md](notes.md) and redo lab sections 5 to 7 before Day 5.
