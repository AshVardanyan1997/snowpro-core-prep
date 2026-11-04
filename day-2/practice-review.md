# Day 2 practice questions: review

Graded from commit `5d14649`, using the answers marked in parentheses in [practice-questions.md](practice-questions.md). Your own "should be" notes match the answer key in every case.

## Score

| Part | Score | Verdict |
|---|---|---|
| A · Day 1 review | **5 / 8 (63%)** | Three Day 1 topics are still not stable: transient vs temporary, editions, account identifiers |
| B · Day 2 topics (1.2, 1.4, 1.6) | **18 / 22 (82%)** | One short of the 85% bar (19/22). Go on to Day 3, but drill the four 1.4 misses first |

Up from Day 1 (75% on Part B). Every 1.2 and 1.6 question (interfaces, Snowpark, Streamlit, Cortex, ML) was right. All four Part B misses are in 1.4 warehouses.

## Misses and the concept behind each

### Part A (repeat misses from Day 1)
| Q | You | Right | Concept | Tracker |
|---|---|---|---|---|
| A1 | D, E | **B, D** | "Dropped when the session ends" is **temporary**, not transient. Transient = lasts until dropped, 0 or 1 day of Time Travel, no Fail-safe. Same topic as Day 1 B12 and B15. | 1.5.3.3 |
| A5 | C, E | **A, C** | Snowpipe is on **Standard**. Governance policies (masking, row access) and Search Optimization need **Enterprise**. Same topic as Day 1 A9. | 1.1.4, 2.2.1 |
| A7 | D | **B** | Preferred form is **`orgname-accountname`**, joined with a **hyphen**, org first. `finance_prod.acme` isn't a valid identifier format. Same topic as Day 1 B20. | 2.1.9 |

### Part B
| Q | You | Right | Concept | Tracker |
|---|---|---|---|---|
| B2 | A | **C** | Spilling is a **memory** problem in **one query**. One query runs on one cluster, so more clusters don't help. Scale **up**. (You got the mirror case, B3, right.) | 1.4.4.1, 4.1.1.1.1 |
| B5 | A | **B** | MIN = MAX → **maximized**: all clusters always run while the warehouse runs. Auto-scale needs MIN < MAX. | 1.4.2 |
| B9 | A | **B** | Resizing never cancels running queries. They finish on the old resources; queued and new queries get the new size. | 1.4.4.1 |
| B11 | A | **B** | Suspending drops the **local disk cache** of the warehouse. A longer auto-suspend keeps it warm for repeated dashboard queries. The result cache lives in cloud services and survives suspension (C is the trap). | 1.4.3.3, 4.3.3 |

## What to drill (10 minutes, before Day 3)

1. **The one-query rule.** A single query always runs on one cluster. So: spilling or slow query → bigger size. Queue of many queries → more clusters. Write this at the top of your error log.
2. **Multi-cluster modes.** MIN = MAX → maximized. MIN < MAX → auto-scale, and only then does the scaling policy (Standard or Economy) matter.
3. **Transient vs temporary.** Both: 0 or 1 day of Time Travel, no Fail-safe. Only temporary disappears when the session ends.
4. **Account identifier.** `orgname-accountname`, with a hyphen. Anything with a region in it is the legacy locator.
5. **Two caches, two places.** Result cache = cloud services, survives suspend. Local disk cache = warehouse, lost on suspend. Day 3 covers this in depth (4.3), so B11 will come back.
