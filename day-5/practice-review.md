# Day 5 practice questions: review

Graded from commit `0274dab`, using the answers marked in parentheses in [practice-questions.md](practice-questions.md). Your own "should be" notes match the answer key in every case.

## Score

| Part | Score |
|---|---|
| A · Data governance (2.2) | **10 / 14 (71%)** |
| B · Monitoring and cost (2.3) | **6 / 7 (86%)** |
| C · Loading and unloading (3.1) | **13 / 13 (100%)** |
| **Total** | **29 / 34 (85%)**, right on the 85% bar |

Loading and unloading was perfect, including every COPY trap: the ON_ERROR defaults, load metadata, TRUNCATE vs DELETE, and the unload defaults. Cost was solid too. All the credit arithmetic was right, including the idle seconds in B6.

All five misses are governance and resource monitor facts from sections 4, 5, 8, 9 and 10 of the notes. Most of that is past the point where you stopped reading the first version, so reread those sections in the new version before Day 6.

## Misses and the concept behind each

| Q | You | Right | Concept | Notes section | Tracker |
|---|---|---|---|---|---|
| A8 | D | **B** | "Can **join** on it, can't **see** it" is a **projection policy**: the column can't appear in the output but works in WHERE and JOIN. A join policy is the opposite idea: it **forces** queries to join the table before they get any results. The word "join" in the question is bait. | 4 | 2.2.3 |
| A9 | B | **C** | **Security Essentials** is on by default, free and always on. **Threat Intelligence** and CIS Benchmarks are opt-in, run daily once enabled and cost credits. | 5 | 2.2.4 |
| A13 | A, C | **A, B** | Database replication works on **every** edition. **Failover**, and replicating **account objects** like users and roles, need **Business Critical**. Think of it as: a read-only copy is cheap, but taking over writes after a disaster is a premium feature. | 8 | 2.2.8 |
| A14 | A | **C** | QUERY_HISTORY stores the **SQL text**, not which columns it touched, and it can't see through a view. **ACCESS_HISTORY** records the columns read per query, and `base_objects_accessed` resolves views to the tables behind them. | 9 | 2.2.9 |
| B4 | A | **B** | **One** account-level monitor per account, and a warehouse can be in **only one** warehouse-level monitor. A monitor can cover many warehouses, but not the other way round. | 10 | 2.3.1 |

## Pattern to watch

The same pattern as Day 4 shows up again. A8 and A9 picked a real feature from the same family (join policy instead of projection policy, Threat Intelligence instead of Security Essentials). A13 applied a rule from the cheap tier (replication on every edition) to the premium tier (failover). When two options are siblings, find the **one word in the question that only fits one of them**: "never see" means projection, "can't be disabled" means Security Essentials, "fail over" means Business Critical.

## Before Day 6

1. Reread sections 4, 5, 8, 9 and 10 of the new [notes.md](notes.md), about 20 minutes.
2. Add the five misses to your error log.
3. If you haven't run lab section 6 (resource monitor), run it. Creating the monitor as SYSADMIN and watching it fail is the fastest way to remember who can create one.
