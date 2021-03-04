#!/bin/bash
source config.sh

# Create functions and procedures
psql $BUILD_ENGINE -1 -f _sql/_functions.sql
psql $BUILD_ENGINE -1 -f _sql/_procedures.sql

# Map source data
psql $BUILD_ENGINE -1 -f _sql/dcp_application.sql
psql $BUILD_ENGINE -1 -f _sql/dcp_housing.sql
psql $BUILD_ENGINE -1 -f _sql/combine.sql

# Find and correct matches between non-DOB sources
psql $BUILD_ENGINE -1 -f _sql/_project_inputs.sql

# Find matches between DOB and non-DOB sources
psql $BUILD_ENGINE -1 -f _sql/dob_match.sql
