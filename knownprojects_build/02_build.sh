#!/bin/bash
source config.sh

# Create functions and procedures
psql $BUILD_ENGINE -1 -f _sql/_functions.sql
psql $BUILD_ENGINE -1 -f _sql/_procedures.sql

# Map source data
psql $BUILD_ENGINE -1 -f _sql/dcp_application.sql
psql $BUILD_ENGINE -1 -f _sql/dcp_housing.sql
psql $BUILD_ENGINE -1 -f _sql/combine.sql
psql $BUILD_ENGINE -1 -c "CALL apply_correction('_combined');"
psql $BUILD_ENGINE -c "VACUUM ANALYZE _combined;"

# Find and matches between non-DOB sources
psql $BUILD_ENGINE -1 -f _sql/_project_record_ids.sql

# Apply corrections to reassign records to projects
psql $BUILD_ENGINE -1 -f _sql/correct_projects.sql
psql $BUILD_ENGINE -c "VACUUM ANALYZE _project_record_ids;"

# Find matches between DOB and non-DOB sources
psql $BUILD_ENGINE -1 -f _sql/dob_match.sql

# Create project IDs and deduplicate units
psql $BUILD_ENGINE -1 -f _sql/project_record_ids.sql 
psql $BUILD_ENGINE -c "VACUUM ANALYZE project_record_ids;"

# Dedup units
python3 -m _python.dedup_units
psql $BUILD_ENGINE -1 -c "CALL apply_correction('dedup_units');"
psql $BUILD_ENGINE -c "VACUUM ANALYZE dedup_units;"

# Create KPDB
psql $BUILD_ENGINE -1 -f _sql/create_kpdb.sql
