-- Standardise region names from every source to dim_region.region_key.
-- ACLED uses English names; DHS splits Douala and Yaounde out of Littoral and Centre;
-- French sources use 'Extreme-Nord', 'Nord-Ouest', 'Sud-Ouest', 'Adamaoua', 'Est', 'Ouest', 'Sud'.
-- The same CASE is used for every source, so keep it in one place if your SQL has views or functions.

INSERT INTO fact_conflict_year (region_key, year, events, fatalities)
SELECT region_key, CAST(year AS INT), COUNT(*), SUM(CAST(fatalities AS INT))
FROM (
    SELECT year, fatalities,
        CASE UPPER(REPLACE(REPLACE(TRIM(admin1), '-', ''), ' ', ''))
            WHEN 'NORTHWEST'   THEN 'NORTHWEST' WHEN 'NORDOUEST' THEN 'NORTHWEST'
            WHEN 'SOUTHWEST'   THEN 'SOUTHWEST' WHEN 'SUDOUEST'  THEN 'SOUTHWEST'
            WHEN 'FARNORTH'    THEN 'FARNORTH'  WHEN 'EXTREMENORD' THEN 'FARNORTH'
            WHEN 'ADAMAOUA'    THEN 'ADAMAWA'   WHEN 'ADAMAWA'   THEN 'ADAMAWA'
            WHEN 'NORD'        THEN 'NORTH'     WHEN 'NORTH'     THEN 'NORTH'
            WHEN 'EST'         THEN 'EAST'      WHEN 'EAST'      THEN 'EAST'
            WHEN 'OUEST'       THEN 'WEST'      WHEN 'WEST'      THEN 'WEST'
            WHEN 'SUD'         THEN 'SOUTH'     WHEN 'SOUTH'     THEN 'SOUTH'
            WHEN 'CENTRE'      THEN 'CENTRE'    WHEN 'CENTER'    THEN 'CENTRE'
            WHEN 'LITTORAL'    THEN 'LITTORAL'
        END AS region_key
    FROM raw_acled
) a
WHERE region_key IS NOT NULL
GROUP BY region_key, CAST(year AS INT);

-- DHS: fold Douala into Littoral and Yaounde into Centre only if you have population weights;
-- otherwise keep them out and say so. This version keeps the 10 regions and drops the two cities.
INSERT INTO fact_dhs (region_key, survey_year, indicator, value)
SELECT r.region_key, CAST(d.survey_year AS INT), TRIM(d.indicator), CAST(d.value AS DECIMAL(6, 1))
FROM raw_dhs d
JOIN dim_region r
  ON UPPER(REPLACE(REPLACE(TRIM(d.region), '-', ''), ' ', '')) = r.region_key
WHERE NULLIF(TRIM(d.value), '') IS NOT NULL;

-- Check: which source region names did not match? (should be only Douala and Yaounde for DHS)
-- SELECT DISTINCT region FROM raw_dhs d WHERE NOT EXISTS
--   (SELECT 1 FROM dim_region r WHERE r.region_key = UPPER(REPLACE(REPLACE(TRIM(d.region), '-', ''), ' ', '')));
