#!/bin/bash
source config.sh

# Create functions and procedures
psql $BUILD_ENGINE -1 -f sql/_functions.sql
psql $BUILD_ENGINE -1 -f sql/_procedures.sql

# Map source data
psql $BUILD_ENGINE -1 -f sql/dcp_application.sql
psql $BUILD_ENGINE -1 -f sql/dcp_housing.sql
psql $BUILD_ENGINE -1 -f sql/combine.sql
psql $BUILD_ENGINE -1 -c "CALL apply_correction('_combined', 'corrections_main');"
psql $BUILD_ENGINE -c "VACUUM ANALYZE _combined;"

# Find and matches between non-DOB sources
psql $BUILD_ENGINE -1 -f sql/_project_record_ids.sql

# Apply corrections to reassign records to projects
psql $BUILD_ENGINE -1 -f sql/correct_projects.sql
psql $BUILD_ENGINE -c "VACUUM ANALYZE _project_record_ids;"

# Find matches between DOB and non-DOB sources
psql $BUILD_ENGINE -1 -f sql/dob_match.sql

# Create project IDs and deduplicate units
psql $BUILD_ENGINE -1 -f sql/project_record_ids.sql 
psql $BUILD_ENGINE -c "VACUUM ANALYZE project_record_ids;"

# Dedup units
python3 -m python.dedup_units
psql $BUILD_ENGINE -1 -c "CALL apply_correction('deduped_units', 'corrections_main');"
psql $BUILD_ENGINE -c "VACUUM ANALYZE deduped_units;"

# Create KPDB
psql $BUILD_ENGINE -1 -f sql/create_kpdb.sql
