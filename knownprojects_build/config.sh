#!/bin/bash
if [ -f .env ]
then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

function max_bg_procs {
    if [[ $# -eq 0 ]] ; then
            echo "Usage: max_bg_procs NUM_PROCS.  Will wait until the number of background (&)"
            echo "           bash processes (as determined by 'jobs -pr') falls below NUM_PROCS"
            return
    fi
    local max_number=$((0 + ${1:-0}))
    while true; do
            local current_number=$(jobs -pr | wc -l)
            if [[ $current_number -lt $max_number ]]; then
                    break
            fi
            sleep 1
    done
}

function import_private {
  name=$1
  version=${2:-latest} #default version to latest
  version=$(mc cat spaces/edm-recipes/datasets/$name/$version/config.json | jq -r '.dataset.version')
  echo "$name version: $version"
  mc cp spaces/edm-recipes/datasets/$name/$version/$name.sql $name.sql
  psql $BUILD_ENGINE -f $name.sql
  rm $name.sql
}

function import_public {
  name=$1
  version=${2:-latest}
  version=$(curl -s https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/$name/$version/config.json | jq -r '.dataset.version')
  echo "$name version: $version"
  curl -O https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/$name/$version/$name.sql
  psql $BUILD_ENGINE -f $name.sql
  rm $name.sql
}