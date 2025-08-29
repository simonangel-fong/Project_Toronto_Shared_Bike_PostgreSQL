#!/usr/bin/bash

# ============================================================================
# Script Name : extract.sh
# Purpose     : Extract data from csv files.
# Author      : Wenhao Fang
# Date        : 2025-07-15
# User        : Execute as a PostgreSQL superuser
# ============================================================================

set -e

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
DATA_PATH="/data"

echo
echo "##############################"
echo "Truncate table ..."
echo "##############################"
echo

psql -U "$DB_USER" -d "$DB_NAME" \
    -c "TRUNCATE TABLE dw_schema.staging_trip"

# Check if truncate was successful
if [[ $? -ne 0 ]]; then
    echo "Failed to truncate table. Exiting."
    exit 1
fi

echo
echo "##############################"
echo "ETL - Extract Task ..."
echo "##############################"
echo

# loop all years
for per_year in {2019..2022}; do
    
    # generate path
    per_year_path="$DATA_PATH/$per_year"

    # Check if directory exists first
    if [[ ! -d "$per_year_path" ]]; then
        echo "Directory not found: $per_year_path"
        continue
    fi

    # loop all csv file in path
    for csv_file in "$per_year_path"/*.csv; do
        # Check if file exists
        if [[ ! -f "$csv_file" ]]; then
            echo "No CSV files found in $per_year_path"
            continue
        fi
        
        echo -e "Processing: $csv_file"
        
        psql -U "$DB_USER" -d "$DB_NAME" \
            -c "\\COPY dw_schema.staging_trip (
                trip_id,
                trip_duration,
                start_station_id,
                start_time,
                start_station_name,
                end_station_id,
                end_time,
                end_station_name,
                bike_id,
                user_type
            ) FROM '$csv_file' DELIMITER ',' CSV HEADER;"
        
        # Check if the psql command was successful
        if [[ $? -eq 0 ]]; then
            echo -e "Successfully loaded: $csv_file \n"
        else
            echo -e "Failed to load: $csv_file \n"
        fi
    done
done

echo
echo "########## Extract Job finished. ##########"