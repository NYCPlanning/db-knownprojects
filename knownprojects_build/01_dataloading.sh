#!/bin/bash
source config.sh

# Load source data
for f in $(ls data/processed)
do 
    psql $BUILD_ENGINE -f data/processed/$f
done