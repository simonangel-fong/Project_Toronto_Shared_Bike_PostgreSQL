-- ============================================================================
-- Script Name : create_tablespaces.sql
-- Purpose     : Create tablespaces for fact, dimension, index, staging, and materialized view storage
--               in the Toronto Shared Bike Data Warehouse (PostgreSQL version)
-- Author      : Wenhao Fang (Converted from Oracle)
-- Date        : 2025-07-09
-- User        : Execute as a PostgreSQL superuser or user with CREATE TABLESPACE privileges
-- Notes       : Ensure the database is created and directories exist before running this script
-- ============================================================================

\echo '\n######## Creating tablespaces... ########\n'

-- Connect to the project db
\c toronto_shared_bike;

-- Display current database and user
SELECT 
	current_database() 	as database_name
	, current_user 		as username
;

-- Create FACT_TBSP tablespace for fact table
CREATE TABLESPACE fact_tbsp
LOCATION '/var/lib/postgresql/toronto_shared_bike/fact_tbsp';

-- Create DIM_TBSP tablespace for dimension tables
CREATE TABLESPACE dim_tbsp
LOCATION '/var/lib/postgresql/toronto_shared_bike/dim_tbsp';

-- Create INDEX_TBSP tablespace for indexes
CREATE TABLESPACE index_tbsp
LOCATION '/var/lib/postgresql/toronto_shared_bike/index_tbsp';

-- Create STAGING_TBSP tablespace for staging tables
CREATE TABLESPACE staging_tbsp
LOCATION '/var/lib/postgresql/toronto_shared_bike/staging_tbsp';

-- Create MV_TBSP tablespace for materialized views
CREATE TABLESPACE mv_tbsp
LOCATION '/var/lib/postgresql/toronto_shared_bike/mv_tbsp';

-- Confirm
SELECT 
	spcname 									AS "Name"
	, pg_catalog.pg_get_userbyid(spcowner) 		AS "Owner"
	, pg_catalog.pg_tablespace_location(oid) 	AS "Location"
FROM pg_catalog.pg_tablespace
WHERE spcname LIKE '%_tbsp'
ORDER BY 1;