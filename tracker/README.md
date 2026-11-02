# Study guide tracker

Every domain, objective and bullet from the official COF-C03 study guide (`SnowProCoreStudyGuideC03.pdf`, last updated July 8, 2026), one row each, worded as in the guide.

- `snowpro-core-study-guide-tracker.xlsx`: tick ✓ in the **Done** column of the Tracker sheet and set **Confidence** (Low, Medium, High). The **Progress** sheet counts done points per domain and per objective, and weights them by the domain percentages.
- `snowpro-core-study-guide-tracker.csv`: the same rows for Google Sheets or anything else.
- `build_tracker.py`: regenerates both files (`python3 tracker/build_tracker.py`). It overwrites any ticks, so re-run it only to change the structure.

Progress counts only the lowest-level points (134 of them). The two topics the guide marks as not tested until they are generally available, the default warehouse for Notebooks and Openflow, are greyed out and not counted. The **Plan day** and **Lesson** columns come from `snowpro-core-7-day-plan.md`; Day 1 (1.1, 1.3, 1.5) is marked as delivered.
