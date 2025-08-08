-- Enable verbose error reporting
\set ON_ERROR_STOP on

-- Connect to the toronto_shared_bike database
\c toronto_shared_bike;

-- Show current database and user
SELECT 
	current_database() 	AS database_name
	, current_user 		AS username
;

-- ============================================================================
-- Data processing: Remove rows with NULLs in Key columns
-- ============================================================================
\echo '\n######## Remove rows with NULLs in key columns... ########\n'
-- Remove rows with NULL values in key columns
DELETE FROM dw_schema.staging_trip
WHERE trip_id IS NULL
   OR trip_duration IS NULL
   OR start_time IS NULL
   OR start_station_id IS NULL
   OR end_station_id IS NULL;

\echo '\n######## Remove rows with "NULLs" in Key columns... ########\n'
-- Remove rows where key columns contain the string "NULL"
DELETE FROM dw_schema.staging_trip
WHERE trip_id = 'NULL'
   OR trip_duration = 'NULL'
   OR start_time = 'NULL'
   OR start_station_id = 'NULL'
   OR end_station_id = 'NULL';

-- ============================================================================
-- Key columns processing: Remove rows with invalid data types or formats
-- ============================================================================
\echo '\n######## Remove rows with invalid data types or formats... ########\n'
DELETE FROM dw_schema.staging_trip
WHERE NOT trip_id ~ '^[0-9]+$'
   OR NOT trip_duration ~ '^[0-9]+(\.[0-9]+)?$'
   OR NOT start_time ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$'
   OR TO_TIMESTAMP(start_time, 'MM/DD/YYYY HH24:MI') IS NULL
   OR NOT start_station_id ~ '^[0-9]+$'
   OR NOT end_station_id ~ '^[0-9]+$';

-- ============================================================================
-- Key column processing (trip durations): Remove rows with non-positive value
-- ============================================================================
\echo '\n######## Delete rows with non-positive duration... ########\n'
-- Delete rows with non-positive duration
DELETE FROM dw_schema.staging_trip
WHERE trip_duration::numeric <= 0;

-- ============================================================================
-- Non-critical columns processing
-- ============================================================================

\echo '\n######## Fix invalid or NULL end_time values... ########\n'
-- Fix invalid or NULL end_time values
UPDATE dw_schema.staging_trip
SET end_time = TO_CHAR(
    TO_TIMESTAMP(start_time, 'MM/DD/YYYY HH24:MI') + (trip_duration::numeric / 86400) * INTERVAL '1 day',
    'MM/DD/YYYY HH24:MI'
)
WHERE end_time IS NULL
   OR NOT end_time ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$'
   OR TO_TIMESTAMP(end_time, 'MM/DD/YYYY HH24:MI') IS NULL;

\echo '\n######## Substitute missing station names with "UNKNOWN"... ########\n'
-- Substitute missing station names with 'UNKNOWN'
UPDATE dw_schema.staging_trip
SET start_station_name = 'UNKNOWN'
WHERE start_station_name IS NULL OR TRIM(start_station_name) = 'NULL';

UPDATE dw_schema.staging_trip
SET end_station_name = 'UNKNOWN'
WHERE end_station_name IS NULL OR TRIM(end_station_name) = 'NULL';


\echo '\n######## Substitute missing user_type with "UNKNOWN"... ########\n'
-- Substitute missing user_type with 'UNKNOWN'
UPDATE dw_schema.staging_trip
SET user_type = 'UNKNOWN'
WHERE user_type IS NULL;

\echo '\n######## Substitute invalid or missing bike_id with "-1"... ########\n'
-- Substitute invalid or missing bike_id with '-1'
UPDATE dw_schema.staging_trip
SET bike_id = '-1'
WHERE bike_id IS NULL
   OR (bike_id !~ '^[0-9]+$' AND bike_id != '-1');

\echo '\n######## Substitute missing model with "UNKNOWN"... ########\n'

-- Substitute missing model with 'UNKNOWN'
UPDATE dw_schema.staging_trip
SET model = 'UNKNOWN'
WHERE model IS NULL;

\echo '\n######## Remove carriage return characters from user_type... ########\n'
-- Remove carriage return characters from user_type
UPDATE dw_schema.staging_trip
SET user_type = REPLACE(user_type, CHR(13), '')
WHERE POSITION(CHR(13) IN user_type) > 0;

-- ============================================================================
-- Final Confirmation
-- ============================================================================
SELECT *
FROM dw_schema.staging_trip
LIMIT 2;