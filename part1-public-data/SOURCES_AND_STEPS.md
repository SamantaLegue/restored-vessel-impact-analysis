# Part 1: Youth at risk in Cameroon (public data)

**Question:** Since the Anglophone crisis began in 2016, are young people in the Northwest and Southwest worse off than in other regions, and how many have been pushed toward cities like Douala?

This is the "need" half of the story. Part 2 (the impact tracker) is the "response" half.

I could not download these files from my side (my network blocks these sites), so the downloads are your job. That is good for the portfolio anyway: recruiters want to see that you found and pulled the data yourself.

## Sources (all free)

| # | Source | What to download | Level | Access |
|---|---|---|---|---|
| 1 | ACLED, Armed Conflict Location & Event Data ([acleddata.com](https://acleddata.com)) | Data export tool: country = Cameroon, 2014 to latest. Keep `event_date`, `year`, `event_type`, `sub_event_type`, `admin1`, `fatalities`, `actor1`. | Event, by region (`admin1`) | Free account (register with your email) |
| 2 | Cameroon DHS 2018 ([report FR360](https://dhsprogram.com/publications/publication-FR360-DHS-Final-Reports.cfm), [key findings SR266](https://dhsprogram.com/publications/publication-SR266-Summary-Reports-Key-Findings.cfm)) | Use STATcompiler on dhsprogram.com: Cameroon, 2004, 2011 and 2018 surveys, broken down by region. Pick youth indicators that exist for all three: secondary school attendance, teenage pregnancy, youth literacy, tobacco use, unemployment. | Region (note: DHS reports Douala and Yaoundé separately from Littoral and Centre) | No account for STATcompiler; free registration for microdata |
| 3 | World Bank World Development Indicators ([data.worldbank.org](https://data.worldbank.org)) | Cameroon, 2000 to latest: youth unemployment 15-24 (`SL.UEM.1524.ZS`), youth not in education, employment or training (`SL.UEM.NEET.ZS`), secondary school enrolment (`SE.SEC.NENR`) | National, by year | None |
| 4 | Displacement: IOM Displacement Tracking Matrix and OCHA Cameroon on [HDX](https://data.humdata.org) (search "Cameroon IDP"). Background: UNHCR microdata catalogue entry on Cameroon IDPs ([link](https://microdata.unhcr.org/index.php/catalog/1134)) | Internally displaced persons by region of origin and region of arrival, latest round | Region | None |
| 5 | Context to cite: World Bank (2021), *The socio-political crisis in the Northwest and Southwest regions of Cameroon: assessing the economic and social impacts* ([PDF](https://www.investiraucameroun.com/docutheque/1204-20575-the-socio-political-crisis-in-the-northwest-and-southwest-regions-of-cameroon-assessing-the-economic-and-social-impacts/download/2937-world-bank-2021-07-pdf)) | Read for figures on school closures and displacement to quote in your write-up | | None |

Check each indicator's definition and survey year before you compare regions, and write that check into the case study.

## Steps

1. Download the files into `part1-public-data/raw/`. Do not edit them by hand.
2. Run `sql/01_tables.sql`, then load each CSV into its `raw_` table.
3. Run `sql/02_clean.sql`. It standardises region names so all sources join on one key (`region_key`).
4. Run `sql/03_analysis.sql`.
5. In Power BI, add a page with a filled map of the 10 regions (use `region_name` with "Cameroon" as country), a line chart of conflict events per year for NW/SW against the rest, and a scatter of conflict events against a DHS indicator by region.

## Findings to look for

- When did conflict events in the Northwest and Southwest rise, and how does that line up with the 2018 DHS?
- Did NW/SW youth indicators fall behind other regions between 2011 and 2018?
- How many displaced people arrived in Littoral (Douala), and what share are young?

Write down what the data does **not** show too. DHS 2018 fieldwork in NW/SW was affected by insecurity, so read the report's notes on coverage there.
