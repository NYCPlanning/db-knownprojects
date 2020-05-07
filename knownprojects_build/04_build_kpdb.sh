#!/bin/bash
source config.sh
psql $BUILD_ENGINE -f sql/update_combined_dob.sql

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
        python3 python/resolve_clusters.py"

psql $BUILD_ENGINE -f sql/add_remaining_n_study.sql
psql $BUILD_ENGINE -f sql/phasing.sql
psql $BUILD_ENGINE -f sql/phasing_counts.sql