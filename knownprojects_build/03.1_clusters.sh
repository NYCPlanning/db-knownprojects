#!/bin/bash
source config.sh

docker run --rm\
            -v `pwd`:/home/knownprojects_build\
            -w /home/knownprojects_build\
            --env-file .env\
            sptkl/cook:latest bash -c "pip3 install -r python/requirements.txt; 
                                        python3 python/clusters.py"