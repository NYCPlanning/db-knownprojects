#!/bin/bash
source config.sh

docker run --rm\
            -v `pwd`:/home/knownprojects_build\
            -w /home/knownprojects_build\
            --env-file .env\
            sptkl/cook:latest bash -c "python3 python/dataloading.py"

# postgres version = 11
pg_dump $ZAP_ENGINE -t project_geoms -O -c | psql $BUILD_ENGINE
pg_dump $ZAP_ENGINE -t dcp_projectaction -O -c | psql $BUILD_ENGINE
pg_dump $ZAP_ENGINE -t dcp_projectbbl -O -c | psql $BUILD_ENGINE
pg_dump $ZAP_ENGINE -t dcp_project -O -c | psql $BUILD_ENGINE