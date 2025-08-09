-- ============================================================================
-- Script Name : 03_load_pg.sql
-- Purpose     : Transform and Load staging data into the Data Warehouse in PostgreSQL
-- Author      : Wenhao Fang (converted for PostgreSQL)
-- Date        : 2025-05-07
-- Notes       : Run with a user that has INSERT/UPDATE privileges on dw_schema
-- ============================================================================

-- ============================================================================
-- Load dim_time
-- ============================================================================
\echo '\n######## Loading dim_time... ########\n'
MERGE INTO dw_schema.dim_time AS tgt
USING (
    SELECT DISTINCT
        TO_TIMESTAMP(time_value, 'MM/DD/YYYY HH24:MI') AS dim_time_id
    FROM (
        SELECT start_time AS time_value FROM dw_schema.staging_trip
        UNION
        SELECT end_time FROM dw_schema.staging_trip WHERE end_time IS NOT NULL
    ) AS combined
) AS src
ON tgt.dim_time_id = src.dim_time_id
WHEN NOT MATCHED THEN
INSERT (
    dim_time_id,
    dim_time_year,
    dim_time_quarter,
    dim_time_month,
    dim_time_day,
    dim_time_week,
    dim_time_weekday,
    dim_time_hour,
    dim_time_minute
)
VALUES (
    src.dim_time_id,
    EXTRACT(YEAR FROM src.dim_time_id)::INT,
    EXTRACT(QUARTER FROM src.dim_time_id)::INT,
    EXTRACT(MONTH FROM src.dim_time_id)::INT,
    EXTRACT(DAY FROM src.dim_time_id)::INT,
    EXTRACT(WEEK FROM src.dim_time_id)::INT,
    EXTRACT(DOW FROM src.dim_time_id)::INT + 1,
    EXTRACT(HOUR FROM src.dim_time_id)::INT,
    EXTRACT(MINUTE FROM src.dim_time_id)::INT
);

-- ============================================================================
-- Load dim_station
-- ============================================================================
\echo '\n######## Loading dim_station... ########\n'
WITH station_times AS (
    SELECT 
        start_station_id::INT AS station_id,
        start_station_name AS station_name,
        TO_TIMESTAMP(start_time, 'MM/DD/YYYY HH24:MI') AS trip_datetime
    FROM dw_schema.staging_trip
    WHERE start_station_id IS NOT NULL AND start_station_name IS NOT NULL

    UNION ALL

    SELECT 
        end_station_id::INT AS station_id,
        end_station_name AS station_name,
        TO_TIMESTAMP(end_time, 'MM/DD/YYYY HH24:MI') AS trip_datetime
    FROM dw_schema.staging_trip
    WHERE end_station_id IS NOT NULL AND end_station_name IS NOT NULL
),
latest_stations AS (
    SELECT DISTINCT ON (station_id)
        station_id,
        station_name
    FROM station_times
    ORDER BY station_id, trip_datetime DESC
)
MERGE INTO dw_schema.dim_station AS tgt
USING latest_stations AS src
ON tgt.dim_station_id = src.station_id
WHEN MATCHED THEN
  UPDATE SET dim_station_name = src.station_name
WHEN NOT MATCHED THEN
  INSERT (dim_station_id, dim_station_name)
  VALUES (src.station_id, src.station_name);

-- ============================================================================
-- Load dim_bike
-- ============================================================================
\echo '\n######## Loading dim_bike... ########\n'
MERGE INTO dw_schema.dim_bike AS tgt
USING (
    SELECT 
        bike_id::INT AS dim_bike_id,
        COALESCE(
            MAX(NULLIF(TRIM(REPLACE(model, CHR(13), '')), 'UNKNOWN')),
            'UNKNOWN'
        ) AS dim_bike_model
    FROM dw_schema.staging_trip
    GROUP BY bike_id::INT
) AS src
ON tgt.dim_bike_id = src.dim_bike_id
WHEN MATCHED AND tgt.dim_bike_model IS DISTINCT FROM src.dim_bike_model THEN
  UPDATE SET dim_bike_model = src.dim_bike_model
WHEN NOT MATCHED THEN
  INSERT (dim_bike_id, dim_bike_model)
  VALUES (src.dim_bike_id, src.dim_bike_model);

-- ============================================================================
-- Load dim_user_type
-- ============================================================================
\echo '\n######## Loading dim_user_type... ########\n'
MERGE INTO dw_schema.dim_user_type AS tgt
USING (
    SELECT DISTINCT user_type AS dim_user_type_name
    FROM dw_schema.staging_trip
    WHERE user_type IS NOT NULL
) AS src
ON tgt.dim_user_type_name = src.dim_user_type_name
WHEN NOT MATCHED THEN
  INSERT (dim_user_type_name)
  VALUES (src.dim_user_type_name);

-- ============================================================================
-- Load fact_trip
-- ============================================================================
\echo '\n######## Loading fact_trip... ########\n'
MERGE INTO dw_schema.fact_trip AS tgt
USING (
    SELECT 
        trip_id::INT AS fact_trip_source_id,
        trip_duration::NUMERIC AS fact_trip_duration,
        TO_TIMESTAMP(start_time, 'MM/DD/YYYY HH24:MI') AS fact_trip_start_time_id,
        TO_TIMESTAMP(end_time, 'MM/DD/YYYY HH24:MI') AS fact_trip_end_time_id,
        start_station_id::INT AS fact_trip_start_station_id,
        end_station_id::INT AS fact_trip_end_station_id,
        bike_id::INT AS fact_trip_bike_id,
        dut.dim_user_type_id AS fact_trip_user_type_id
    FROM dw_schema.staging_trip st
    JOIN dw_schema.dim_user_type dut
      ON dut.dim_user_type_name = st.user_type
) AS src
ON tgt.fact_trip_source_id = src.fact_trip_source_id
WHEN MATCHED AND (
    tgt.fact_trip_duration IS DISTINCT FROM src.fact_trip_duration OR
    tgt.fact_trip_start_time_id IS DISTINCT FROM src.fact_trip_start_time_id OR
    tgt.fact_trip_end_time_id IS DISTINCT FROM src.fact_trip_end_time_id OR
    tgt.fact_trip_start_station_id IS DISTINCT FROM src.fact_trip_start_station_id OR
    tgt.fact_trip_end_station_id IS DISTINCT FROM src.fact_trip_end_station_id OR
    tgt.fact_trip_bike_id IS DISTINCT FROM src.fact_trip_bike_id OR
    tgt.fact_trip_user_type_id IS DISTINCT FROM src.fact_trip_user_type_id
) THEN
  UPDATE SET
    fact_trip_duration = src.fact_trip_duration,
    fact_trip_start_time_id = src.fact_trip_start_time_id,
    fact_trip_end_time_id = src.fact_trip_end_time_id,
    fact_trip_start_station_id = src.fact_trip_start_station_id,
    fact_trip_end_station_id = src.fact_trip_end_station_id,
    fact_trip_bike_id = src.fact_trip_bike_id,
    fact_trip_user_type_id = src.fact_trip_user_type_id
WHEN NOT MATCHED THEN
  INSERT (
    fact_trip_source_id,
    fact_trip_duration,
    fact_trip_start_time_id,
    fact_trip_end_time_id,
    fact_trip_start_station_id,
    fact_trip_end_station_id,
    fact_trip_bike_id,
    fact_trip_user_type_id
  )
  VALUES (
    src.fact_trip_source_id,
    src.fact_trip_duration,
    src.fact_trip_start_time_id,
    src.fact_trip_end_time_id,
    src.fact_trip_start_station_id,
    src.fact_trip_end_station_id,
    src.fact_trip_bike_id,
    src.fact_trip_user_type_id
  );

-- Confirm
\echo '\n######## Confirm loading task... ########\n'
SELECT COUNT(*) AS dim_time_count
FROM dw_schema.dim_time;

SELECT COUNT(*) AS dim_station_count
FROM dw_schema.dim_station;

SELECT COUNT(*) AS dim_bike_count
FROM dw_schema.dim_bike;

SELECT COUNT(*) AS dim_user_type_count
FROM dw_schema.dim_user_type;

SELECT COUNT(*) AS fact_trip_count
FROM dw_schema.fact_trip;