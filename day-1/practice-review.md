# Day 1 practice questions: review

Graded from commit `5577cd0` ("answered the questions"), using the answers marked in parentheses in [practice-questions.md](practice-questions.md). Your self-notes ("should be …") match the answer key in every case, and I checked the key itself and found no errors.

## Score

| Part | Score | Verdict |
|---|---|---|
| A · Diagnostic (mixed domains) | **10 / 15 (67%)** | Fine for a cold diagnostic; misses point at Days 2–6 topics |
| B · Day 1 topics (1.1, 1.3, 1.5) | **15 / 20 (75%)** | Between 70% and 85%: move on to Day 2, but reread the "Ten facts" in notes.md first |

## Misses and the concept behind each

### Part A
| Q | You | Right | Concept | Tracker |
|---|---|---|---|---|
| A2 | A | **B** | Queuing = concurrency → scale **out** (multi-cluster). Bigger size = scale **up**, helps one slow, complex query. | 1.4.4.1, 1.4.4.2, 1.4.4.4.2 |
| A6 | C | **B** | No Snowflake account → **reader account**, created and paid for by the provider. Exporting to a stage isn't sharing. | 5.2.1.3 |
| A7 | C | **A** | Spilling = out of memory/local disk → **larger warehouse**. The result cache only helps repeated identical queries. | 4.1.1.1.1, 1.4.4.1 |
| A9 | A | **B** | Masking and row access policies need **Enterprise**. | 1.1.4, 2.2.1 |
| A13 | A | **B** | A clone is **metadata only**; it shares micro-partitions until either side changes. Clones don't inherit the source's Time Travel history. | 5.1.3 |

### Part B
| Q | You | Right | Concept | Tracker |
|---|---|---|---|---|
| B12 | C | **B** | Regenerable data + lowest storage cost → **transient** (no Fail-safe). External tables point at files outside Snowflake; they're not a staging-table choice. | 1.5.3.3 |
| B15 | (blank) | **B** | Transient retention can only be **0 or 1** day. You can't ALTER a transient table to permanent, and it never gets Fail-safe. | 1.5.3.3 |
| B18 | A only | **A, C** | Secure views hide the definition **and** are what you share with other accounts. Watch "Choose two". | 1.5.4.3, 5.2.2 |
| B19 | D | **C** | CREATE/SHOW/DDL run in **cloud services**; unfiltered COUNT(*) is answered from **metadata**. A filtered AVG has to scan data, so it needs a warehouse. | 1.1.1, 4.3 |
| B20 | A | **C** | Preferred identifier is **`orgname-accountname`**. `xy12345` is the legacy account locator. | 2.1.9 |

## Weak areas by exam domain

1. **Domain 1.0 (31%), table types and their limits.** B12 and B15 are both transient-table rules, and that's Day 1 material (1.5.3.3). Drill: permanent vs transient vs temporary — Time Travel range, Fail-safe, can you convert. 
2. **Domain 1.0, what needs a warehouse.** B19 plus A10 (right) are the same idea: cloud services and metadata answer DDL, SHOW and simple aggregates. Tie this to 1.1.1 and the caching objective 4.3 on Day 3.
3. **Domain 1.0, scale up vs scale out.** A2 and A7 are the two sides of one rule: queuing → more clusters; spilling → bigger size. This is today's Day 2 topic (1.4.4), so focus on it.
4. **Edition gating (1.1.4).** B3 and B4 right but A9 wrong. Memorize: Enterprise = multi-cluster, 90-day Time Travel, materialized views, masking/row access policies; Business Critical = PrivateLink, HIPAA/PCI, Tri-Secret Secure.
5. **Not yet studied (expected):** reader accounts (5.2.1.3), cloning (5.1.3), account identifiers (2.1.9). These come on Days 4–6; just log them.

Also: read the "(Choose two)" cue on every question. B18 was lost to picking one answer.
