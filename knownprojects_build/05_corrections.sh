#!/bin/bash
source config.sh
# Add in records where field=add, then fill in missing attributes
echo "Adding previously-filtered records"
psql $BUILD_ENGINE -f sql/add_new_records.sql
echo "Calculating phasing for new records"
psql $BUILD_ENGINE -f sql/phasing.sql
echo "Normalizing status for new records"
psql $BUILD_ENGINE -f sql/normalize_status.sql
echo "Assigning boolean fields"
psql $BUILD_ENGINE -f sql/assign_boolean.sql

# Add planner-added projects
echo "Adding planner-added projects"
psql $BUILD_ENGINE -f sql/append_planner_added.sql

# Apply corrections
echo "Applying corrections"
psql $BUILD_ENGINE -f sql/apply_corrections.sql
echo "Recalculating borough"
psql $BUILD_ENGINE -f sql/assign_boro.sql

# Recalculate units_net & phasing counts
echo "Deduplicating units"
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

# Overwrite automatically calculated units_net
echo "Force-setting units_net"
psql $BUILD_ENGINE -f sql/correct_units_net.sql

echo "Calculating count phasing fields"
psql $BUILD_ENGINE -f sql/phasing_counts.sql
