-- ============================================================================
-- Script Name : 03_create_schema.sql
-- Purpose     : Create schema to contain objects.
-- Author      : Wenhao Fang
-- Date        : 2025-07-15
-- User        : Execute as a PostgreSQL superuser
-- ============================================================================

\echo '\n######## Creating schema... ########\n'

-- Connect to the Toronto Shared Bike database
\c toronto_shared_bike;

-- Display current database and user
SELECT 
current_database() 	as database_name
, current_user 		as username
;

-- Create role
CREATE ROLE dw_role
    LOGIN
    PASSWORD 'SecurePassword!23'
    CREATEDB                    -- Allow creating databases
    CREATEROLE                  -- Allow creating roles
    INHERIT                     -- Inherit privileges from granted roles
    VALID UNTIL 'infinity'      -- No expiration date
;     

-- Grant privileges to dw_role role
GRANT CONNECT ON DATABASE toronto_shared_bike TO dw_role;
GRANT CREATE ON DATABASE toronto_shared_bike TO dw_role;

-- Grant usage on all tablespaces
GRANT CREATE ON TABLESPACE fact_tbsp TO dw_role;
GRANT CREATE ON TABLESPACE dim_tbsp TO dw_role;
GRANT CREATE ON TABLESPACE index_tbsp TO dw_role;
GRANT CREATE ON TABLESPACE staging_tbsp TO dw_role;
GRANT CREATE ON TABLESPACE mv_tbsp TO dw_role;

-- Create data warehouse schema
CREATE SCHEMA dw_schema AUTHORIZATION dw_role;

-- grant usage on schema
GRANT USAGE ON SCHEMA dw_schema TO dw_role;
GRANT CREATE ON SCHEMA dw_schema TO dw_role;

-- Confirm
SELECT 
    r.rolname 			as rolename,
    r.rolcreatedb 		as can_create_db,
    r.rolcreaterole 	as can_create_role,
    r.rolcanlogin 		as can_login,
    r.rolvaliduntil 	as valid_until,
    s.schema_name,
    s.schema_owner
FROM pg_roles r
LEFT JOIN information_schema.schemata s 
ON r.rolname = s.schema_owner
WHERE rolname = 'dw_role'
;

-- confirm tablespace privileges
SELECT 
    t.spcname 		as tablespace_name,
    r.rolname 		as grantee,
    'CREATE' 		as privilege_type
FROM pg_tablespace t
CROSS JOIN pg_roles r
WHERE r.rolname = 'dw_role'
    AND has_tablespace_privilege(r.oid, t.oid, 'CREATE')
ORDER BY t.spcname;
