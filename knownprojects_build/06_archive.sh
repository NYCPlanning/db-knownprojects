#!/bin/bash
source config.sh

START=$(date +%s);
# archive devDB
pg_dump -t kp_export --no-owner $BUILD_ENGINE | psql $EDM_DATA

psql $EDM_DATA -c "CREATE SCHEMA IF NOT EXISTS knownprojects;";
psql $EDM_DATA -c "ALTER TABLE kp_export SET SCHEMA knownprojects;";
psql $EDM_DATA -c "DROP VIEW IF EXISTS knownprojects.latest;";
psql $EDM_DATA -c "DROP TABLE IF EXISTS knownprojects.\"$VERSION\";";
psql $EDM_DATA -c "ALTER TABLE knownprojects.kp_export RENAME TO \"$VERSION\";";
psql $EDM_DATA -c "CREATE VIEW knownprojects.latest AS (SELECT '$VERSION' as v, * FROM knownprojects.\"$VERSION\");"

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'