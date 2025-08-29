#!/usr/bin/bash

# ============================================================================
# Script Name : pipeline.sh
# Purpose     : Execute pipeline jobs.
# Author      : Wenhao Fang
# Date        : 2025-07-15
# User        : Execute as a PostgreSQL superuser
# ============================================================================

set -e

SCRIPT_LIST=("/scripts/etl/extract.sh" "/scripts/etl/transform.sh" "/scripts/etl/load.sh" "/scripts/mv/mv_refresh.sh" "/scripts/export/export.sh")

echo
echo "##############################"
echo "Executing pipeline jobs ..."
echo "##############################"
echo

for SCRIPT in "${SCRIPT_LIST[@]}"; 
do
    bash $SCRIPT
done

echo "Pipeline jobs completed."