#!/bin/bash
source bash/config.sh

echo "Create the longfrom SCA Aggregate Tables..."

echo "Preprocess column names to standardize"
#Preprocess the tables to standardize geometry column name 
psql $BUILD_ENGINE -1 -f sca_aggregate/preprocessing.sql

echo "Create ZAP Project Many BBLs table"
# Create the `zap_projects_many_bbls`` table
psql $BUILD_ENGINE -1 -f sca_aggregate/create_zap_projects.sql

# Aggregate KPDB projects to Elementary School Zones 
echo "Build Elementary School Zones Aggregate Table"
psql $BUILD_ENGINE -1 -f sca_aggregate/boundaries_es_zone.sql

echo "Build School Districts aggregate table"
# Aggregate KPDB projects to School District Zones
psql $BUILD_ENGINE -1 -f sca_aggregate/boundaries_school_districts.sql

echo "Build School Subdistricts aggregate tables"
# Aggregate KPDB projects to School Subdistrict Zones
psql $BUILD_ENGINE -1 -f sca_aggregate/boundaries_school_subdistricts.sql

echo "SCA Longform Aggregate tables are complete"

echo "Export SCA Aggregate tables"


rm -rf sca_aggregate/sca_output
mkdir -p sca_aggregate/sca_output

(
    cd sca_aggregate/sca_output

    echo "Exporting SCA Aggregate tables"

    (
        
        CSV_export longform_csd_output &
        CSV_export longform_es_zone_output &
        CSV_export longform_subdist_output_cp_assumptions
        wait
    )
    echo "Export complete"

)


