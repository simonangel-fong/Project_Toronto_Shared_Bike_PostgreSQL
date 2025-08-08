#!/usr/bin/bash

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
SQL_FILE="03_load.sql"

psql -U "$DB_USER" -d "$DB_NAME" -f $SQL_FILE