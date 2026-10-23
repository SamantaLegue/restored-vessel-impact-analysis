-- =====================================================================
-- Clean the raw intake register into dim_youth.
-- Problems found when profiling raw_youth_intake:
--   1. 12 duplicate rows (same youth entered twice)
--   2. Region spelled many ways: 'North West', 'NW', 'littoral', 'Littoral (Douala)', 'Extreme Nord'...
--   3. Gender as 'F', 'f', 'female', 'M'...
--   4. Missing ages and impossible ages (2, 99, 180)
--   5. Some referral sources typed in CAPITALS
--   6. Empty strings instead of NULL for exit_date / exit_reason
-- =====================================================================

-- Profiling queries (run these first to see the problems)
-- SELECT youth_id, COUNT(*) FROM raw_youth_intake GROUP BY youth_id HAVING COUNT(*) > 1;
-- SELECT home_region, COUNT(*) FROM raw_youth_intake GROUP BY home_region ORDER BY home_region;
-- SELECT gender, COUNT(*) FROM raw_youth_intake GROUP BY gender;
-- SELECT age FROM raw_youth_intake WHERE age IS NULL OR TRIM(age) = '' OR CAST(age AS INT) NOT BETWEEN 10 AND 30;

INSERT INTO dim_youth (
    youth_id, intake_date, age_at_intake, age_band, gender, home_region, is_displaced_nw_sw,
    primary_issue, referral_source, education_at_intake, exit_date, exit_reason)
SELECT
    youth_id,
    intake_date,
    age_clean,
    CASE WHEN age_clean IS NULL THEN 'Unknown'
         WHEN age_clean <= 15 THEN '13-15'
         WHEN age_clean <= 18 THEN '16-18'
         WHEN age_clean <= 21 THEN '19-21'
         ELSE '22-24' END,
    gender_clean,
    region_clean,
    CASE WHEN region_clean IN ('Northwest', 'Southwest') THEN 1 ELSE 0 END,
    primary_issue,
    source_clean,
    education_at_intake,
    exit_date,
    exit_reason
FROM (
    SELECT
        TRIM(youth_id) AS youth_id,
        TRIM(intake_date) AS intake_date,
        CASE WHEN NULLIF(TRIM(age), '') IS NULL THEN NULL
             WHEN CAST(TRIM(age) AS INT) BETWEEN 10 AND 30 THEN CAST(TRIM(age) AS INT)
             ELSE NULL END AS age_clean,
        CASE UPPER(TRIM(gender))
             WHEN 'F' THEN 'Female' WHEN 'FEMALE' THEN 'Female'
             WHEN 'M' THEN 'Male'   WHEN 'MALE'   THEN 'Male' END AS gender_clean,
        CASE UPPER(REPLACE(REPLACE(TRIM(home_region), '-', ''), ' ', ''))
             WHEN 'NORTHWEST'         THEN 'Northwest'
             WHEN 'NW'                THEN 'Northwest'
             WHEN 'SOUTHWEST'         THEN 'Southwest'
             WHEN 'SW'                THEN 'Southwest'
             WHEN 'LITTORAL'          THEN 'Littoral'
             WHEN 'LITTORAL(DOUALA)'  THEN 'Littoral'
             WHEN 'FARNORTH'          THEN 'Far North'
             WHEN 'EXTREMENORD'       THEN 'Far North'
             ELSE TRIM(home_region) END AS region_clean,
        TRIM(primary_issue) AS primary_issue,
        CASE UPPER(TRIM(referral_source))
             WHEN 'CHURCH'          THEN 'Church'
             WHEN 'STREET OUTREACH' THEN 'Street outreach'
             WHEN 'FAMILY'          THEN 'Family'
             WHEN 'SELF'            THEN 'Self'
             WHEN 'SCHOOL'          THEN 'School'
             WHEN 'POLICE / COURT'  THEN 'Police / court'
             WHEN 'NGO PARTNER'     THEN 'NGO partner'
             ELSE TRIM(referral_source) END AS source_clean,
        TRIM(education_at_intake) AS education_at_intake,
        NULLIF(TRIM(exit_date), '') AS exit_date,
        NULLIF(TRIM(exit_reason), '') AS exit_reason,
        ROW_NUMBER() OVER (PARTITION BY TRIM(youth_id) ORDER BY youth_id) AS rn
    FROM raw_youth_intake
) AS cleaned
WHERE rn = 1;

-- Checks after cleaning (each should return 0 rows)
-- SELECT youth_id FROM dim_youth GROUP BY youth_id HAVING COUNT(*) > 1;
-- SELECT DISTINCT home_region FROM dim_youth WHERE home_region NOT IN
--   ('Littoral','Northwest','Southwest','Centre','West','South','East','Adamawa','North','Far North');
-- SELECT * FROM dim_youth WHERE gender IS NULL;
