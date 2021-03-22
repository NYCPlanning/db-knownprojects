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
        
        CSV_export combined &

        CSV_export review_project &
        CSV_export review_dob &

        CSV_export corrections_applied &
        CSV_export corrections_not_applied &
        CSV_export corrections_dob_match &
        CSV_export corrections_project &
        CSV_export corrections_main &

        SHP_export combined MULTIPOLYGON &
        SHP_export review_project MULTIPOLYGON &
        SHP_export review_dob MULTIPOLYGON 

        wait
        Compress combined.csv
        Compress review_dob.csv
        Compress review_project.csv
    ) 

    echo "Exporting output tables"
    CSV_export kpdb
    Compress kpdb.csv
    SHP_export kpdb MULTIPOLYGON
)

# Upload
python3 -m python.upload