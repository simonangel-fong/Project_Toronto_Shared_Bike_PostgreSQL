-- ============================================================================
-- Script Name : 04_create_dw.sql
-- Purpose     : Create data warehouse objects.
-- Author      : Wenhao Fang
-- Date        : 2025-07-15
-- User        : Execute as a PostgreSQL superuser
-- ============================================================================

\echo '\n######## Creating schema... ########\n'

-- Switch to the Toronto Shared Bike database
\c toronto_shared_bike;

-- Display current database and user
SELECT 
current_database() 	as database_name
, current_user 		as username
;

-- Create the time dimension table
CREATE TABLE dw_schema.dim_time (
  dim_time_id           TIMESTAMP   NOT NULL,  -- Unique time identifier (canonical timestamp representation)
  dim_time_year         INTEGER     NOT NULL,  -- Year (e.g., 2024)
  dim_time_quarter      INTEGER     NOT NULL,  -- Quarter
  dim_time_month        INTEGER     NOT NULL,  -- Month
  dim_time_day          INTEGER     NOT NULL,  -- Day
  dim_time_week         INTEGER     NOT NULL,  -- Week
  dim_time_weekday      INTEGER     NOT NULL,  -- Day of week
  dim_time_hour         INTEGER     NOT NULL,  -- Hour
  dim_time_minute       INTEGER     NOT NULL,  -- Minute
  CONSTRAINT pk_dim_time  PRIMARY KEY (dim_time_id),
  CONSTRAINT chk_year     CHECK (dim_time_year BETWEEN 2000 AND 2999),     -- Validate year (2000-2999)
  CONSTRAINT chk_quarter  CHECK (dim_time_quarter BETWEEN 1 AND 4),        -- Validate quarter (1-4)
  CONSTRAINT chk_month    CHECK (dim_time_month BETWEEN 1 AND 12),          -- Validate month (1-12)
  CONSTRAINT chk_day      CHECK (dim_time_day BETWEEN 1 AND 31),            -- Validate day (1-31)
  CONSTRAINT chk_week     CHECK (dim_time_week BETWEEN 1 AND 53),           -- Validate week (1-53)
  CONSTRAINT chk_weekday  CHECK (dim_time_weekday BETWEEN 1 AND 7),         -- Validate day of week
  CONSTRAINT chk_hour     CHECK (dim_time_hour BETWEEN 0 AND 23),           -- Validate hour (0-23)
  CONSTRAINT chk_minute   CHECK (dim_time_minute BETWEEN 0 AND 59)          -- Validate minute (0-59)
) 
TABLESPACE dim_tbsp;

-- Create composite B-tree index on year and month for time-based aggregations
CREATE INDEX index_dim_time_year_month
ON dw_schema.dim_time (dim_time_year, dim_time_month)
TABLESPACE index_tbsp;

-- Create the station dimension table
CREATE TABLE dw_schema.dim_station (
	dim_station_id      INTEGER         NOT NULL,  -- Unique station identifier
  	dim_station_name    VARCHAR(100)    NOT NULL,  -- Station name
	CONSTRAINT pk_dim_station PRIMARY KEY (dim_station_id)
) 
TABLESPACE dim_tbsp;

-- Create index on station name for efficient lookups
CREATE INDEX index_dim_station_station_name
ON dw_schema.dim_station (dim_station_name)
TABLESPACE index_tbsp;

-- Create the bike dimension table
CREATE TABLE dw_schema.dim_bike (
  dim_bike_id       INTEGER       NOT NULL,  -- Unique bike identifier
  dim_bike_model    VARCHAR(50)   NOT NULL,  -- Bike model
  CONSTRAINT pk_dim_bike PRIMARY KEY (dim_bike_id)
) 
TABLESPACE dim_tbsp;

-- Create the user type dimension table
CREATE TABLE dw_schema.dim_user_type (
  dim_user_type_id        SERIAL          PRIMARY KEY,  -- Auto-incremented unique identifier
  dim_user_type_name      VARCHAR(50)     NOT NULL,     -- User type name
  CONSTRAINT uk_dim_user_type_name UNIQUE (dim_user_type_name)
) 
TABLESPACE dim_tbsp;

-- Create the trip fact table with range partitioning
CREATE TABLE dw_schema.fact_trip (
    fact_trip_id                  BIGSERIAL   NOT NULL,      -- Auto-incremented unique identifier
    fact_trip_source_id           INTEGER     NOT NULL,         -- Source trip identifier
    fact_trip_duration            INTEGER     NOT NULL,         -- Trip duration in seconds
    fact_trip_start_time_id       TIMESTAMP   NOT NULL,         -- Reference to start time dimension
    fact_trip_end_time_id         TIMESTAMP   NOT NULL,         -- Reference to end time dimension
    fact_trip_start_station_id    INTEGER     NOT NULL,         -- Reference to start station dimension
    fact_trip_end_station_id      INTEGER     NOT NULL,         -- Reference to end station dimension
    fact_trip_bike_id             INTEGER     NOT NULL,         -- Reference to bike dimension
    fact_trip_user_type_id        INTEGER     NOT NULL,         -- Reference to user type dimension
    CONSTRAINT fk_fact_trip_start_time      FOREIGN KEY (fact_trip_start_time_id)     REFERENCES dw_schema.dim_time (dim_time_id),
    CONSTRAINT fk_fact_trip_end_time        FOREIGN KEY (fact_trip_end_time_id)       REFERENCES dw_schema.dim_time (dim_time_id),
    CONSTRAINT fk_fact_trip_start_station   FOREIGN KEY (fact_trip_start_station_id)  REFERENCES dw_schema.dim_station (dim_station_id),
    CONSTRAINT fk_fact_trip_end_station     FOREIGN KEY (fact_trip_end_station_id)    REFERENCES dw_schema.dim_station (dim_station_id),
    CONSTRAINT fk_fact_trip_bike            FOREIGN KEY (fact_trip_bike_id)           REFERENCES dw_schema.dim_bike (dim_bike_id),
    CONSTRAINT fk_fact_trip_user_type       FOREIGN KEY (fact_trip_user_type_id)      REFERENCES dw_schema.dim_user_type (dim_user_type_id)
) 
PARTITION BY RANGE (fact_trip_start_time_id)
;

-- Create partitions for each year
CREATE TABLE dw_schema.fact_trip_before_2019 
PARTITION OF dw_schema.fact_trip 
FOR VALUES FROM (MINVALUE) TO ('2019-01-01')
TABLESPACE fact_tbsp;

CREATE TABLE dw_schema.fact_trip_2019 
PARTITION OF dw_schema.fact_trip 
FOR VALUES FROM ('2019-01-01') TO ('2020-01-01')
PARTITION BY RANGE (fact_trip_start_time_id);

-- Create monthly subpartitions for 2019
CREATE TABLE dw_schema.fact_trip_2019_jan PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-01-01') TO ('2019-02-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_feb PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-02-01') TO ('2019-03-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_mar PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-03-01') TO ('2019-04-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_apr PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-04-01') TO ('2019-05-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_may PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-05-01') TO ('2019-06-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_jun PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-06-01') TO ('2019-07-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_jul PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-07-01') TO ('2019-08-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_aug PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-08-01') TO ('2019-09-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_sep PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-09-01') TO ('2019-10-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_oct PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-10-01') TO ('2019-11-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_nov PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-11-01') TO ('2019-12-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2019_dec PARTITION OF dw_schema.fact_trip_2019 FOR VALUES FROM ('2019-12-01') TO ('2020-01-01') TABLESPACE fact_tbsp;

CREATE TABLE dw_schema.fact_trip_2020 
PARTITION OF dw_schema.fact_trip 
FOR VALUES FROM ('2020-01-01') TO ('2021-01-01')
PARTITION BY RANGE (fact_trip_start_time_id);

-- Create monthly subpartitions for 2020
CREATE TABLE dw_schema.fact_trip_2020_jan PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-01-01') TO ('2020-02-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_feb PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-02-01') TO ('2020-03-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_mar PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-03-01') TO ('2020-04-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_apr PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-04-01') TO ('2020-05-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_may PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-05-01') TO ('2020-06-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_jun PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-06-01') TO ('2020-07-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_jul PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-07-01') TO ('2020-08-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_aug PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-08-01') TO ('2020-09-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_sep PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-09-01') TO ('2020-10-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_oct PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-10-01') TO ('2020-11-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_nov PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-11-01') TO ('2020-12-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2020_dec PARTITION OF dw_schema.fact_trip_2020 FOR VALUES FROM ('2020-12-01') TO ('2021-01-01') TABLESPACE fact_tbsp;

CREATE TABLE dw_schema.fact_trip_2021 
PARTITION OF dw_schema.fact_trip 
FOR VALUES FROM ('2021-01-01') TO ('2022-01-01')
PARTITION BY RANGE (fact_trip_start_time_id);

-- Create monthly subpartitions for 2021
CREATE TABLE dw_schema.fact_trip_2021_jan PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-01-01') TO ('2021-02-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_feb PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-02-01') TO ('2021-03-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_mar PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-03-01') TO ('2021-04-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_apr PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-04-01') TO ('2021-05-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_may PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-05-01') TO ('2021-06-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_jun PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-06-01') TO ('2021-07-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_jul PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-07-01') TO ('2021-08-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_aug PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-08-01') TO ('2021-09-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_sep PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-09-01') TO ('2021-10-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_oct PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-10-01') TO ('2021-11-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_nov PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-11-01') TO ('2021-12-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2021_dec PARTITION OF dw_schema.fact_trip_2021 FOR VALUES FROM ('2021-12-01') TO ('2022-01-01') TABLESPACE fact_tbsp;

CREATE TABLE dw_schema.fact_trip_2022 
PARTITION OF dw_schema.fact_trip 
FOR VALUES FROM ('2022-01-01') TO ('2023-01-01')
PARTITION BY RANGE (fact_trip_start_time_id);

-- Create monthly subpartitions for 2022
CREATE TABLE dw_schema.fact_trip_2022_jan PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-01-01') TO ('2022-02-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_feb PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-02-01') TO ('2022-03-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_mar PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-03-01') TO ('2022-04-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_apr PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-04-01') TO ('2022-05-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_may PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-05-01') TO ('2022-06-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_jun PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-06-01') TO ('2022-07-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_jul PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-07-01') TO ('2022-08-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_aug PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-08-01') TO ('2022-09-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_sep PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-09-01') TO ('2022-10-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_oct PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-10-01') TO ('2022-11-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_nov PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-11-01') TO ('2022-12-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2022_dec PARTITION OF dw_schema.fact_trip_2022 FOR VALUES FROM ('2022-12-01') TO ('2023-01-01') TABLESPACE fact_tbsp;

CREATE TABLE dw_schema.fact_trip_2023 
PARTITION OF dw_schema.fact_trip 
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01')
PARTITION BY RANGE (fact_trip_start_time_id);

-- Create monthly subpartitions for 2023
CREATE TABLE dw_schema.fact_trip_2023_jan PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-01-01') TO ('2023-02-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_feb PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-02-01') TO ('2023-03-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_mar PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-03-01') TO ('2023-04-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_apr PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-04-01') TO ('2023-05-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_may PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-05-01') TO ('2023-06-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_jun PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-06-01') TO ('2023-07-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_jul PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-07-01') TO ('2023-08-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_aug PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-08-01') TO ('2023-09-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_sep PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-09-01') TO ('2023-10-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_oct PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-10-01') TO ('2023-11-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_nov PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-11-01') TO ('2023-12-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2023_dec PARTITION OF dw_schema.fact_trip_2023 FOR VALUES FROM ('2023-12-01') TO ('2024-01-01') TABLESPACE fact_tbsp;

CREATE TABLE dw_schema.fact_trip_2024 
PARTITION OF dw_schema.fact_trip 
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01')
PARTITION BY RANGE (fact_trip_start_time_id);

-- Create monthly subpartitions for 2024
CREATE TABLE dw_schema.fact_trip_2024_jan PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-01-01') TO ('2024-02-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_feb PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-02-01') TO ('2024-03-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_mar PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-03-01') TO ('2024-04-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_apr PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-04-01') TO ('2024-05-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_may PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-05-01') TO ('2024-06-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_jun PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-06-01') TO ('2024-07-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_jul PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-07-01') TO ('2024-08-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_aug PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-08-01') TO ('2024-09-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_sep PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-09-01') TO ('2024-10-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_oct PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-10-01') TO ('2024-11-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_nov PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-11-01') TO ('2024-12-01') TABLESPACE fact_tbsp;
CREATE TABLE dw_schema.fact_trip_2024_dec PARTITION OF dw_schema.fact_trip_2024 FOR VALUES FROM ('2024-12-01') TO ('2025-01-01') TABLESPACE fact_tbsp;

CREATE TABLE dw_schema.fact_trip_future 
PARTITION OF dw_schema.fact_trip 
FOR VALUES FROM ('2025-01-01') TO (MAXVALUE)
TABLESPACE fact_tbsp;

-- Create indexes on the fact table
-- Create index on start time for efficient time-based queries
CREATE INDEX index_fact_trip_start_time
ON dw_schema.fact_trip (fact_trip_start_time_id)
TABLESPACE index_tbsp;

-- Create composite index on start and end station IDs for route-based queries
CREATE INDEX index_fact_trip_station_pair
ON dw_schema.fact_trip (fact_trip_start_station_id, fact_trip_end_station_id)
TABLESPACE index_tbsp;

-- Create index on user type ID for efficient filtering
CREATE INDEX index_fact_trip_user_type
ON dw_schema.fact_trip (fact_trip_user_type_id)
TABLESPACE index_tbsp;

-- Confirm
SELECT 
    schemaname,
    tablename,
    tablespace
FROM pg_tables 
WHERE schemaname = 'dw_schema'
ORDER BY tablename;

SELECT 
    schemaname,
    indexname,
    indexdef,
    tablespace
FROM pg_indexes 
WHERE schemaname = 'dw_schema'
ORDER BY indexname;

