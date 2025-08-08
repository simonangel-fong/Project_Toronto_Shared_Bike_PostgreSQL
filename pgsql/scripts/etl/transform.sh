#!/usr/bin/bash

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
SQL_FILE="/var/lib/postgresql/scripts/etl/transform.sql"

psql -U "$DB_USER" -d "$DB_NAME" -f $SQL_FILE