# Day 4 practice questions: review

Graded from commit `f53282f`, using the answers marked in parentheses in [practice-questions.md](practice-questions.md). Your own "should be" notes match the answer key in every case.

## Score

| Part | Score |
|---|---|
| A · Transformations (4.4) | **12 / 14 (86%)** |
| B · Security model (2.1) | **16 / 18 (89%)** |
| **Total** | **28 / 32 (88%)**, just over the 85% bar |

Both halves were new material today, and both cleared 85% on the first try. JSON paths, FLATTEN, window functions, the system roles, secondary roles, managed access and authentication were all right.

## Misses and the concept behind each

| Q | You | Right | Concept | Tracker |
|---|---|---|---|---|
| A9 | B | **A** | Directory tables work on **both** internal and external stages. The real problem: internal stages default to **client-side encryption**, which blocks file, scoped and pre-signed URLs. Create the stage with `ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')`; it can't be changed later. | 4.4.1.3 |
| A11 | B | **A, C** | `ROLLUP (region, city)` rolls up **right to left**: detail rows, a subtotal per **region** (the first column), and a grand total. A subtotal per city across all regions only comes from **CUBE**. Remember: ROLLUP = a hierarchy, CUBE = every combination. | 4.4.2 |
| B5 | A, B | **B, C** | Database roles **can't** be activated with USE ROLE (the lab showed this failing). Grant them to an account role, or to a **share**, which is how providers expose subsets of a shared database. | 2.1.7.2 |
| B11 | A | **B** | Network policies don't combine: **the most specific level wins** (security integration > user > account). JO's user policy replaces the account policy, and 10.1.2.3 isn't in JO's range, so JO is blocked. | 2.1.4 |

## Pattern to watch

Three of the four misses picked an answer that was true **somewhere else**: directory tables (true of URL access in general, wrong cause), CUBE's subtotals for ROLLUP, and account-level allows for a user with its own policy. When two answers look plausible, ask which **level or variant** the question is about.
