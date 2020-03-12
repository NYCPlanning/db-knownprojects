#!/bin/bash
source config.sh

START=$(date +%s);

# put your sql executions as the below format
# psql $BUILD_ENGINE -f sql/<function>.sql

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'