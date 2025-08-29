#!/usr/bin/bash

# ============================================================================
# Script Name : transorm.sh
# Purpose     : Transform staging data.
# Author      : Wenhao Fang
# Date        : 2025-07-15
# User        : Execute as a PostgreSQL superuser
# ============================================================================

set -e

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
SQL_FILE="/scripts/etl/transform.sql"

psql -U "$DB_USER" -d "$DB_NAME" -f $SQL_FILE