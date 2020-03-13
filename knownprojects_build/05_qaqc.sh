#!/bin/bash
source config.sh

START=$(date +%s);

# put your sql executions as the below format
psql $BUILD_ENGINE -f sql/bbl_geoms.sql
psql $BUILD_ENGINE -f sql/load_to_geoms.sql
psql $BUILD_ENGINE -f sql/load_and_combine_geoms.sql
psql $BUILD_ENGINE -f sql/qc_.sql
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_bblgeoms_stats) TO '$(pwd)/output/qc_bblgeoms_stats.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_bbl_needgeoms) TO '$(pwd)/output/qc_bbl_needgeoms.csv' DELIMITER ',' CSV HEADER;"

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'