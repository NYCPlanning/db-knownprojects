#!/bin/bash
source config.sh

docker run --rm\
            -v `pwd`:/home/knownprojects_build\
            -w /home/knownprojects_build\
            --env-file .env\
            sptkl/cook:latest bash -c "pip3 install -r python/requirements.txt; 
                                        python3 python/carto_to_build.py"

psql $BUILD_ENGINE -f sql/cluster_updates.sql

