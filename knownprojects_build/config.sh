#!/bin/bash
if [ -f .env ]
then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

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