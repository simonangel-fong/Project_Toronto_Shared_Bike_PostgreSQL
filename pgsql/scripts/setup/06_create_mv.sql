-- ============================================================================
-- Script Name : 06_create_mv.sql
-- Purpose     : Create mv objects.
-- Author      : Wenhao Fang
-- Date        : 2025-07-15
-- User        : Execute as a PostgreSQL superuser
-- ============================================================================

-- ####################################
--  mv_trip_user_year_hour
-- ####################################
-- DROP MATERIALIZED VIEW IF EXISTS dw_schema.mv_trip_user_year_hour;
CREATE MATERIALIZED VIEW dw_schema.mv_trip_user_year_hour
TABLESPACE mv_tbsp
AS
SELECT	
	gen_random_uuid()				AS pk
  	, t.dim_time_year				AS dim_year
	, t.dim_time_hour				AS dim_hour
	, u.dim_user_type_name			AS dim_user
	, COUNT(*)						AS trip_count
	, SUM(f.fact_trip_duration)		AS duration_sum
FROM dw_schema.fact_trip f
JOIN dw_schema.dim_time t 
    ON f.fact_trip_start_time_id = t.dim_time_id
JOIN dw_schema.dim_user_type u
	ON f.fact_trip_user_type_id = u.dim_user_type_id
GROUP BY
	t.dim_time_year
	, t.dim_time_hour
	, u.dim_user_type_name
;

-- Create index
-- DROP INDEX dw_schema.idx_mv_trip_user_year_hour;
CREATE INDEX idx_mv_trip_user_year_hour
ON dw_schema.mv_trip_user_year_hour (dim_user, dim_year, dim_hour);

-- ####################################
--  mv_trip_user_year_month
-- ####################################

-- DROP MATERIALIZED VIEW IF EXISTS dw_schema.mv_trip_user_year_month;
CREATE MATERIALIZED VIEW dw_schema.mv_trip_user_year_month
TABLESPACE mv_tbsp
AS
SELECT	
	gen_random_uuid() 				AS pk	
    , t.dim_time_year     			AS dim_year
	, t.dim_time_month    			AS dim_month
	, u.dim_user_type_name 			AS dim_user
	, COUNT(*)            			AS trip_count
	, SUM(f.fact_trip_duration) 	AS duration_sum
FROM dw_schema.fact_trip f
JOIN dw_schema.dim_time t 
    ON f.fact_trip_start_time_id = t.dim_time_id
JOIN dw_schema.dim_user_type u
	ON f.fact_trip_user_type_id = u.dim_user_type_id
GROUP BY
	t.dim_time_year
	, t.dim_time_month
	, u.dim_user_type_name
;

-- Create index
-- DROP INDEX dw_schema.idx_mv_trip_user_year_month;
CREATE INDEX idx_mv_trip_user_year_month
ON dw_schema.mv_trip_user_year_month (dim_user, dim_year, dim_month);

-- ####################################
--  mv_top_station_user_year
-- ####################################
-- DROP MATERIALIZED VIEW IF EXISTS dw_schema.mv_top_station_user_year;
CREATE MATERIALIZED VIEW dw_schema.mv_top_station_user_year
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
	gen_random_uuid()	AS pk
	, trip_count
 	, dim_station
	, dim_year
	, dim_user
FROM ranked_station_year_user
WHERE trip_rank <= 10;
-- SELECT
-- 	gen_random_uuid()	AS pk
--  	, trip_count
--  	, dim_station
--  	, dim_year
-- 	, 'all'				AS dim_user
-- FROM ranked_station_year_all
-- WHERE trip_rank <= 10

-- UNION ALL


;

-- Indexes for filter speed
-- DROP INDEX dw_schema.idx_mv_top_station_user_year;
CREATE INDEX idx_mv_top_station_user_year
ON dw_schema.mv_top_station_user_year (dim_year, dim_user);

-- ####################################
--  mv_station_year
-- ####################################
-- DROP MATERIALIZED VIEW IF EXISTS dw_schema.mv_station_year;
CREATE MATERIALIZED VIEW dw_schema.mv_station_year
TABLESPACE mv_tbsp
AS
SELECT
	gen_random_uuid()								AS pk
	, COUNT(DISTINCT f.fact_trip_start_station_id) 	AS station_count
	, t.dim_time_year 								AS dim_year
FROM dw_schema.fact_trip f
JOIN dw_schema.dim_time t
  ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY t.dim_time_year
;

-- ####################################
--  mv_bike_year
-- ####################################
-- DROP MATERIALIZED VIEW IF EXISTS dw_schema.mv_bike_year;
CREATE MATERIALIZED VIEW dw_schema.mv_bike_year
TABLESPACE mv_tbsp
AS
SELECT
	gen_random_uuid()					AS pk
	, COUNT(DISTINCT f.fact_trip_bike_id) AS bike_count
	, t.dim_time_year 					AS dim_year
FROM dw_schema.fact_trip f
JOIN dw_schema.dim_time t
  ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY t.dim_time_year
;
