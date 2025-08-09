#!/usr/bin/bash

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
SCHEMA_NAME="dw_schema"
MV_LIST=("mv_user_time" "mv_user_station" "mv_station_count" "mv_bike_count")

echo
echo "##############################"
echo "Refresh Materialized View ..."
echo "##############################"
echo

for VIEW in "${MV_LIST[@]}"; do
    
    echo -e "\n########## Refreshing $SCHEMA_NAME.$VIEW ##########"
    psql -U "$DB_USER" -d "$DB_NAME" \
        -c "REFRESH MATERIALIZED VIEW $SCHEMA_NAME.$VIEW";
done