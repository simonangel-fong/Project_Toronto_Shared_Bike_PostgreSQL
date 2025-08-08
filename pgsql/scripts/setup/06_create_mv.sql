
-- ####################################
--  mv_user_time
-- ####################################

DROP MATERIALIZED VIEW IF EXISTS dw_schema.mv_user_time;

CREATE MATERIALIZED VIEW dw_schema.mv_user_time
TABLESPACE mv_tbsp
AS
SELECT	
    t.dim_time_year     AS dim_year,
	t.dim_time_month    AS dim_month,
	t.dim_time_hour     AS dim_hour,
	u.dim_user_type_name AS dim_user,
    COUNT(*)            AS trip_count,
	SUM(f.fact_trip_duration) AS duration_sum,
	ROUND(AVG(f.fact_trip_duration)::NUMERIC, 2) AS duration_avg
FROM dw_schema.fact_trip f
JOIN dw_schema.dim_time t 
    ON f.fact_trip_start_time_id = t.dim_time_id
JOIN dw_schema.dim_user_type u
	ON f.fact_trip_user_type_id = u.dim_user_type_id
GROUP BY
	t.dim_time_year,
	t.dim_time_month,
	t.dim_time_hour,
	u.dim_user_type_name;

-- Create index to simulate partition-like filtering
CREATE INDEX idx_mv_time 
ON dw_schema.mv_user_time (dim_year, dim_month, dim_hour);


-- ####################################
--  mv_user_station
-- ####################################
DROP MATERIALIZED VIEW IF EXISTS dw_schema.mv_user_station;

CREATE MATERIALIZED VIEW dw_schema.mv_user_station
TABLESPACE mv_tbsp
AS
WITH ranked_station_year_all AS (
  SELECT
    trip_count,
    dim_station,
    dim_year,
    RANK() OVER(PARTITION BY dim_year ORDER BY trip_count DESC) AS trip_rank
  FROM (
    SELECT 
      COUNT(*) AS trip_count,
      s.dim_station_name AS dim_station,
      t.dim_time_year AS dim_year
    FROM dw_schema.fact_trip f
    JOIN dw_schema.dim_time t 
      ON f.fact_trip_start_time_id = t.dim_time_id
    JOIN dw_schema.dim_station s 
      ON f.fact_trip_start_station_id = s.dim_station_id
    JOIN dw_schema.dim_user_type u 
      ON f.fact_trip_user_type_id = u.dim_user_type_id
    WHERE s.dim_station_name <> 'UNKNOWN'
    GROUP BY s.dim_station_name, t.dim_time_year
  ) station_all_year
),
ranked_station_year_user AS (
  SELECT 
    trip_count,
    dim_year,
    dim_user,
    dim_station,
    RANK() OVER(PARTITION BY dim_year, dim_user ORDER BY trip_count DESC) AS trip_rank
  FROM (
    SELECT
      COUNT(*) AS trip_count,
      t.dim_time_year AS dim_year,
      u.dim_user_type_name AS dim_user,
      s.dim_station_name AS dim_station
    FROM dw_schema.fact_trip f
    JOIN dw_schema.dim_time t
      ON f.fact_trip_start_time_id = t.dim_time_id
    JOIN dw_schema.dim_station s
      ON f.fact_trip_start_station_id = s.dim_station_id
    JOIN dw_schema.dim_user_type u
      ON f.fact_trip_user_type_id = u.dim_user_type_id
    WHERE s.dim_station_name <> 'UNKNOWN'
    GROUP BY t.dim_time_year, u.dim_user_type_name, s.dim_station_name
  ) station_user_year
)
SELECT
  trip_count,
  dim_station,
  dim_year,
  'all' AS dim_user
FROM ranked_station_year_all
WHERE trip_rank <= 10

UNION ALL

SELECT 
  trip_count,
  dim_station,
  dim_year,
  dim_user
FROM ranked_station_year_user
WHERE trip_rank <= 10;

-- Indexes for filter speed
CREATE INDEX idx_mv_user_station_year 
ON dw_schema.mv_user_station (dim_year);

CREATE INDEX idx_mv_user_station_station 
ON dw_schema.mv_user_station (dim_station);


-- ####################################
--  mv_station_count
-- ####################################
DROP MATERIALIZED VIEW IF EXISTS dw_schema.mv_station_count;

CREATE MATERIALIZED VIEW dw_schema.mv_station_count
TABLESPACE mv_tbsp
AS
SELECT
	COUNT(DISTINCT f.fact_trip_start_station_id) AS station_count,
	t.dim_time_year AS dim_year
FROM dw_schema.fact_trip f
JOIN dw_schema.dim_time t
  ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY t.dim_time_year;

-- ####################################
--  mv_bike_count
-- ####################################
DROP MATERIALIZED VIEW IF EXISTS dw_schema.mv_bike_count;

CREATE MATERIALIZED VIEW dw_schema.mv_bike_count
TABLESPACE mv_tbsp
AS
SELECT
	COUNT(DISTINCT f.fact_trip_bike_id) AS bike_count,
	t.dim_time_year AS dim_year
FROM dw_schema.fact_trip f
JOIN dw_schema.dim_time t
  ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY t.dim_time_year;
