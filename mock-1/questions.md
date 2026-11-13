# Mock 1 · SnowPro Core COF-C03

**100 questions · 115 minutes · no notes, no docs, no Snowflake.**

## Rules

- Set a timer for **115 minutes** and do it in one sitting, like the real exam.
- Mark your answer in parentheses, as before: `(B.)`. For "Select TWO/THREE", mark exactly that many.
- If you're unsure, add `?` after your mark, for example `(B.)?`. Guessed answers that turn out right still tell us something.
- When a question takes longer than **90 seconds**, mark your best guess with `?` and move on. Come back at the end if there's time.
- Don't open [answers.md](answers.md) until you've pushed your answers. Then I'll grade it and give you a score per domain.

The questions follow the real exam's domain weights, in order:

| Domain | Questions | Weight |
|---|---|---|
| 1 · Snowflake AI Data Cloud Features and Architecture | 1–31 | 31% |
| 2 · Account Management and Data Governance | 32–51 | 20% |
| 3 · Data Loading, Unloading, and Connectivity | 52–69 | 18% |
| 4 · Performance Optimization, Querying, and Transformation | 70–90 | 21% |
| 5 · Data Collaboration | 91–100 | 10% |

The real exam mixes the domains together. Here they're grouped so the score per domain is easy to read.

---

## Domain 1 · Features and Architecture

**1.** Which layer of the Snowflake architecture handles authentication, metadata management, and query optimization?
A. The client layer  B. Cloud services  C. Database storage  D. Query processing (virtual warehouses)

**2.** Snowflake's architecture is often described as a hybrid of which two traditional designs? (Select TWO)
A. Peer-to-peer  B. Shared-memory  C. Shared-nothing  D. Shared-disk  E. Master-slave replication

**3.** What size are Snowflake micro-partitions?
A. 1 GB each  B. 100 to 250 MB compressed  C. 16 MB compressed  D. 50 to 500 MB of uncompressed data

**4.** Which statements about micro-partitions are TRUE? (Select TWO)
A. Users define them with PARTITION BY when creating a table  B. Each table has exactly one micro-partition per day  C. Data inside them is stored by column  D. They are immutable  E. They can be updated in place

**5.** What is the minimum edition that supports multi-cluster warehouses?
A. Virtual Private Snowflake  B. Enterprise  C. Standard  D. Business Critical

**6.** A healthcare company needs PrivateLink connectivity and HIPAA support. What is the minimum edition?
A. Business Critical  B. Enterprise  C. Standard  D. Virtual Private Snowflake

**7.** Which objects live inside a schema? (Select TWO)
A. File format  B. Stage  C. Warehouse  D. Role  E. Share

**8.** STATEMENT_TIMEOUT_IN_SECONDS is set to 3600 for the account, 1800 for user ANA, and 600 in ANA's current session. What timeout applies to ANA's queries in that session?
A. 3600  B. 1800  C. 600  D. The lowest value across all warehouses

**9.** SYSTEM$CLUSTERING_INFORMATION returns these values for a large table. Which one suggests the table is well clustered on the chosen key?
A. A high average depth  B. A large number of overlapping micro-partitions  C. An average depth close to 1  D. A total partition count of 1

**10.** A staging table is reloaded from files every night and must survive across sessions. The team wants to avoid paying for Fail-safe storage on it. Which table type fits best?
A. Temporary  B. External  C. Permanent  D. Transient

**11.** Which statement about temporary tables is TRUE?
A. They need Enterprise edition  B. They have 7 days of Fail-safe  C. They exist only in the session that created them and are dropped when it ends  D. They're visible to all users with the right privileges

**12.** A provider wants to share a view while hiding its SQL definition from consumers. Which type of view is required?
A. Standard view  B. Secure view  C. Materialized view  D. Recursive view

**13.** Which statement about materialized views is TRUE?
A. They can query only a single table  B. They can join several tables  C. They are available on Standard edition  D. Users must refresh them manually

**14.** A developer wants to deploy a Streamlit app and a Native App from the command line. Which client should they use?
A. SnowSQL  B. Snowflake CLI  C. The ODBC driver  D. A Snowsight worksheet

**15.** Which clients can run the PUT command to upload a local file to an internal stage? (Select TWO)
A. The Snowflake Marketplace  B. SnowSQL  C. Snowflake CLI  D. Cortex Analyst  E. A Snowsight SQL worksheet

**16.** Query Profile shows a large amount of "bytes spilled to remote storage" for a nightly transformation. What is the most direct fix?
A. Increase the warehouse size  B. Enable the result cache  C. Add clusters to the warehouse  D. Switch the scaling policy to Economy

**17.** Every weekday at 9:00, 200 analysts open dashboards at once and their queries queue. Individual queries are fast once they start. What should you change?
A. Add a clustering key  B. Make the warehouse larger  C. Lower AUTO_SUSPEND  D. Make it a multi-cluster warehouse

**18.** A multi-cluster warehouse supports a reporting team. Keeping credits low matters more than avoiding occasional queuing. Which scaling policy fits?
A. Maximized  B. Auto-resume  C. Standard  D. Economy

**19.** A Large warehouse (8 credits per hour) runs for 30 minutes and then suspends. How many credits does it use?
A. 2  B. 4  C. 8  D. 16

**20.** A BI warehouse serves the same dashboard queries all day. Which is the main downside of setting its AUTO_SUSPEND to 60 seconds?
A. The local disk (warehouse) cache is lost each time it suspends  B. Credits are billed for a full hour on each resume  C. Queries fail while it resumes  D. The result cache is cleared

**21.** A data scientist trains a memory-intensive ML model inside a Snowpark stored procedure, and it runs out of memory. Which warehouse type should they use?
A. A multi-cluster Standard warehouse  B. Standard Gen 1 X-Small  C. Snowpark-optimized  D. A warehouse with Query Acceleration

**22.** A warehouse is resized from Small to Large while three queries are running. What happens?
A. The running queries are cancelled and restarted on Large  B. The resize waits until the warehouse is idle  C. The running queries move to the larger cluster mid-execution  D. The running queries finish on Small; new and queued queries use Large

**23.** A multi-cluster warehouse has MIN_CLUSTER_COUNT = 3 and MAX_CLUSTER_COUNT = 3. Which mode is this?
A. Maximized  B. Standard  C. Economy  D. Auto-scale

**24.** What is Standard Gen 2 warehouse hardware especially good at, compared with Gen 1?
A. Running on GPU compute pools  B. 16x more memory per node for ML  C. Lower credit cost per hour for the same size  D. Faster DML (DELETE, UPDATE, MERGE) and table scans

**25.** In Snowpark Python, when does a DataFrame transformation actually run in Snowflake?
A. When an action such as collect(), show() or save_as_table() is called  B. Immediately, on each method call  C. Only when the session is closed  D. On the client machine, not in Snowflake

**26.** By default, whose privileges does a Streamlit in Snowflake app use when it queries data?
A. PUBLIC's  B. ACCOUNTADMIN's  C. The viewing user's  D. The app owner role's

**27.** A company wants a chatbot that answers questions from thousands of PDF policy documents using retrieval-augmented generation (RAG). Which Cortex feature finds the relevant text?
A. AI_SENTIMENT  B. Cortex Analyst  C. ML FORECAST  D. Cortex Search

**28.** Business users want to ask "What was revenue by region last quarter?" in plain English and get answers from structured sales tables. Which Cortex feature fits best?
A. Cortex Search  B. AI_TRANSLATE  C. AI_REDACT  D. Cortex Analyst with a semantic view

**29.** How are Cortex AI SQL functions such as AI_COMPLETE billed?
A. Only by the size of the warehouse  B. By tokens processed  C. A flat monthly fee  D. Per row returned

**30.** Which function keeps only the rows that match a natural-language condition, used in a WHERE clause?
A. AI_FILTER  B. AI_EMBED  C. AI_AGG  D. AI_CLASSIFY

**31.** A sales manager wants to predict next quarter's daily sales from SQL, without writing ML code. What should they use?
A. The FORECAST ML function  B. A materialized view  C. Cortex Search  D. Snowpipe Streaming

---

## Domain 2 · Account Management and Data Governance

**32.** Which system role creates users and roles by default?
A. ORGADMIN  B. USERADMIN  C. PUBLIC  D. SYSADMIN

**33.** Which privilege lets SECURITYADMIN grant or revoke privileges on any object, even one it doesn't own?
A. OWNERSHIP  B. APPLY GRANTS  C. CREATE ROLE  D. MANAGE GRANTS

**34.** Snowflake recommends that custom roles which own databases and warehouses be granted to which system role, so that administrators can manage those objects?
A. USERADMIN  B. ORGADMIN  C. PUBLIC  D. SYSADMIN

**35.** A user's primary role is ANALYST, and their secondary roles are set to ALL. They run CREATE TABLE. Which role owns the new table?
A. SYSADMIN  B. PUBLIC  C. The secondary role with the most privileges  D. ANALYST, the primary role

**36.** An account-level network policy allows 10.0.0.0/8. User JO has a user-level network policy that allows only 192.168.1.0/24. JO connects from 10.1.1.1. What happens?
A. JO is allowed, because the two policies are combined  B. JO is asked for MFA  C. JO is blocked, because the user-level policy applies instead of the account policy  D. JO is allowed, because the account policy allows the address

**37.** A nightly ETL service connects as a service user (TYPE = SERVICE). Which authentication method should it use?
A. Password only  B. SSO through the browser  C. Key-pair authentication  D. Password with MFA

**38.** What is Snowflake's preferred format for an account identifier?
A. The account locator only  B. The account's IP address  C. The cloud region name  D. `<orgname>-<account_name>`

**39.** A table has both a row access policy and a masking policy. How are they applied when a user queries it?
A. Only the policy created last applies  B. They can't be on the same table  C. Row access first, then masking on the remaining rows  D. Masking first, then row access

**40.** Which statements about object tags are TRUE? (Select TWO)
A. Tag values can be numbers, dates or strings  B. A tag is an account-level object  C. An object can have unlimited tags  D. A masking policy can be attached to a tag  E. A tag on a table is inherited by its columns

**41.** An aggregation policy with MIN_GROUP_SIZE => 10 is attached to a table. An analyst without an exemption runs `SELECT * FROM t LIMIT 5`. What happens?
A. 5 rows are returned  B. The query fails, because results must be aggregated  C. Rows are returned only if there are at least 10  D. 5 masked rows are returned

**42.** A security team wants to check the account against the Center for Internet Security's benchmark for Snowflake. What should they turn on?
A. Periodic rekeying  B. Security Essentials in Trust Center  C. The CIS Benchmarks scanner package in Trust Center  D. A row access policy

**43.** A customer wants to be able to revoke a key held in their own cloud key-management service, so Snowflake can no longer decrypt their data. Which feature is this, and what edition does it need?
A. Periodic rekeying, Enterprise  B. Client-side encryption, Enterprise  C. Automatic key rotation, Standard  D. Tri-Secret Secure, Business Critical

**44.** What does periodic rekeying do?
A. Encrypts data in transit  B. Re-encrypts data whose key was retired more than a year ago, on Enterprise or higher  C. Lets customers bring their own key  D. Rotates keys every 30 days on all editions

**45.** Which statement about alerts is TRUE?
A. An alert is created suspended and needs ALTER ALERT … RESUME  B. An alert starts running as soon as it's created  C. An alert can only send email  D. Alerts need Business Critical

**46.** A company wants a secondary account in another region that can be promoted to accept writes if the primary region fails. What does it need?
A. A clone of the database  B. A replication group on Standard edition  C. A direct share  D. A failover group, which needs Business Critical

**47.** Auditors ask who read the `salary` column last month, including reads through views. Which ACCOUNT_USAGE view answers this?
A. TAG_REFERENCES  B. ACCESS_HISTORY  C. LOGIN_HISTORY  D. QUERY_HISTORY

**48.** A resource monitor reaches a threshold whose action is SUSPEND_IMMEDIATE. What happens to queries running on its warehouses?
A. They are paused until the next interval  B. They finish, then the warehouses suspend  C. They are cancelled and the warehouses suspend  D. Nothing; only a notification is sent

**49.** Finance wants to be notified when monthly spending on Snowpipe and serverless tasks gets close to a limit. What should you use?
A. Query Acceleration  B. A warehouse-level resource monitor  C. An account-level resource monitor with SUSPEND  D. A budget

**50.** Which statements about the ACCOUNT_USAGE schema are TRUE? (Select TWO)
A. Most views keep about 1 year of history  B. It has no latency  C. It includes dropped objects  D. Only SYSADMIN can query it  E. It covers only the current database

**51.** Who can create a resource monitor?
A. SECURITYADMIN  B. Any role with CREATE WAREHOUSE  C. ACCOUNTADMIN  D. SYSADMIN

---

## Domain 3 · Data Loading, Unloading, and Connectivity

**52.** Which file format can Snowflake load but NOT unload?
A. Parquet  B. CSV  C. XML  D. JSON

**53.** Which statement about table stages (`@%table`) is TRUE?
A. Several tables share one table stage  B. They don't support transformations during COPY  C. They can be dropped like named stages  D. Privileges on them can be granted to any role

**54.** Files were staged long ago, and their load status is unknown because the load metadata has expired. Which COPY option loads them anyway?
A. PURGE = TRUE  B. FORCE = TRUE  C. VALIDATION_MODE = RETURN_ALL_ERRORS  D. LOAD_UNCERTAIN_FILES = TRUE

**55.** COPY INTO runs with ON_ERROR = SKIP_FILE on five files, and one file has two bad rows. What is loaded?
A. All rows except the two bad ones  B. The four clean files; the file with errors is skipped entirely  C. Only the first file  D. Nothing

**56.** Which statement about VALIDATION_MODE is TRUE?
A. It's the default for Snowpipe  B. It checks the files without loading any data  C. It works with any COPY transformation  D. It loads the valid rows and reports the invalid ones

**57.** You unload a table with `FILE_FORMAT = (TYPE = PARQUET)` and no other options. How are the files compressed?
A. gzip  B. ZSTD  C. Not compressed  D. Snappy

**58.** A JSON file contains one large array: `[ {...}, {...}, ... ]`. You want each element loaded as its own row. Which file format option should you set?
A. SKIP_HEADER = 1  B. STRIP_NULL_VALUES = TRUE  C. FLATTEN = TRUE  D. STRIP_OUTER_ARRAY = TRUE

**59.** What does PURGE = TRUE do in a COPY INTO <table> command?
A. Deletes the target table's existing rows before loading  B. Removes successfully loaded files from the stage  C. Clears the load metadata  D. Deletes files that failed to load

**60.** How is Snowpipe compute billed?
A. On the warehouse named in the pipe  B. A fixed charge per file regardless of size  C. It isn't billed  D. As serverless compute, based on the amount of data loaded

**61.** What are the two ways to trigger Snowpipe? (Select TWO)
A. A CRON schedule on the pipe  B. Calls to the Snowpipe REST API  C. Cloud storage event notifications (auto-ingest)  D. Running EXECUTE PIPE  E. A resource monitor

**62.** When does a stream's offset advance?
A. Every time the stream is queried with SELECT  B. When the source table is cloned  C. Every 24 hours  D. When a DML statement that reads the stream commits

**63.** A table has DATA_RETENTION_TIME_IN_DAYS = 1, and its stream hasn't been consumed for some time. By default, how long can Snowflake extend the table's retention to keep the stream from going stale?
A. 1 day  B. 7 days  C. 14 days  D. 90 days

**64.** A task is created without a WAREHOUSE parameter. Which statements are TRUE? (Select TWO)
A. The owner role needs the EXECUTE MANAGED TASK privilege  B. It runs on serverless compute managed by Snowflake  C. It fails at creation  D. It runs on the user's default warehouse  E. It can't be scheduled

**65.** A pipeline needs IF/ELSE logic in a stored procedure, a MERGE, and a run at 02:00 every night (CRON). Which approach fits best?
A. A materialized view  B. A dynamic table  C. A secure view  D. Streams and tasks

**66.** IoT devices send small JSON events continuously, and they must be queryable within seconds without staging files. Which feature fits?
A. Snowpipe with auto-ingest  B. An external table  C. Snowpipe Streaming  D. Bulk COPY INTO

**67.** Which object lets external stages access cloud storage through an identity (such as an AWS IAM role) instead of keys in SQL?
A. Security integration  B. API integration  C. Notification integration  D. Storage integration

**68.** Which of these are Snowflake drivers? (Select TWO)
A. Snowpipe Streaming  B. Go  C. The Kafka connector  D. Snowsight  E. JDBC

**69.** Your Snowflake Git repository object is behind the remote repository. What do you run to update it?
A. GIT PULL  B. ALTER GIT REPOSITORY … FETCH  C. CREATE OR REPLACE STAGE  D. ALTER GIT REPOSITORY … PUSH

---

## Domain 4 · Performance, Querying, and Transformation

**70.** In Query Profile, "Partitions scanned" is almost equal to "Partitions total" for a query that filters on a date range. What does this indicate?
A. Inefficient pruning  B. Remote spilling  C. Exploding join  D. Queuing

**71.** A join returns 50 million rows from two tables with 10,000 rows each. What is the most likely cause?
A. Too small a warehouse  B. An exploding join from a missing or wrong join condition  C. Too many clusters  D. Result cache being disabled

**72.** You need the text and duration of every query from the last 6 months. Which source do you use?
A. INFORMATION_SCHEMA.QUERY_HISTORY()  B. The result cache  C. Snowsight Query History  D. SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY

**73.** Which ACCOUNT_USAGE view shows the compute credits attributed to each individual query?
A. METERING_DAILY_HISTORY  B. WAREHOUSE_METERING_HISTORY  C. QUERY_ATTRIBUTION_HISTORY  D. STORAGE_USAGE

**74.** A warehouse runs mostly small queries, but occasional ad-hoc queries scan huge amounts of data and slow everything down. Which feature is designed for these outlier queries?
A. Materialized views  B. Automatic Clustering  C. Query Acceleration Service  D. Search Optimization Service

**75.** Analysts look up single customers in a 5 TB table with `WHERE customer_email = '...'`. Which feature speeds up these point lookups?
A. Search Optimization Service  B. Query Acceleration Service  C. Multi-cluster warehouse  D. A larger warehouse

**76.** A multi-terabyte event table is almost always filtered by day, and its timestamp column has very high cardinality. Which clustering key is best?
A. `(TO_DATE(event_ts))`  B. No key; use a materialized view  C. `(event_ts)`  D. `(event_id)`

**77.** Which conditions prevent a query from using the result cache? (Select TWO)
A. The query calls a function such as CURRENT_TIMESTAMP()  B. The warehouse that ran the original query is suspended  C. The query runs on a different warehouse  D. The underlying table's data changed since the result was cached

**78.** How long is a query result kept in the result cache if it's never reused?
A. 1 hour  B. 24 hours  C. 7 days  D. 31 days

**79.** `SELECT COUNT(*) FROM big_table` returns instantly with no warehouse running. Why?
A. Query Acceleration ran it  B. The metadata in the cloud services layer answered it  C. It was a materialized view  D. The warehouse cache answered it

**80.** What happens to the warehouse (local disk) cache when a warehouse suspends?
A. It moves to the result cache  B. It's kept for 24 hours  C. It's dropped  D. It's copied to remote storage

**81.** A VARIANT column `v` holds `{"Customer": {"City": "Yerevan"}}`. What does `SELECT v:customer.city FROM t` return?
A. NULL  B. "Yerevan"  C. An error  D. Yerevan

**82.** You FLATTEN an array column, and some rows have empty arrays. You still want those rows in the output. What do you set?
A. PATH => ''  B. MODE => 'ARRAY'  C. OUTER => TRUE  D. RECURSIVE => TRUE

**83.** Which FLATTEN output column holds each array element?
A. INDEX  B. KEY  C. SEQ  D. VALUE

**84.** Scores are 100, 100 and 90. Which function returns 1, 1, 2 for them?
A. RANK  B. DENSE_RANK  C. NTILE  D. ROW_NUMBER

**85.** Which clause filters rows on the result of a window function without a subquery?
A. QUALIFY  B. HAVING  C. GROUP BY  D. WHERE

**86.** Which function gives a fast, approximate count of distinct values using HyperLogLog?
A. APPROX_COUNT_DISTINCT  B. APPROX_TOP_K  C. COUNT(DISTINCT …)  D. HASH_AGG

**87.** You need subtotals per region (and not per city across all regions), plus a grand total, from `GROUP BY region, city`. Which extension do you use?
A. CUBE  B. ROLLUP  C. PIVOT  D. GROUPING SETS ((), (city))

**88.** Which type of URL lets only the user who generated it access a staged file, and expires after 24 hours?
A. External URL  B. Scoped URL  C. File URL  D. Pre-signed URL

**89.** A partner without a Snowflake login needs temporary download access to one file in an internal stage. Which URL type fits?
A. File URL  B. Scoped URL  C. Directory table URL  D. Pre-signed URL

**90.** Which statements about materialized views are TRUE? (Select TWO)
A. Snowflake maintains them in the background using serverless compute  B. They're best for queries on base tables that change constantly  C. They always return current data, even if maintenance is behind  D. Resource monitors control their maintenance cost

---

## Domain 5 · Data Collaboration

**91.** What is the default Time Travel retention period for a permanent table?
A. 0 days  B. 1 day  C. 7 days  D. 90 days

**92.** A permanent table with DATA_RETENTION_TIME_IN_DAYS = 0 is dropped by mistake. How can it be recovered?
A. Only through Snowflake Support, from Fail-safe  B. Query it with AT(OFFSET => -60)  C. UNDROP TABLE  D. It can't be recovered at all

**93.** Which statement about Fail-safe is TRUE?
A. It lasts 7 days and only Snowflake Support can recover data from it  B. It can be extended to 30 days on Enterprise  C. Users can query it with Time Travel syntax  D. Transient tables have 7 days of Fail-safe

**94.** You clone a 500 GB table and then update 1% of the rows in the clone. Roughly how much new storage is used?
A. 250 GB  B. None, ever  C. Only the micro-partitions that changed in the clone  D. 500 GB

**95.** Which statement creates a copy of a table as it was before a specific bad statement ran?
A. `UNDROP TABLE t`  B. `CREATE TABLE t2 COPY t AT(TIMESTAMP => ...)`  C. `CREATE TABLE t2 LIKE t`  D. `CREATE TABLE t2 CLONE t BEFORE(STATEMENT => '<query id>')`

**96.** In Secure Data Sharing between two full Snowflake accounts, who pays for what?
A. The provider pays for storage; the consumer pays for the compute it uses to query  B. Both split the storage cost  C. The provider pays for storage and compute  D. The consumer pays for storage and compute

**97.** Which statement about reader accounts is TRUE?
A. The reader account pays for its own compute  B. A reader account is created and paid for by the provider and can only query data shared by that provider  C. Reader accounts can load their own data  D. Reader accounts can consume shares from any provider

**98.** A provider in one cloud region wants to share data with a consumer in a different region. What's TRUE?
A. A direct share works across regions automatically  B. A direct share works only within one region; the provider needs replication or a listing with Cross-Cloud Auto-Fulfillment  C. The consumer must create a reader account  D. Cross-region sharing is impossible

**99.** A provider wants any Snowflake customer to be able to find and get its dataset. What should it publish?
A. A direct share  B. A reader account  C. A public listing on the Snowflake Marketplace  D. A private listing

**100.** Where does a Snowflake Native App run after a consumer installs it?
A. In the consumer's account  B. Outside Snowflake, on the provider's servers  C. In the provider's account, on the consumer's data copied there  D. In a reader account
