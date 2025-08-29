#!/usr/bin/bash

# ============================================================================
# Script Name : mv_refresh.sh
# Purpose     : Refresh materialized views.
# Author      : Wenhao Fang
# Date        : 2025-07-15
# User        : Execute as a PostgreSQL superuser
# ============================================================================

set -e

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
SCHEMA_NAME="dw_schema"
MV_LIST=("mv_user_year_hour_trip" "mv_user_year_month_trip" "mv_user_year_station" "mv_station_count" "mv_bike_count")

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