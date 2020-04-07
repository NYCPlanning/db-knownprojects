#!/bin/bash
source config.sh

START=$(date +%s);

# assign bbl geometries and column mapping
psql $BUILD_ENGINE -f sql/dcp_application.sql       # ZAP filtered applications
psql $BUILD_ENGINE -f sql/dcp_housing.sql           # DOB permits & applications
psql $BUILD_ENGINE -f sql/dcp_n_study_future.sql    # Future neighborhood studies
psql $BUILD_ENGINE -f sql/dcp_n_study_projected.sql # Neighborhood study projected development sites
psql $BUILD_ENGINE -f sql/dcp_n_study.sql           # Neighborhood Study Rezoning Commitments
psql $BUILD_ENGINE -f sql/edc_projects.sql          # EDC projects
psql $BUILD_ENGINE -f sql/esd_projects.sql          # ESD projects
psql $BUILD_ENGINE -f sql/hpd_pc.sql                # HPD Projected Closings
psql $BUILD_ENGINE -f sql/hpd_rfp.sql               # HPD RFPs
psql $BUILD_ENGINE -f sql/dcp_planneradded.sql      # Planner added projects

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'