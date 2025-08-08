#!/usr/bin/bash


set -e

echo "########################################"
echo "Create directory"
echo "########################################"

DB_PATH="/var/lib/postgresql/toronto_shared_bike"

mkdir -pv "${DB_PATH}/fact_tbsp"
mkdir -pv "${DB_PATH}/dim_tbsp"
mkdir -pv "${DB_PATH}/index_tbsp"
mkdir -pv "${DB_PATH}/staging_tbsp"
mkdir -pv "${DB_PATH}/mv_tbsp"

chown -vR postgres:postgres ${DB_PATH}
