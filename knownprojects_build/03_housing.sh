#!/bin/bash
source config.sh

# Add dcp_housing records to projects
psql $BUILD_ENGINE -1 -f _sql/project_record_ids.sql