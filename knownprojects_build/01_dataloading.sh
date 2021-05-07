#!/bin/bash
source config.sh
max_bg_procs 5

# Load source data
for f in $(ls data/processed)
do 
    psql $BUILD_ENGINE -f data/processed/$f &
done

# Load ZAP tables
import_private dcp_projects 20210415 &
import_private dcp_projectactions 20210415 &
import_private dcp_projectbbls 20210415 &

# Load other tables
import_public dcp_mappluto_wi &
import_public dcp_boroboundaries_wi &
import_public dcp_housing &
import_public dcp_zoningmapamendments &
wait

# Load corrections tables
psql $BUILD_ENGINE -f sql/create_corrections.sql

echo
echo "data loading complate"
echo
