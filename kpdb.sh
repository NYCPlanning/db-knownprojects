#!/bin/bash
source bash/config.sh

case $1 in 
    dataloading ) ./bash/01_dataloading.sh;;
    build ) ./bash/02_build.sh;;
    export ) shift && ./bash/03_export.sh $@;;
    archive ) ./bash/04_archive.sh;;
    * ) echo "$@ command not found";
esac
