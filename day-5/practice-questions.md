# Day 5 Practice Questions

- **Part A: Data governance** (14 questions on objective 2.2).
- **Part B: Monitoring and cost** (7 questions on objective 2.3).
- **Part C: Loading and unloading** (13 questions on objective 3.1).

34 questions, about 40 minutes at exam pace. Answer them after the notes and the lab. Mark your answers the same way as before. Answers and explanations are at the bottom. Cover them while you work, and add every miss to your error log.

---

## Part A · Data governance (2.2)

**A1.** A masking policy is applied to the `email` column. What happens to the data stored in the table?
A. It's rewritten in masked form  B. It's encrypted with a separate key  (C. )Nothing: masking is applied at query time  D. It's copied to a hidden secure table

**A2.** A table has both a row access policy and a masking policy. In which order are they evaluated?
A. Masking policy first, then row access policy  (B.) Row access policy first, then masking policy  C. Both at the same time  D. Whichever was attached first

**A3.** A masking policy uses `CURRENT_ROLE() = 'ANALYST'`. A user's active role is JUNIOR_ANALYST, which has been granted ANALYST. What does the user see?
(A.) Masked data, because CURRENT_ROLE() checks only the active role  B. Real data, because ANALYST is in the hierarchy  C. An error  D. NULL

**A4.** What is the minimum Snowflake edition for Dynamic Data Masking and row access policies?
A. Standard ( B.) Enterprise  C. Business Critical  D. Virtual Private Snowflake

**A5.** A security team wants every column tagged `PII = 'email'` in the account to be masked automatically, including columns added next month. What should they use?
A. A secure view over each table  B. A row access policy on each table  (C.) A masking policy attached to the tag  D. Automatic Clustering

**A6.** Which statement about object tags is TRUE?
A. A tag is an account-level object  (B.) A tag set on a table is inherited by its columns  C. Tag values can be any data type  D. An object can have unlimited tags

**A7.** Analysts may only see results computed over groups of at least 10 customers, never individual rows. Which policy fits?
A. Projection policy  B. Row access policy ( C.) Aggregation policy  D. Masking policy

**A8.** Analysts need to join on a customer's email but must never see the email in the output. Which policy fits best?--should be B
A. Aggregation policy  B. Projection policy  C. Network policy  (D.) Join policy

**A9.** Which Trust Center scanner package is enabled by default and can't be disabled?-- should be C
A. CIS Benchmarks  (B.) Threat Intelligence  C. Security Essentials  D. Data Security

**A10.** Put Snowflake's encryption key hierarchy in order, from the top.
(A.) Root key → account master key → table master key → file key  B. Account master key → root key → file key → table master key  C. File key → table master key → account master key → root key  D. Root key → table master key → account master key → file key

**A11.** A customer wants to be able to revoke a key they control so that Snowflake can no longer decrypt their data. Which feature, and which minimum edition?
A. Periodic rekeying, Enterprise  (B.) Tri-Secret Secure, Business Critical  C. Automatic key rotation, Standard  D. Tri-Secret Secure, Standard

**A12.** An alert was just created with CREATE ALERT. What is its state, and what is needed to start the schedule?
A. Started; nothing  (B.) Suspended; ALTER ALERT … RESUME  C. Suspended; EXECUTE TASK  D. Started; ALTER ALERT … SUSPEND to stop it

**A13.** A company on Enterprise edition wants to replicate a database to another region. Then it wants to replicate users and roles too, and fail over if the region goes down. What's TRUE? (Select TWO) --should be A, B
(A.) Database replication is available on Enterprise  B. Replicating users and roles requires Business Critical  (C. )Failover is available on every edition  D. The secondary database can be written to at any time  E. Replication only works within one cloud provider

**A14.** An auditor asks which users read the `salary` column last month, including reads through views. Where do you look?--should be C
(A. )QUERY_HISTORY  B. LOGIN_HISTORY  C. ACCESS_HISTORY (base_objects_accessed)  D. TAG_REFERENCES

---

## Part B · Monitoring and cost (2.3)

**B1.** Which role can create a resource monitor?
A. SYSADMIN  B. SECURITYADMIN  (C.) ACCOUNTADMIN only  D. Any role with CREATE WAREHOUSE

**B2.** A resource monitor reaches a threshold with the action SUSPEND (not SUSPEND_IMMEDIATE). What happens to queries running at that moment?
A. They're cancelled  (B.) They finish, then the warehouse suspends  C. They're paused and resume next interval  D. They move to another warehouse

**B3.** Which costs can a resource monitor NOT control? (Select TWO)
A. A virtual warehouse's compute  (B.) Snowpipe  (C.) Automatic Clustering  D. A multi-cluster warehouse

**B4.** Which statement about resource monitors is TRUE? --should be B
(A.) A warehouse can be assigned to several warehouse-level monitors  B. An account can have one account-level monitor  C. Thresholds can't go over 100%  D. Resource monitors reset at midnight in the account's time zone

**B5.** A Medium warehouse (4 credits per hour) runs as a multi-cluster warehouse with 3 clusters for 30 minutes. How many credits does it use?
A. 2  B. 4  (C.) 6  D. 12

**B6.** An X-Small warehouse resumes, runs one 10-second query, and auto-suspends after 60 seconds of idle time. How long is it billed for?
A. 10 seconds  B. 60 seconds  (C.) 70 seconds  D. A full hour

**B7.** You need login attempts from 4 months ago, including users dropped since then. Which do you query?
A. INFORMATION_SCHEMA.LOGIN_HISTORY table function  (B.) SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY  C. SHOW USERS  D. The Trust Center

---

## Part C · Loading and unloading (3.1)

**C1.** Which file formats can Snowflake unload data into? (Select THREE)
(A.) CSV  (B.) JSON  C. Avro  (D.) Parquet  E. ORC  F. XML

**C2.** What is the recommended size for data files to load?
A. 1–10 MB uncompressed  (B.) About 100–250 MB compressed  C. At least 1 GB per file  D. One file per table, any size

**C3.** Which stage type can't be used with a COPY transformation (`SELECT $1, $2 FROM @…`)?
A. User stage  B. Named internal stage  (C.) Table stage  D. Named external stage

**C4.** Which stage reference is the current user's stage?
A. `@%users`  (B.) `@~`  C. `@user`  D. `@$user`

**C5.** What is the recommended way for an external stage to access an S3 bucket?
A. Put the AWS keys in the CREDENTIALS parameter  (B.) Use a storage integration  C. Make the bucket public  D. Use PUT from SnowSQL

**C6.** Which encryption type must a named internal stage use to support presigned URLs, and when must it be set?
A. SNOWFLAKE_FULL, at any time ( B.) SNOWFLAKE_SSE, at creation  C. AWS_SSE_KMS, at creation  D. SNOWFLAKE_SSE, at any time with ALTER STAGE

**C7.** A COPY INTO command runs without an ON_ERROR option and hits one bad row. What happens?
A. The bad row is skipped  B. The file with the bad row is skipped  (C.) The whole load is stopped and nothing is loaded  D. The bad row is loaded as NULLs

**C8.** What is the default ON_ERROR behaviour for Snowpipe?
A. ABORT_STATEMENT  B. CONTINUE  (C.) SKIP_FILE  D. SKIP_FILE_10%

**C9.** You want to see every error in a set of staged files without loading any data. Which option?
A. ON_ERROR = CONTINUE  (B.) VALIDATION_MODE = RETURN_ERRORS  C. PURGE = TRUE  D. FORCE = TRUE

**C10.** A COPY command loads 50 files. A colleague runs the identical command an hour later. What happens?
A. The 50 files load again and duplicate the data  (B.) The files are skipped, because load metadata shows they're already loaded  C. The command fails  D. Only changed rows load

**C11.** A table was loaded from staged files last week. You must load the same files into the same table again, without duplicates. What is the best approach? (This mirrors the study guide's sample question.)
A. Run DELETE FROM the table, then COPY  (B.) Run TRUNCATE TABLE, then COPY  C. Drop and recreate the stage  D. Set PURGE = TRUE

**C12.** How long does Snowflake keep load metadata for a table?
A. 24 hours  B. 14 days  (C.) 64 days  D. 1 year

**C13.** You unload a 2 GB table with `COPY INTO @stage/out/ FROM t FILE_FORMAT = (TYPE = CSV)` and no other options. What do you get?
A. One uncompressed CSV file  (B.) Several gzip-compressed CSV files of up to about 16 MB each  C. One gzip file of 2 GB  D. An error, because unloads need SINGLE = TRUE

---

## Answers

### Part A
| Q | Answer | Why |
|---|---|---|
| A1 | C | Masking is applied at query time. The stored data never changes, and a WHERE filter still works on the real value. |
| A2 | B | **Row access policy first**, then masking on the rows that are left. |
| A3 | A | CURRENT_ROLE() returns only the active primary role (JUNIOR_ANALYST). IS_ROLE_IN_SESSION('ANALYST') would return TRUE through the hierarchy. |
| A4 | B | Both are Enterprise features. |
| A5 | C | Tag-based masking: a policy attached to a tag masks every column with that tag (and a matching data type), including ones tagged later. |
| A6 | B | Tags are inherited down the hierarchy (table → columns). Tags are schema-level, values are strings, and the limit is 50 tags per object. |
| A7 | C | An aggregation policy forces aggregation with a minimum group size. |
| A8 | B | A projection policy stops a column from appearing in output, but it can still be used in WHERE or JOIN. |
| A9 | C | Security Essentials is on by default, free, and can't be disabled. CIS Benchmarks and Threat Intelligence are off until you enable them. |
| A10 | A | Root key (in an HSM) → account master keys → table master keys → file keys. |
| A11 | B | Tri-Secret Secure combines a customer-managed key with a Snowflake key. Business Critical or higher. |
| A12 | B | Alerts (like tasks) are created suspended. `ALTER ALERT … RESUME` starts the schedule. EXECUTE ALERT runs it once. |
| A13 | A, B | Database and share replication work on every edition. Account objects (users, roles, …) and failover need Business Critical. Secondaries are read-only until promoted, and replication works across clouds. |
| A14 | C | ACCESS_HISTORY shows which columns each query read. `base_objects_accessed` resolves views to the tables behind them. |

### Part B
| Q | Answer | Why |
|---|---|---|
| B1 | C | Only ACCOUNTADMIN can create resource monitors. It can grant MONITOR or MODIFY on them to others. |
| B2 | B | SUSPEND waits for running statements to finish. SUSPEND_IMMEDIATE cancels them. |
| B3 | B, C | Resource monitors track warehouses only. Serverless features (Snowpipe, Automatic Clustering, MVs, search optimization, serverless tasks) need a budget. |
| B4 | B | One account-level monitor per account. A warehouse belongs to only one warehouse monitor, thresholds can exceed 100%, and resets happen at 12:00 AM UTC. |
| B5 | C | 4 credits × 3 clusters × 0.5 hours = 6. |
| B6 | C | Billing runs while the warehouse is up: 10 seconds of query plus 60 seconds idle before auto-suspend = 70 seconds. The 60-second minimum is already met. |
| B7 | B | ACCOUNT_USAGE keeps 1 year and includes dropped objects. INFORMATION_SCHEMA's LOGIN_HISTORY goes back only 7 days. |

### Part C
| Q | Answer | Why |
|---|---|---|
| C1 | A, B, D | Unloading supports CSV, JSON and Parquet. Avro, ORC and XML are load-only. |
| C2 | B | About 100–250 MB compressed, so loads run in parallel without per-file overhead. |
| C3 | C | Table stages don't support transformations during COPY. |
| C4 | B | `@~` is the user stage. `@%name` is a table stage. |
| C5 | B | A storage integration keeps credentials out of SQL. The docs highly recommend it. You can't PUT to an external stage. |
| C6 | B | Presigned URLs need SNOWFLAKE_SSE (server-side only), and a stage's encryption type can't be changed after creation. |
| C7 | C | The COPY default is ABORT_STATEMENT: one error stops the whole load. |
| C8 | C | Snowpipe defaults to SKIP_FILE. |
| C9 | B | VALIDATION_MODE checks files without loading. RETURN_ERRORS returns all errors. |
| C10 | B | Load metadata (kept 64 days) makes COPY skip files it has already loaded. |
| C11 | B | TRUNCATE clears the table and its load metadata, so the files load again. DELETE leaves the metadata, so COPY would skip the files (you'd need FORCE). |
| C12 | C | 64 days. Older files have an uncertain status: LOAD_UNCERTAIN_FILES = TRUE loads them. |
| C13 | B | SINGLE defaults to FALSE and MAX_FILE_SIZE to 16 MB, and CSV unloads are gzip-compressed by default. |

**Scoring:** 85% or more overall (29/34) means you're ready for Day 6. Under 70% (24/34) means you should reread the "Ten facts" in [notes.md](notes.md) and redo lab section 8 before Day 6.
