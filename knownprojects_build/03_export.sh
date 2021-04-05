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
        SHP_export combined MULTIPOLYGON &
        SHP_export review_project MULTIPOLYGON &
        SHP_export review_dob MULTIPOLYGON &
        psql $BUILD_ENGINE  -c "ALTER TABLE review_project DROP COLUMN geom;" &
        psql $BUILD_ENGINE  -c "ALTER TABLE review_dob DROP COLUMN geom;" &
        wait 
        
        CSV_export combined &
        CSV_export review_project &
        CSV_export review_dob &
        CSV_export corrections_applied &
        CSV_export corrections_not_applied &
        CSV_export corrections_zap &
        CSV_export corrections_dob_match &
        CSV_export corrections_project &
        CSV_export corrections_main &
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

mv run_notes.txt output/run_notes.txt

# Upload
SENDER=${1:-unknown}
python3 -m python.upload $SENDER
