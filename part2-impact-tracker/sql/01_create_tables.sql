-- =====================================================================
-- The Restored Vessel impact tracker: table design
-- Written in portable SQL. Tested on SQLite; runs on SQL Server 2017+,
-- PostgreSQL and MySQL 8 with no or minor changes.
-- All data in these tables is SYNTHETIC.
-- =====================================================================

-- Staging table: the intake register exactly as staff typed it.
-- Everything is text so nothing fails on load; 02_clean_youth.sql fixes it.
CREATE TABLE raw_youth_intake (
    youth_id            VARCHAR(10),
    intake_date         VARCHAR(20),
    age                 VARCHAR(10),
    gender              VARCHAR(20),
    home_region         VARCHAR(40),
    primary_issue       VARCHAR(40),
    referral_source     VARCHAR(40),
    education_at_intake VARCHAR(40),
    exit_date           VARCHAR(20),
    exit_reason         VARCHAR(40)
);

-- Calendar table. day_number is a running count of days, so the gap
-- between two dates is a plain subtraction in any SQL dialect.
CREATE TABLE dim_date (
    date         DATE PRIMARY KEY,
    day_number   INT NOT NULL,
    year         INT NOT NULL,
    quarter      INT NOT NULL,
    month        INT NOT NULL,
    month_name   VARCHAR(12) NOT NULL,
    year_month   VARCHAR(7) NOT NULL,
    year_quarter VARCHAR(7) NOT NULL,
    weekday      VARCHAR(10) NOT NULL
);

-- One row per young person (cleaned).
CREATE TABLE dim_youth (
    youth_id            VARCHAR(10) PRIMARY KEY,
    intake_date         DATE NOT NULL,
    age_at_intake       INT,              -- NULL when missing or impossible in the raw data
    age_band            VARCHAR(10),
    gender              VARCHAR(10) NOT NULL,
    home_region         VARCHAR(20) NOT NULL,
    is_displaced_nw_sw  INT NOT NULL,     -- 1 = from Northwest or Southwest (Anglophone crisis regions)
    primary_issue       VARCHAR(30) NOT NULL,
    referral_source     VARCHAR(30) NOT NULL,
    education_at_intake VARCHAR(20) NOT NULL,
    exit_date           DATE,             -- NULL = still in the programme
    exit_reason         VARCHAR(30)
);

-- One row per scheduled session.
CREATE TABLE fact_sessions (
    session_id    VARCHAR(10) PRIMARY KEY,
    youth_id      VARCHAR(10) NOT NULL REFERENCES dim_youth (youth_id),
    session_date  DATE NOT NULL REFERENCES dim_date (date),
    session_type  VARCHAR(30) NOT NULL,
    duration_min  INT NOT NULL,
    attended      INT NOT NULL            -- 1 = attended, 0 = no-show
);

-- One row per referral to an outside service.
CREATE TABLE fact_referrals (
    referral_id   VARCHAR(10) PRIMARY KEY,
    youth_id      VARCHAR(10) NOT NULL REFERENCES dim_youth (youth_id),
    referral_date DATE NOT NULL REFERENCES dim_date (date),
    service_type  VARCHAR(30) NOT NULL,
    completed     INT NOT NULL            -- 1 = young person actually received the service
);

-- One row per assessment: intake (month 0) then 3, 6 and 12 months.
-- A missing row means the follow-up was not reached.
CREATE TABLE fact_outcomes (
    outcome_id            VARCHAR(10) PRIMARY KEY,
    youth_id              VARCHAR(10) NOT NULL REFERENCES dim_youth (youth_id),
    checkpoint_month      INT NOT NULL,
    assessment_date       DATE NOT NULL REFERENCES dim_date (date),
    wellbeing_score       INT NOT NULL,   -- 1 (very low) to 10 (thriving), self-reported
    substance_free_30d    INT NOT NULL,   -- 1 = no drug use in the last 30 days
    in_school_or_work     INT NOT NULL,
    safe_housing          INT NOT NULL,
    reoffended_since_last INT             -- NULL at intake
);
