#!/bin/bash
source config.sh

START=$(date +%s);
# archive devDB
pg_dump -t kp_export --no-owner $BUILD_ENGINE | psql $EDM_DATA
DATE=$(date "+%Y/%m/%d");
psql $EDM_DATA -c "CREATE SCHEMA IF NOT EXISTS knownprojects;";
psql $EDM_DATA -c "ALTER TABLE kp_export SET SCHEMA knownprojects;";
psql $EDM_DATA -c "DROP VIEW IF EXISTS knownprojects.latest;";
psql $EDM_DATA -c "DROP TABLE IF EXISTS knownprojects.\"$DATE\";";
psql $EDM_DATA -c "ALTER TABLE knownprojects.kp_export RENAME TO \"$DATE\";";
psql $EDM_DATA -c "CREATE VIEW knownprojects.latest AS (SELECT '$DATE' as v, * FROM knownprojects.\"$DATE\");"

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'