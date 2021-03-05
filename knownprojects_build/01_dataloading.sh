#!/bin/bash
source config.sh

# Load source data
for f in $(ls data/processed)
do 
    psql $BUILD_ENGINE -f data/processed/$f &
done
wait

# Load ZAP tables
import_private dcp_projects &
import_private dcp_projectactions &
import_private dcp_projectbbls

# Load other tables
import_public dcp_mappluto_wi
import_public dcp_boroboundaries_wi
import_public dcp_housing
import_public dcp_zoningmapamendments


