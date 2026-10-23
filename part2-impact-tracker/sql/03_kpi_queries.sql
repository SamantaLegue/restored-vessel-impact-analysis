-- =====================================================================
-- The Restored Vessel impact tracker: KPI queries
-- Each query answers one question a ministry leader or funder would ask.
-- All data is SYNTHETIC. Dataset cut-off date: 2026-09-30.
-- =====================================================================


-- Q1. How many young people do we take in each quarter, and for what?
SELECT d.year_quarter,
       COUNT(*)                                                              AS new_youth,
       SUM(CASE WHEN y.primary_issue = 'Substance use'       THEN 1 ELSE 0 END) AS substance_use,
       SUM(CASE WHEN y.primary_issue = 'Crime'               THEN 1 ELSE 0 END) AS crime,
       SUM(CASE WHEN y.primary_issue = 'Sexual exploitation' THEN 1 ELSE 0 END) AS sexual_exploitation,
       SUM(CASE WHEN y.primary_issue = 'Multiple'            THEN 1 ELSE 0 END) AS multiple
FROM dim_youth y
JOIN dim_date d ON d.date = y.intake_date
GROUP BY d.year_quarter
ORDER BY d.year_quarter;


-- Q2. Who are we serving? Profile by issue, gender and displacement.
SELECT primary_issue,
       COUNT(*)                                                         AS youth,
       ROUND(100.0 * SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_female,
       ROUND(AVG(1.0 * age_at_intake), 1)                                AS avg_age,
       ROUND(100.0 * SUM(is_displaced_nw_sw) / COUNT(*), 1)              AS pct_from_nw_sw
FROM dim_youth
GROUP BY primary_issue
ORDER BY youth DESC;


-- Q3. Retention: of the youth who have been with us long enough to reach
--     each checkpoint, what share were still in the programme on that day?
WITH checkpoints AS (
    SELECT 3 AS months, 91 AS days UNION ALL
    SELECT 6, 182 UNION ALL
    SELECT 12, 365
),
youth_days AS (
    SELECT y.youth_id,
           di.day_number                                   AS intake_day,
           COALESCE(de.day_number, (SELECT MAX(day_number) FROM dim_date)) AS last_day,
           (SELECT MAX(day_number) FROM dim_date)          AS cutoff_day
    FROM dim_youth y
    JOIN dim_date di ON di.date = y.intake_date
    LEFT JOIN dim_date de ON de.date = y.exit_date
)
SELECT c.months,
       COUNT(*)                                                           AS eligible_youth,
       SUM(CASE WHEN yd.last_day - yd.intake_day >= c.days THEN 1 ELSE 0 END) AS still_engaged,
       ROUND(100.0 * SUM(CASE WHEN yd.last_day - yd.intake_day >= c.days THEN 1 ELSE 0 END) / COUNT(*), 1) AS retention_pct
FROM checkpoints c
JOIN youth_days yd ON yd.cutoff_day - yd.intake_day >= c.days
GROUP BY c.months
ORDER BY c.months;


-- Q4. Do outcomes improve over time? Average and rates at each checkpoint.
--     (Only youth who were assessed at that checkpoint are counted.)
SELECT o.checkpoint_month,
       COUNT(*)                                       AS assessed,
       ROUND(AVG(1.0 * o.wellbeing_score), 2)         AS avg_wellbeing,
       ROUND(100.0 * SUM(o.in_school_or_work) / COUNT(*), 1) AS pct_school_or_work,
       ROUND(100.0 * SUM(o.safe_housing) / COUNT(*), 1)      AS pct_safe_housing
FROM fact_outcomes o
GROUP BY o.checkpoint_month
ORDER BY o.checkpoint_month;


-- Q5. Substance-free rate for youth who came in for substance use,
--     comparing the same young people at intake and at 6 months (paired).
SELECT y.primary_issue,
       COUNT(*)                                                    AS youth_with_both,
       ROUND(100.0 * SUM(o0.substance_free_30d) / COUNT(*), 1)      AS pct_free_at_intake,
       ROUND(100.0 * SUM(o6.substance_free_30d) / COUNT(*), 1)      AS pct_free_at_6m
FROM dim_youth y
JOIN fact_outcomes o0 ON o0.youth_id = y.youth_id AND o0.checkpoint_month = 0
JOIN fact_outcomes o6 ON o6.youth_id = y.youth_id AND o6.checkpoint_month = 6
WHERE y.primary_issue IN ('Substance use', 'Multiple')
GROUP BY y.primary_issue;


-- Q6. Does engagement matter? Sessions attended in the first 90 days
--     against wellbeing gain and school/work at 6 months.
WITH early AS (
    SELECT y.youth_id,
           SUM(CASE WHEN s.attended = 1 AND ds.day_number - di.day_number < 90 THEN 1 ELSE 0 END) AS sessions_90d
    FROM dim_youth y
    JOIN dim_date di ON di.date = y.intake_date
    LEFT JOIN fact_sessions s ON s.youth_id = y.youth_id
    LEFT JOIN dim_date ds ON ds.date = s.session_date
    GROUP BY y.youth_id
),
banded AS (
    SELECT youth_id,
           CASE WHEN sessions_90d < 6  THEN '1. 0-5 sessions'
                WHEN sessions_90d < 13 THEN '2. 6-12 sessions'
                ELSE                        '3. 13+ sessions' END AS engagement_band
    FROM early
)
SELECT b.engagement_band,
       COUNT(*)                                                    AS youth_assessed_at_6m,
       ROUND(AVG(1.0 * o6.wellbeing_score - o0.wellbeing_score), 2) AS avg_wellbeing_gain,
       ROUND(100.0 * SUM(o6.in_school_or_work) / COUNT(*), 1)       AS pct_school_or_work_6m
FROM banded b
JOIN fact_outcomes o0 ON o0.youth_id = b.youth_id AND o0.checkpoint_month = 0
JOIN fact_outcomes o6 ON o6.youth_id = b.youth_id AND o6.checkpoint_month = 6
GROUP BY b.engagement_band
ORDER BY b.engagement_band;


-- Q7. Which partner services actually deliver? Referral completion rate.
SELECT service_type,
       COUNT(*)                                       AS referrals,
       SUM(completed)                                 AS completed,
       ROUND(100.0 * SUM(completed) / COUNT(*), 1)    AS completion_pct
FROM fact_referrals
GROUP BY service_type
ORDER BY completion_pct;


-- Q8. Reoffending among youth who came in for crime, by checkpoint.
SELECT o.checkpoint_month,
       COUNT(*)                                                   AS assessed,
       ROUND(100.0 * SUM(o.reoffended_since_last) / COUNT(*), 1)  AS reoffended_pct
FROM fact_outcomes o
JOIN dim_youth y ON y.youth_id = o.youth_id
WHERE y.primary_issue IN ('Crime', 'Multiple')
  AND o.checkpoint_month > 0
GROUP BY o.checkpoint_month
ORDER BY o.checkpoint_month;


-- Q9. The link to Part 1: do youth displaced from the Northwest and
--     Southwest arrive in a worse position, and do they recover as well?
SELECT CASE WHEN y.is_displaced_nw_sw = 1 THEN 'From NW/SW' ELSE 'Other regions' END AS origin,
       COUNT(DISTINCT y.youth_id)                                         AS youth,
       ROUND(100.0 * SUM(CASE WHEN y.education_at_intake = 'Dropped out' THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                               AS pct_dropped_out_at_intake,
       ROUND(AVG(1.0 * o0.wellbeing_score), 2)                            AS avg_wellbeing_intake,
       ROUND(AVG(1.0 * o6.wellbeing_score), 2)                            AS avg_wellbeing_6m
FROM dim_youth y
JOIN fact_outcomes o0 ON o0.youth_id = y.youth_id AND o0.checkpoint_month = 0
LEFT JOIN fact_outcomes o6 ON o6.youth_id = y.youth_id AND o6.checkpoint_month = 6
GROUP BY CASE WHEN y.is_displaced_nw_sw = 1 THEN 'From NW/SW' ELSE 'Other regions' END;


-- Q10. Why do young people leave?
SELECT COALESCE(exit_reason, 'Still in programme') AS status,
       COUNT(*)                                     AS youth,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dim_youth), 1) AS pct
FROM dim_youth
GROUP BY COALESCE(exit_reason, 'Still in programme')
ORDER BY youth DESC;


-- Q11. Headline figures for the dashboard cover (paired measures only).
SELECT
    (SELECT COUNT(*) FROM dim_youth)                                   AS youth_served,
    (SELECT COUNT(*) FROM dim_youth WHERE exit_date IS NULL)           AS active_youth,
    (SELECT SUM(attended) FROM fact_sessions)                          AS sessions_attended,
    (SELECT ROUND(1.0 * SUM(duration_min) / 60, 0) FROM fact_sessions WHERE attended = 1) AS contact_hours,
    (SELECT ROUND(100.0 * SUM(completed) / COUNT(*), 1) FROM fact_referrals) AS referral_completion_pct,
    (SELECT ROUND(AVG(1.0 * o6.wellbeing_score - o0.wellbeing_score), 2)
       FROM fact_outcomes o0
       JOIN fact_outcomes o6 ON o6.youth_id = o0.youth_id AND o6.checkpoint_month = 6
      WHERE o0.checkpoint_month = 0)                                   AS wellbeing_gain_6m_paired,
    (SELECT ROUND(100.0 * SUM(o6.substance_free_30d) / COUNT(*), 1)
       FROM fact_outcomes o6
       JOIN dim_youth y ON y.youth_id = o6.youth_id
      WHERE o6.checkpoint_month = 6
        AND y.primary_issue IN ('Substance use', 'Multiple'))          AS substance_free_6m_pct;
