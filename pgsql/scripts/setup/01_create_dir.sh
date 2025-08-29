#!/usr/bin/bash

# ============================================================================
# Script Name : 01_create_dir.sh
# Purpose     : Create directories for tablespaces
# Author      : Wenhao Fang
# Date        : 2025-07-15
# User        : Execute as a PostgreSQL superuser
# ============================================================================

set -e

DB_PATH="/var/lib/postgresql/toronto_shared_bike"
TBSP_PATH=("${DB_PATH}/fact_tbsp" "${DB_PATH}/dim_tbsp" "${DB_PATH}/index_tbsp" "${DB_PATH}/staging_tbsp" "${DB_PATH}/mv_tbsp")

echo
echo "########################################"
echo "Create directory"
echo "########################################"

for DIR_PATH in "${TBSP_PATH[@]}";
do
    mkdir -pv $DIR_PATH
done

chown -vR postgres:postgres ${DB_PATH}
