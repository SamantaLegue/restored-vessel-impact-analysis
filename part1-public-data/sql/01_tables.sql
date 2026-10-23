-- Part 1: public data tables. Portable SQL (tested for syntax on SQLite).

-- Lookup that every source joins to.
CREATE TABLE dim_region (
    region_key   VARCHAR(20) PRIMARY KEY,   -- e.g. 'NORTHWEST'
    region_name  VARCHAR(20) NOT NULL,      -- e.g. 'Northwest'
    is_nw_sw     INT NOT NULL,              -- 1 = Anglophone crisis region
    capital      VARCHAR(20) NOT NULL
);

INSERT INTO dim_region VALUES
 ('ADAMAWA',   'Adamawa',   0, 'Ngaoundere'),
 ('CENTRE',    'Centre',    0, 'Yaounde'),
 ('EAST',      'East',      0, 'Bertoua'),
 ('FARNORTH',  'Far North', 0, 'Maroua'),
 ('LITTORAL',  'Littoral',  0, 'Douala'),
 ('NORTH',     'North',     0, 'Garoua'),
 ('NORTHWEST', 'Northwest', 1, 'Bamenda'),
 ('SOUTH',     'South',     0, 'Ebolowa'),
 ('SOUTHWEST', 'Southwest', 1, 'Buea'),
 ('WEST',      'West',      0, 'Bafoussam');

-- ACLED export, only the columns we use, loaded as text.
CREATE TABLE raw_acled (
    event_id_cnty   VARCHAR(20),
    event_date      VARCHAR(20),
    year            VARCHAR(4),
    event_type      VARCHAR(60),
    sub_event_type  VARCHAR(60),
    actor1          VARCHAR(200),
    admin1          VARCHAR(40),
    fatalities      VARCHAR(10)
);

-- DHS STATcompiler export reshaped to long format: one row per indicator, survey and region.
CREATE TABLE raw_dhs (
    survey_year     VARCHAR(4),
    region          VARCHAR(40),
    indicator       VARCHAR(200),
    value           VARCHAR(20)
);

-- World Bank WDI, long format.
CREATE TABLE raw_wdi (
    indicator_code  VARCHAR(30),
    indicator_name  VARCHAR(200),
    year            VARCHAR(4),
    value           VARCHAR(20)
);

-- Displacement by region (IOM DTM / OCHA).
CREATE TABLE raw_idp (
    report_date     VARCHAR(20),
    region_of_origin   VARCHAR(40),
    region_of_arrival  VARCHAR(40),
    idps            VARCHAR(20)
);

-- Cleaned tables
CREATE TABLE fact_conflict_year (
    region_key  VARCHAR(20) REFERENCES dim_region (region_key),
    year        INT,
    events      INT,
    fatalities  INT
);

CREATE TABLE fact_dhs (
    region_key  VARCHAR(20) REFERENCES dim_region (region_key),
    survey_year INT,
    indicator   VARCHAR(200),
    value       DECIMAL(6, 1)
);
