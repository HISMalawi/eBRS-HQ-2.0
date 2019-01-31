#!/usr/bin/env bash
ENV=$1

echo "READING CONFIGURATIONS FOR METADATA"
USERNAME=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['username']"`
PASSWORD=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['password']"`
DATABASE=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['database']"`
HOST=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['host']"`

echo $ENV
echo 'BUILDING METADATA'
mysqldump -u $USERNAME -p$PASSWORD $DATABASE --tables   location location_tag location_tag_map > locations_metadata.sql

DIR=`pwd`
echo "GENERATED METADATA FILE : $DIR/locations_metadata.sql"

