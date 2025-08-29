#!/usr/bin/bash

# ============================================================================
# Script Name : export.sh
# Purpose     : Export data into csv files.
# Author      : Wenhao Fang
# Date        : 2025-07-15
# User        : Execute as a PostgreSQL superuser
# ============================================================================

set -e

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
SCHEMA_NAME="dw_schema"
MV_LIST=("mv_user_year_hour_trip" "mv_user_year_month_trip" "mv_user_year_station" "mv_station_count" "mv_bike_count")
EXPORT_PATH="/export"

echo
echo "##############################"
echo "Exporting MV..."
echo "##############################"
echo

for VIEW in "${MV_LIST[@]}";
do
    view_name="$SCHEMA_NAME.$VIEW"
    csv_file="$EXPORT_PATH/$VIEW.csv"

    echo "########## Exporting #csv_file ##########"
    psql -U "$DB_USER" -d "$DB_NAME" \
        -c "COPY (SELECT * FROM $view_name) TO '$csv_file' WITH (FORMAT CSV, HEADER)";
done