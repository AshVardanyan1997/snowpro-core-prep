"""Build the SnowPro Core (COF-C03) study-guide tracker as CSV and XLSX.

Source: SnowProCoreStudyGuideC03.pdf (official guide, last updated July 8, 2026).
Run: python3 tracker/build_tracker.py
"""
import csv
from pathlib import Path

from openpyxl import Workbook
from openpyxl.formatting.rule import FormulaRule
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

OUT = Path(__file__).resolve().parent
NOT_TESTED = "Not tested until globally GA"

DOMAINS = [
    ("1.0", "Snowflake AI Data Cloud Features and Architecture", 0.31),
    ("2.0", "Account Management and Data Governance", 0.20),
    ("3.0", "Data Loading, Unloading, and Connectivity", 0.18),
    ("4.0", "Performance Optimization, Querying, and Transformation", 0.21),
    ("5.0", "Data Collaboration", 0.10),
]

# Objective -> study-plan day (snowpro-core-7-day-plan.md)
PLAN_DAY = {
    "1.1": 1, "1.3": 1, "1.5": 1,
    "1.2": 2, "1.4": 2, "1.6": 2,
    "4.1": 3, "4.2": 3, "4.3": 3,
    "4.4": 4, "2.1": 4,
    "2.2": 5, "2.3": 5, "3.1": 5,
    "3.2": 6, "3.3": 6, "5.1": 6, "5.2": 6, "5.3": 6,
}
DELIVERED_DAYS = {1}  # lesson materials already in the repo (day-1/)
PLAN_DATES = {1: "Mon Nov 2", 2: "Tue Nov 3", 3: "Wed Nov 4", 4: "Thu Nov 5",
              5: "Fri Nov 6", 6: "Sat Nov 7"}

# Bullets exactly as worded in the guide. A tuple is (text, [children]).
# A text ending in "*" is flagged not tested.
OBJECTIVES = {
    "1.1": ("Describe and use the Snowflake architecture", [
        "Cloud Services layer", "Compute layer", "Database Storage layer",
        "Compare and contrast the different Snowflake editions"]),
    "1.2": ("Use Snowflake Interfaces and tools", [
        "Snowsight", "Snowflake CLI", "IDE integrations (e.g., Visual Studio Code)"]),
    "1.3": ("Differentiate Snowflake object hierarchy and types", [
        "Organization and account objects",
        ("Database objects", ["Stages", "Schemas", "Tables", "Views",
                              "User-Defined Functions (UDFs)", "File formats",
                              "Stored procedures", "Pipes", "Shares", "Sequences",
                              "ML models", "Applications"]),
        ("Session and context variables", ["Parameter hierarchy", "Parameter precedence"])]),
    "1.4": ("Configure virtual warehouses", [
        ("Types", ["Snowpark Optimized", "Standard (Gen 1 and Gen 2)",
                   "Default warehouse for Notebooks*"]),
        "Scaling policies",
        ("Warehouse type and configurations based on use cases",
         ["Ad-hoc queries", "Data loading", "BI and reporting"]),
        ("Best practices", ["Sizing (up, down)", "Scaling (in, out)", "Auto-Suspend",
                            ("Workloads", ["Different teams", "High concurrency",
                                           "Complex queries"])])]),
    "1.5": ("Explain Snowflake storage concepts", [
        "Micro-partitions", "Data clustering",
        ("Table types", ["Permanent", "Temporary", "Transient", "Apache Iceberg",
                         "External", "Dynamic"]),
        ("Views types", ["Standard", "Materialized", "Secure"])]),
    "1.6": ("Explain AI/ML and application development features", [
        "Snowflake Notebooks", "Streamlit in Snowflake", "Snowpark",
        ("Snowflake Cortex", ["AI SQL functions", "Cortex Search", "Cortex Analyst"]),
        "Snowflake ML"]),
    "2.1": ("Explain Snowflake security model and principles", [
        "Role-Based Access Control (RBAC)", "Securable object hierarchy",
        "Discretionary access control (DAC)", "Network Policies",
        ("Authentication", ["Multi-Factor Authentication (MFA)", "Federated Authentication",
                            "Single Sign-on (SSO)", "OAuth", "Key-pair authentication"]),
        "System-defined roles",
        ("Functional roles", ["Account roles", "Database roles", "Custom roles"]),
        "Secondary roles", "Account identifiers", "Logging and tracing"]),
    "2.2": ("Define data governance features and how they are used", [
        ("Data masking", ["Row-level security", "Column-level security"]),
        "Object tagging", "Privacy policies", "Trust Center", "Encryption key management",
        "Alerts", "Notifications", "Data replication and failover", "Data lineage"]),
    "2.3": ("Explain monitoring and cost management", [
        ("Resource Monitors", ["Cost and warehouse monitoring"]),
        "Calculating virtual warehouse credit usage", "ACCOUNT_USAGE schema"]),
    "3.1": ("Perform data loading and unloading", [
        "File formats",
        ("Create and use stages", ["Internal stages", "External stages",
                                   "Server-side encryption", "Directory tables"]),
        "COPY INTO command", "Error handling options"]),
    "3.2": ("Perform automated data ingestion", [
        "Snowpipe", "Snowpipe streaming", "Streams", "Tasks", "Dynamic tables", "Openflow*"]),
    "3.3": ("Identify the different Snowflake Connectors and integrations", [
        "Snowflake drivers", "Snowflake connectors", "Storage integration",
        "API integration", "Git integration"]),
    "4.1": ("Evaluate query performance", [
        ("Query Performance Tuning", [
            ("Query Profile/Query insights", ["Bytes spilled to storage", "Inefficient pruning",
                                              "Exploding joins", "Queuing"])]),
        ("SNOWFLAKE.ACCOUNT_USAGE views (Snowflake database views)",
         ["Query attribution", "Query history"]),
        ("Workload management best practices", ["Grouping similar workloads"])]),
    "4.2": ("Optimize query performance", [
        "Query acceleration service", "Search optimization service", "Clustering keys",
        "Materialized views"]),
    "4.3": ("Use Snowflake caching", [
        "Query result cache", "Metadata cache", "Warehouse cache"]),
    "4.4": ("Perform data transformation techniques", [
        ("Using data", ["Structured", "Semi-structured", "Unstructured"]),
        "Aggregate functions", "Applying SQL for query optimization", "Window functions"]),
    "5.1": ("Explain data collaboration and protection", [
        "Data replication and failover", "Secure data sharing features", "Cloning",
        "Time Travel", "Fail-safe"]),
    "5.2": ("Explain Snowflake's data sharing capabilities", [
        ("Accounts", ["Provider", "Consumer", "Reader accounts"]),
        "Secure Data Sharing", "Sharing and resharing", "Direct shares", "Data clean rooms"]),
    "5.3": ("Share data using the Snowflake Marketplace and listings", [
        "Snowflake Marketplace", ("Listings", ["Private", "Public"]), "Native Apps"]),
}

HEADERS = ["ID", "Domain", "Domain weight", "Objective", "Level", "Point",
           "Full path", "Has sub-points", "Plan day", "Lesson", "Exam note",
           "Done", "Confidence", "Notes"]


def build_rows():
    rows = []
    for dnum, dname, weight in DOMAINS:
        dkey = dnum.split(".")[0]
        for onum, (oname, bullets) in OBJECTIVES.items():
            if not onum.startswith(dkey + "."):
                continue
            day = PLAN_DAY[onum]
            lesson = (f"Day {day} lesson delivered" if day in DELIVERED_DAYS
                      else f"Day {day} (planned, {PLAN_DATES[day]})")
            base = dict(domain=f"{dnum} {dname}", weight=weight,
                        objective=f"{onum} {oname}", day=day, lesson=lesson)
            rows.append({**base, "id": onum, "level": 1, "point": f"{onum} {oname}",
                         "path": oname, "has_children": "Yes", "note": ""})

            def walk(items, prefix, path, level):
                for i, item in enumerate(items, 1):
                    text, kids = (item if isinstance(item, tuple) else (item, []))
                    note = NOT_TESTED if text.endswith("*") else ""
                    text = text.rstrip("*")
                    pid = f"{prefix}.{i}"
                    full = f"{path} > {text}" if path else text
                    rows.append({**base, "id": pid, "level": level, "point": text,
                                 "path": full, "has_children": "Yes" if kids else "No",
                                 "note": note})
                    walk(kids, pid, full, level + 1)

            walk(bullets, onum, "", 2)
    return rows


def to_record(r):
    return [r["id"], r["domain"], f'{round(r["weight"] * 100)}%', r["objective"],
            r["level"], r["point"], r["path"], r["has_children"], r["day"],
            r["lesson"], r["note"], "", "", ""]


def write_csv(rows):
    with open(OUT / "snowpro-core-study-guide-tracker.csv", "w", newline="",
              encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(HEADERS)
        for r in rows:
            w.writerow(to_record(r))


def write_xlsx(rows):
    wb = Workbook()
    thin = Side(style="thin", color="D0D5DD")
    border = Border(bottom=thin)
    head_fill = PatternFill("solid", fgColor="1F3A5F")
    head_font = Font(bold=True, color="FFFFFF")
    obj_fill = PatternFill("solid", fgColor="DCE6F2")

    # ---------- Tracker sheet ----------
    ws = wb.active
    ws.title = "Tracker"
    cols = ["ID", "Domain", "Weight", "Objective", "Point (indented as in the guide)",
            "Plan day", "Lesson", "Exam note", "Done", "Confidence", "Notes", "Level",
            "Countable"]
    ws.append(cols)
    for c in ws[1]:
        c.fill, c.font = head_fill, head_font
        c.alignment = Alignment(vertical="center", wrap_text=True)
    for r in rows:
        countable = "Yes" if r["has_children"] == "No" and not r["note"] else "No"
        ws.append([r["id"], r["domain"], r["weight"], r["objective"], r["point"],
                   r["day"], r["lesson"], r["note"], "", "", "", r["level"], countable])
        row = ws.max_row
        ws.cell(row, 3).number_format = "0%"
        ws.cell(row, 5).alignment = Alignment(indent=(r["level"] - 1) * 2)
        for c in ws[row]:
            c.border = border
            c.alignment = Alignment(indent=c.alignment.indent, vertical="top",
                                    wrap_text=c.column in (5, 11))
        ws.cell(row, 9).alignment = Alignment(horizontal="center")
        if r["level"] == 1:
            for c in ws[row]:
                c.fill = obj_fill
                c.font = Font(bold=True)
        if r["note"]:
            for c in ws[row]:
                c.font = Font(italic=True, color="98A2B3")
    last = ws.max_row
    widths = [9, 30, 8, 34, 52, 8, 26, 24, 7, 12, 40, 6, 10]
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = w
    ws.freeze_panes = "F2"
    ws.auto_filter.ref = f"A1:{get_column_letter(len(cols))}{last}"

    dv_done = DataValidation(type="list", formula1='"✓"', allow_blank=True,
                             errorTitle="Done", error="Pick ✓ or leave blank.")
    dv_conf = DataValidation(type="list", formula1='"Low,Medium,High"', allow_blank=True)
    ws.add_data_validation(dv_done)
    ws.add_data_validation(dv_conf)
    dv_done.add(f"I2:I{last}")
    dv_conf.add(f"J2:J{last}")
    rng = f"A2:K{last}"
    ws.conditional_formatting.add(rng, FormulaRule(
        formula=['$I2="✓"'], fill=PatternFill("solid", fgColor="D1FADF")))
    ws.conditional_formatting.add(f"J2:J{last}", FormulaRule(
        formula=['$J2="Low"'], fill=PatternFill("solid", fgColor="FEE4E2")))
    ws.conditional_formatting.add(f"J2:J{last}", FormulaRule(
        formula=['$J2="Medium"'], fill=PatternFill("solid", fgColor="FEF0C7")))

    # ---------- Progress sheet ----------
    ps = wb.create_sheet("Progress", 0)
    ps["A1"] = "SnowPro Core COF-C03 · study guide progress"
    ps["A1"].font = Font(bold=True, size=14)
    ps["A2"] = ("Tick ✓ in the Done column of the Tracker sheet. Progress counts the "
                "lowest-level points only, and leaves out the two not-tested topics.")
    ps["A2"].font = Font(italic=True, color="667085")
    hdr = ["Domain", "Weight", "Points", "Done", "% done", "Weighted progress",
           "Low confidence"]
    ps.append([])
    ps.append(hdr)
    for c in ps[4]:
        c.fill, c.font = head_fill, head_font
    T = f"Tracker!$B$2:$B${last}"
    CNT = f"Tracker!$M$2:$M${last}"
    DONE = f"Tracker!$I$2:$I${last}"
    CONF = f"Tracker!$J$2:$J${last}"
    start = 5
    for i, (dnum, dname, weight) in enumerate(DOMAINS):
        r = start + i
        ps.cell(r, 1, f"{dnum} {dname}")
        ps.cell(r, 2, weight).number_format = "0%"
        ps.cell(r, 3, f'=COUNTIFS({T},A{r},{CNT},"Yes")')
        ps.cell(r, 4, f'=COUNTIFS({T},A{r},{CNT},"Yes",{DONE},"✓")')
        ps.cell(r, 5, f"=IF(C{r}=0,0,D{r}/C{r})").number_format = "0%"
        ps.cell(r, 6, f"=B{r}*E{r}").number_format = "0.0%"
        ps.cell(r, 7, f'=COUNTIFS({T},A{r},{CONF},"Low")')
    tot = start + len(DOMAINS)
    ps.cell(tot, 1, "Total").font = Font(bold=True)
    ps.cell(tot, 2, f"=SUM(B{start}:B{tot-1})").number_format = "0%"
    ps.cell(tot, 3, f"=SUM(C{start}:C{tot-1})")
    ps.cell(tot, 4, f"=SUM(D{start}:D{tot-1})")
    ps.cell(tot, 5, f"=IF(C{tot}=0,0,D{tot}/C{tot})").number_format = "0%"
    ps.cell(tot, 6, f"=SUM(F{start}:F{tot-1})").number_format = "0.0%"
    ps.cell(tot, 7, f"=SUM(G{start}:G{tot-1})")
    for c in ps[tot]:
        c.font = Font(bold=True)
        c.border = Border(top=Side(style="thin"))
    ps.conditional_formatting.add(f"E{start}:E{tot}", FormulaRule(
        formula=[f"E{start}>=1"], fill=PatternFill("solid", fgColor="D1FADF")))

    # Per-objective table
    r0 = tot + 2
    ps.cell(r0, 1, "By objective").font = Font(bold=True, size=12)
    ps.append(["Objective", "Plan day", "Points", "Done", "% done", "Lesson"])
    for c in ps[r0 + 1]:
        c.fill, c.font = head_fill, head_font
    OBJ = f"Tracker!$D$2:$D${last}"
    r = r0 + 2
    for onum, (oname, _) in sorted(OBJECTIVES.items(),
                                   key=lambda kv: [int(x) for x in kv[0].split(".")]):
        day = PLAN_DAY[onum]
        ps.cell(r, 1, f"{onum} {oname}")
        ps.cell(r, 2, day)
        ps.cell(r, 3, f'=COUNTIFS({OBJ},A{r},{CNT},"Yes")')
        ps.cell(r, 4, f'=COUNTIFS({OBJ},A{r},{CNT},"Yes",{DONE},"✓")')
        ps.cell(r, 5, f"=IF(C{r}=0,0,D{r}/C{r})").number_format = "0%"
        ps.cell(r, 6, "Delivered" if day in DELIVERED_DAYS else "Planned")
        r += 1
    ps.conditional_formatting.add(f"E{r0+2}:E{r-1}", FormulaRule(
        formula=[f"E{r0+2}>=1"], fill=PatternFill("solid", fgColor="D1FADF")))
    for col, w in zip("ABCDEFG", [62, 9, 8, 8, 9, 18, 15]):
        ps.column_dimensions[col].width = w
    ps.freeze_panes = "A5"

    wb.save(OUT / "snowpro-core-study-guide-tracker.xlsx")


if __name__ == "__main__":
    rows = build_rows()
    write_csv(rows)
    write_xlsx(rows)
    leaves = sum(1 for r in rows if r["has_children"] == "No" and not r["note"])
    print(f"{len(rows)} rows, {leaves} countable points")
