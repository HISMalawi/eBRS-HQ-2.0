#!/usr/bin/env bash
ENV=$1
NM=$2

echo "READING CONFIGURATIONS FOR METADATA"
USERNAME=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['username']"`
PASSWORD=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['password']"`
DATABASE=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['database']"`
HOST=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['host']"`

echo $ENV
echo 'BUILDING DATA WITHOUT SCHEMA'

mysqldump -u $USERNAME -p$PASSWORD  --no-create-info $DATABASE --tables  users -w"person_id LIKE '100279%'"  > tmp2.sql

mysqldump -u $USERNAME -p$PASSWORD  --no-create-info $DATABASE --tables user_role -w" user_id LIKE '100279%' " > tmp3.sql

cat tmp2.sql tmp3.sql > $NM

rm tmp2.sql tmp3.sql

DIR=`pwd`
echo "GENERATED DUMP FILE : $DIR/$NM"

