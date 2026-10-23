# From need to response: measuring a youth ministry's impact in Douala

A two-part data analysis portfolio project by Samantha, founder of The Restored Vessel, a faith-based ministry in Douala, Cameroon, for young people caught in addiction, crime or sexual exploitation.

**Tools:** SQL (data modelling, cleaning, KPIs), Power BI (data model, DAX, report), Python (synthetic data only).

> Part 2 uses **synthetic data**. No real young person's information is used anywhere in this project. That is a deliberate safeguarding choice: the people a ministry like this serves are minors and survivors of exploitation, and their records should never be in a public portfolio.

---

## The question

Young people from the Northwest and Southwest regions have been pushed toward cities like Douala by the Anglophone crisis since 2016. Many arrive out of school and at risk.

1. **Part 1, the need:** What does public data show about youth in the crisis regions compared with the rest of Cameroon?
2. **Part 2, the response:** If a small ministry wants to show funders it works, what should it track, and what would the numbers tell it?

## Part 1: Youth at risk in Cameroon (public data)

Folder: `part1-public-data/`

- **Sources:** ACLED conflict events, the Cameroon DHS (2004, 2011, 2018) by region, World Bank youth unemployment and NEET, and IOM/OCHA displacement figures. Full list and download steps in `SOURCES_AND_STEPS.md`.
- **SQL:** `01_tables.sql` (a region lookup that every source joins to), `02_clean.sql` (one mapping for English and French region names), `03_analysis.sql` (conflict trend, indicator gap between crisis and other regions, 2018 region league table).
- **Status:** to do. Download the files, run the scripts, and write the findings here.

## Part 2: The Restored Vessel impact tracker (synthetic data)

Folder: `part2-impact-tracker/`

### Data model

A star schema, built for Power BI:

- `dim_youth`: one row per young person (age band, gender, home region, main issue, referral source, exit)
- `dim_date`: calendar with a running `day_number`, so date gaps are plain subtraction in any SQL dialect
- `fact_sessions`: 13,363 sessions (mentoring, group, counselling, Bible study, skills training)
- `fact_referrals`: 889 referrals to outside services
- `fact_outcomes`: 1,269 assessments at intake, 3, 6 and 12 months

### Cleaning

The raw intake register (`data/raw_youth_intake.csv`) has the problems real registers have: 12 duplicate entries, regions typed many ways ("North West", "NW", "Littoral (Douala)", "Extreme Nord"), gender as F/f/female, missing and impossible ages, and inconsistent capitals. `sql/02_clean.sql` profiles and fixes each one, with checks that should return no rows.

### Findings (synthetic data)

| Metric | Result | SQL |
|---|---|---|
| Young people served, Jan 2024 to Sep 2026 | 500 (202 still active) | Q11 |
| Still engaged at 3 / 6 / 12 months | 79% / 64% / 42% | Q3 |
| Wellbeing gain, intake to 6 months (same youth, 1 to 10 scale) | +2.4 points | Q11 |
| Drug-free at 6 months, youth who came in for substance use | 55% (from 0% at intake) | Q5, Q11 |
| Displaced youth (NW/SW): wellbeing at intake | 3.2 against 3.9 for other youth | Q9 |
| Referral completion, lowest service | Rehabilitation centres, 60% | Q7 |
| Biggest reason youth leave | Lost contact, 31% of all youth | Q10 |

**Recommendations a ministry could act on:**
1. Follow up within two weeks when a young person misses sessions. Lost contact is the biggest leak, and retention drops sharply after month 6.
2. Aim for at least six sessions in the first 90 days. Youth with 0 to 5 early sessions gained the least wellbeing.
3. Review the rehabilitation centre partnership, which has the lowest completion rate.
4. Give displaced youth extra early support. They arrive with lower wellbeing and more have dropped out of school.

### Limitations

- The data is synthetic. The patterns come from rules in `generate_data.py`, so they show the method, not real results.
- Later check-ins only include youth who could still be reached, so averages at 6 and 12 months lean positive. Paired measures (same youth at intake and 6 months) are used for the headline figures to reduce this.
- Some groups are small (for example 40 youth in the 13+ sessions band), so differences between them could be noise.

### Files

| File | What it is |
|---|---|
| `generate_data.py` | Makes the synthetic CSVs (fixed seed, so anyone gets the same data) |
| `data/*.csv` | Raw intake register, sessions, referrals, outcomes, calendar |
| `sql/01_create_tables.sql` | Table design |
| `sql/02_clean_youth.sql` | Profiling and cleaning |
| `sql/03_kpi_queries.sql` | 11 KPI queries, each answering one question |
| `results/*.csv` | Output of each KPI query |
| `build_sqlite.py`, `restored_vessel.db` | A ready SQLite copy for quick checking (open in DB Browser for SQLite) |
| `powerbi/POWER_BI_GUIDE.md` | Model, relationships and report page layout |
| `powerbi/measures.dax` | 19 DAX measures |

## How to publish this

1. Create a GitHub repository, upload the `portfolio` folder, and use this README as its front page.
2. Build the Power BI report from the guide, publish it to the web or export it to PDF, and add screenshots to this README.
3. Write a short LinkedIn post about why you built it. Your story as the founder is what makes this project different from a standard dataset.
