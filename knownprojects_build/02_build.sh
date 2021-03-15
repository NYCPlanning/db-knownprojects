#!/bin/bash
source config.sh

# Create functions -- these get used to create flags
psql $BUILD_ENGINE -1 -f _sql/_functions.sql

# Map source data
psql $BUILD_ENGINE -1 -f _sql/dcp_application.sql
psql $BUILD_ENGINE -1 -f _sql/dcp_housing.sql
psql $BUILD_ENGINE -1 -f _sql/combine.sql

# Find and matches between non-DOB sources
psql $BUILD_ENGINE -1 -f _sql/_project_record_ids.sql

# Apply corrections to reassign records to projects
psql $BUILD_ENGINE -1 -f _sql/correct_projects.sql

# Find matches between DOB and non-DOB sources
psql $BUILD_ENGINE -1 -f _sql/dob_match.sql

# Create project IDs and deduplicate units
psql $BUILD_ENGINE -1 -f _sql/project_record_ids.sql |
docker run --rm\
    -v $(pwd):/home/knownprojects_build\
    -w /home/knownprojects_build\
    python:3.7-slim sh -c "
        pip3 install pandas; 
        python3 _python/dedup_units.py" |
psql $BUILD_ENGINE -1 -f _sql/create_kpdb.sql