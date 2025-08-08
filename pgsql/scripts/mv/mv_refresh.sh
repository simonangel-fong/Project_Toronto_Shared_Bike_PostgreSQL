#!/usr/bin/bash

DB_USER="postgres"
DB_NAME="toronto_shared_bike"

psql -U "$DB_USER" -d "$DB_NAME" \
    -c "REFRESH MATERIALIZED VIEW dw_schema.mv_user_time";

psql -U "$DB_USER" -d "$DB_NAME" \
    -c "REFRESH MATERIALIZED VIEW dw_schema.mv_user_station";

psql -U "$DB_USER" -d "$DB_NAME" \
    -c "REFRESH MATERIALIZED VIEW dw_schema.mv_station_count";

psql -U "$DB_USER" -d "$DB_NAME" \
    -c "REFRESH MATERIALIZED VIEW dw_schema.mv_bike_count";
