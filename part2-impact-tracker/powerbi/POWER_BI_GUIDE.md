# Power BI build guide: Restored Vessel impact tracker

Everything here uses synthetic data. Say so on the report's cover page.

## 1. Get the data in

Choose one of these:

- **From SQL Server (shows off SQL best).** Create a database, run `sql/01_create_tables.sql`, load `data/raw_youth_intake.csv` into `raw_youth_intake` and `data/dim_date.csv` into `dim_date` (SSMS: right-click the database > Tasks > Import Flat File), run `sql/02_clean_youth.sql`, then load `sessions.csv`, `referrals.csv` and `outcomes.csv` into the three fact tables. In Power BI: Get data > SQL Server, and pick `dim_youth`, `dim_date` and the three `fact_` tables.
- **Straight from the CSVs (quickest).** Get data > Text/CSV for each file. Do the raw intake cleaning in Power Query instead (Trim, Replace values, Remove duplicates on `youth_id`) and write a note in the case study that the SQL version does the same.

Set data types in Power Query: dates as Date, flags (`attended`, `completed`, `substance_free_30d` and so on) as Whole number.

## 2. Model (star schema)

| From | To | Cardinality | Active |
|---|---|---|---|
| dim_youth[youth_id] | fact_sessions[youth_id] | 1 to many | yes |
| dim_youth[youth_id] | fact_referrals[youth_id] | 1 to many | yes |
| dim_youth[youth_id] | fact_outcomes[youth_id] | 1 to many | yes |
| dim_date[date] | fact_sessions[session_date] | 1 to many | yes |
| dim_date[date] | fact_referrals[referral_date] | 1 to many | yes |
| dim_date[date] | fact_outcomes[assessment_date] | 1 to many | yes |
| dim_date[date] | dim_youth[intake_date] | 1 to many | **no** (used by `New Intakes` with USERELATIONSHIP) |

Mark `dim_date` as a date table (Table tools > Mark as date table > `date`). Sort `month_name` by `month`. Hide the key columns on the fact tables.

## 3. Measures

Copy them from `measures.dax`.

## 4. Report pages

**Page 1. Overview (for a funder)**
- Cards: Youth Served, Active Youth, Contact Hours, Referral Completion Rate, Retention 6m
- Clustered column: New Intakes by `dim_date[year_quarter]`, legend `primary_issue`
- Donut: Youth Served by `primary_issue`
- Slicers: `gender`, `age_band`, `home_region`

**Page 2. Outcomes**
- Line chart: Avg Wellbeing, % In School or Work, % Safe Housing by `fact_outcomes[checkpoint_month]`
- Column: % Substance Free at month 0 and 6
- Card: Wellbeing Gain at 6m (paired), with a text box explaining why it is paired
- Line: % Reoffended by checkpoint

**Page 3. Engagement and partners**
- Bar: Referral Completion Rate by `service_type` (sorted ascending, so the weakest partner is at the top)
- Column: Sessions Attended by `session_type`
- Funnel or bar: exit reasons (`dim_youth[exit_reason]`, blanks shown as "Still in programme")

**Page 4. The crisis link (ties to Part 1)**
- Clustered column: Avg Wellbeing by checkpoint, legend `is_displaced_nw_sw` (rename the values "From NW/SW" and "Other regions")
- Card pair: % dropped out of school at intake, displaced and not
- Text box: one line on what Part 1 found about the Northwest and Southwest

## 5. Finishing touches recruiters notice

- A cover page with the question, the data (synthetic, with why), and three headline findings.
- One accent colour (the ministry's terracotta, `#C0623B`) and grey for everything else.
- Tooltips that say how each number is calculated.
- Publish to the web from Power BI Service (free account) or export to PDF, and link it from your portfolio and GitHub.
