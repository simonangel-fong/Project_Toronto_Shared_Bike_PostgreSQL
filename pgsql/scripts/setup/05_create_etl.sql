-- ============================================================================
-- Script Name : 05_create_etl.sql
-- Purpose     : Create etl pipeline objects.
-- Author      : Wenhao Fang
-- Date        : 2025-07-15
-- User        : Execute as a PostgreSQL superuser
-- ============================================================================

-- Create staging table
-- DROP TABLE IF EXISTS dw_schema.staging_trip;
CREATE TABLE dw_schema.staging_trip (
    trip_id               VARCHAR(100),
    trip_duration         VARCHAR(15),
    start_time            VARCHAR(50),
    start_station_id      VARCHAR(15),
    start_station_name    VARCHAR(100),
    end_time              VARCHAR(50),
    end_station_id        VARCHAR(15),
    end_station_name      VARCHAR(100),
    bike_id               VARCHAR(15),
    user_type             VARCHAR(50),
    model                 VARCHAR(50)
)
TABLESPACE staging_tbsp;

-- confirm
SELECT 
	tablename
	, schemaname
	, tablespace
FROM pg_tables 
WHERE schemaname = 'dw_schema' 
AND tablename IN ('staging_trip');
