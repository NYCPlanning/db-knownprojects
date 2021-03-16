#!/bin/bash
source config.sh

echo "Generate output tables"
psql $BUILD_ENGINE -f sql/_export.sql

rm -rf output
mkdir -p output 
(
    cd output

    echo "Exporting review tables"
    mkdir -p review

    (
        cd review

        CSV_export dob_review
        CSV_export combined
        CSV_export corrections_applied
        CSV_export corrections_not_applied
        CSV_export corrections_dob_match
        CSV_export corrections_project
        CSV_export corrections_main

        SHP_export $BUILD_ENGINE combined MULTIPOLYGON combined
        SHP_export $BUILD_ENGINE dob_review MULTIPOLYGON dob_review
    )

    echo "Exporting output tables"
    CSV_export kpdb
    SHP_export $BUILD_ENGINE kpdb MULTIPOLYGON kpdb
    echo "[$(date)] $DATE" > version.txt
)

zip -r output/output.zip output

#Upload latest &
#Upload $DATE
#rm -rf output

wait 
echo "Upload Complete"
