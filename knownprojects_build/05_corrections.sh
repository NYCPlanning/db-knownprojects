#!/bin/bash
source config.sh
# Add in records where field=add, then fill in missing attributes
psql $BUILD_ENGINE -f sql/add_new_records.sql
psql $BUILD_ENGINE -f sql/phasing.sql
psql $BUILD_ENGINE -f sql/normalize_status.sql
psql $BUILD_ENGINE -f sql/assign_boolean.sql
psql $BUILD_ENGINE -f sql/assign_boro.sql

# Add planner-added projects
psql $BUILD_ENGINE -f sql/append_planner_added.sql

# Apply corrections
psql $BUILD_ENGINE -f sql/apply_corrections.sql

# Recalculate units_net & phasing counts
docker run --rm\
    -v $(pwd):/home/knownprojects_build\
    -w /home/knownprojects_build\
    -e EDM_DATA=$EDM_DATA\
    -e RECIPE_ENGINE=$RECIPE_ENGINE\
    -e BUILD_ENGINE=$BUILD_ENGINE\
    -e CARTO_USERNAME=$CARTO_USERNAME\
    -e CARTO_APIKEY=$CARTO_APIKEY\
    python:3.7-slim sh -c "
        pip3 install -r python/requirements.txt; 
        python3 python/resolve_clusters.py kpdb kpdb"

psql $BUILD_ENGINE -f sql/phasing_counts.sql
