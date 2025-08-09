#!/usr/bin/bash

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
SCHEMA_NAME="dw_schema"
VIEW_LIST=("mv_user_time" "mv_user_station" "mv_station_count" "mv_bike_count")
EXPORT_PATH="/export"

echo
echo "##############################"
echo "Exporting MV..."
echo "##############################"
echo

for VIEW in "${VIEW_LIST[@]}";
do
    view_name="$SCHEMA_NAME.$VIEW"
    csv_file="$EXPORT_PATH/$VIEW.csv"

    echo "########## Exporting #csv_file ##########"
    psql -U "$DB_USER" -d "$DB_NAME" \
        -c "COPY (SELECT * FROM $view_name) TO '$csv_file' WITH (FORMAT CSV, HEADER)";
done