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
MV_LIST=("mv_trip_user_year_hour" "mv_trip_user_year_month" "mv_top_station_user_year" "mv_station_year" "mv_bike_year")
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