#!/bin/bash
source config.sh

START=$(date +%s);

# create a geometries table at source data/bbl level
psql $BUILD_ENGINE -f sql/bbl_geoms.sql
psql $BUILD_ENGINE -f sql/load_to_geoms.sql
psql $BUILD_ENGINE -f sql/load_and_combine_geoms.sql

# create a geometries table at project level
psql $BUILD_ENGINE -f sql/project_geoms.sql
psql $BUILD_ENGINE -f sql/load_to_projects.sql
psql $BUILD_ENGINE -f sql/load_and_combine_projects.sql
psql $BUILD_ENGINE -f sql/qc_.sql
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_geoms_stats) TO '$(pwd)/output/qc_geoms_stats.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_bbl_needgeoms) TO '$(pwd)/output/qc_bbl_needgeoms.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_project_needgeoms) TO '$(pwd)/output/qc_project_needgeoms.csv' DELIMITER ',' CSV HEADER;"

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'