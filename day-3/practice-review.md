# Day 3 practice questions: review

Graded from commit `a37654c`, using the answers marked in parentheses in [practice-questions.md](practice-questions.md).

## Score

| Part | Score | Verdict |
|---|---|---|
| A · Repeat-miss review | **8 / 8 (100%)** | Every topic you'd missed twice (transient vs temporary, editions, account identifiers, scale up vs out, maximized mode, resizing, the warehouse cache) is now fixed |
| B · Day 3 topics (4.1, 4.2, 4.3) | **23 / 24 (96%)** | Well above the 85% bar |

Trend on the day's topics: Day 1 75% → Day 2 82% → Day 3 96%.

## The one miss

| Q | You | Right | Concept | Tracker |
|---|---|---|---|---|
| B8 | A, B | **A, C** | QUERY_ATTRIBUTION_HISTORY gives warehouse credits **per query**, but **excludes idle time** and queries of **about 100 ms or less** (also cloud services, storage, serverless and AI tokens). It can be up to 8 hours behind. For a warehouse's total credits, including idle time, use WAREHOUSE_METERING_HISTORY. | 4.1.2.1 |

Your own note on B8 already has the right answer.
