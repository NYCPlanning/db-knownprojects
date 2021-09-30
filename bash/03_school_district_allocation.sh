#!/bin/bash
source bash/config.sh

# Perform school district join
psql $BUILD_ENGINE -1 -f sql/school_district_csd.sql
psql $BUILD_ENGINE -1 -f sql/school_district_es_zone.sql
psql $BUILD_ENGINE -1 -f sql/school_district_subdistricts.sql