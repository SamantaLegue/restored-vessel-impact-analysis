-- A1. Conflict events per year: crisis regions against the rest of the country.
SELECT c.year,
       SUM(CASE WHEN r.is_nw_sw = 1 THEN c.events ELSE 0 END)     AS events_nw_sw,
       SUM(CASE WHEN r.is_nw_sw = 0 THEN c.events ELSE 0 END)     AS events_other,
       SUM(CASE WHEN r.is_nw_sw = 1 THEN c.fatalities ELSE 0 END) AS fatalities_nw_sw
FROM fact_conflict_year c
JOIN dim_region r ON r.region_key = c.region_key
GROUP BY c.year
ORDER BY c.year;

-- A2. Change in each DHS youth indicator between surveys, crisis regions against the rest.
--     (Simple average of regions. A population-weighted version is a good stretch goal.)
SELECT d.indicator,
       d.survey_year,
       ROUND(AVG(CASE WHEN r.is_nw_sw = 1 THEN d.value END), 1) AS avg_nw_sw,
       ROUND(AVG(CASE WHEN r.is_nw_sw = 0 THEN d.value END), 1) AS avg_other,
       ROUND(AVG(CASE WHEN r.is_nw_sw = 1 THEN d.value END)
           - AVG(CASE WHEN r.is_nw_sw = 0 THEN d.value END), 1) AS gap
FROM fact_dhs d
JOIN dim_region r ON r.region_key = d.region_key
GROUP BY d.indicator, d.survey_year
ORDER BY d.indicator, d.survey_year;

-- A3. Region league table for 2018: conflict intensity next to each indicator
--     (feeds the Power BI scatter plot).
SELECT r.region_name,
       r.is_nw_sw,
       d.indicator,
       d.value                                   AS value_2018,
       COALESCE(SUM(c.events), 0)                AS conflict_events_2017_2018
FROM dim_region r
JOIN fact_dhs d ON d.region_key = r.region_key AND d.survey_year = 2018
LEFT JOIN fact_conflict_year c ON c.region_key = r.region_key AND c.year IN (2017, 2018)
GROUP BY r.region_name, r.is_nw_sw, d.indicator, d.value
ORDER BY d.indicator, conflict_events_2017_2018 DESC;
