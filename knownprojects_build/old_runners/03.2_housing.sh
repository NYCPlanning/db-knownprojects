#!/bin/bash
source config.sh

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
        python3 python/carto_to_build.py;
        python3 python/update_proj_tables.py"

psql $BUILD_ENGINE -f sql/combine.sql
psql $BUILD_ENGINE -f sql/dob_match.sql

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
        python3 python/upload_dob_match_to_carto.py"

