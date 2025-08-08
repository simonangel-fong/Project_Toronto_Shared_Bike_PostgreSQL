#!/usr/bin/bash

# set -e

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
DATA_PATH="/data"
YEAR_START=2019
YEAR_END=2022

# Truncate table
psql -U "$DB_USER" -d "$DB_NAME" \
        -c "TRUNCATE TABLE dw_schema.staging_trip"

# Check if truncate was successful
if [[ $? -ne 0 ]]; then
    echo "Failed to truncate table. Exiting."
    exit 1
fi

# loop all years
for per_year in {$YEAR_START..$YEAR_END}; do
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
            echo "Successfully loaded: $csv_file"
        else
            echo "Failed to load: $csv_file"
        fi
    done
done

echo
echo -e "########## Extract Job finished. ##########"