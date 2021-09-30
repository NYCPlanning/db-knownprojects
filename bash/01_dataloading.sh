#!/bin/bash
source bash/config.sh
max_bg_procs 5

# Load source data
for f in $(ls data/processed)
do 
    psql $BUILD_ENGINE -f data/processed/$f &
done

# Load ZAP tables
import_private dcp_projects &
import_private dcp_projectactions &
import_private dcp_projectbbls &
import_private dcp_dcpprojectteams &

# Load other tables
import_public dcp_mappluto_wi &
import_public dcp_boroboundaries_wi &
import_public dcp_housing &  
import_public dcp_zoningmapamendments &
# load school districts tables
import_public nyc_school_districts &
import_public doe_schoolsubdistricts &
import_public doe_school_zones_es_2019 &
wait

# Load corrections tables
psql $BUILD_ENGINE -f sql/create_corrections.sql



echo
echo "data loading complate"
echo



