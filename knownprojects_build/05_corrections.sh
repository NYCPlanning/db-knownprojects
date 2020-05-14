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