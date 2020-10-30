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
mysqldump -u $USERNAME -p$PASSWORD  --no-create-info $DATABASE --tables person barcode_identifiers duplicate_records person_addresses person_attributes person_birth_details person_record_statuses potential_duplicates -w "person_id LIKE '100264%'" > tmp1.sql

mysqldump -u $USERNAME -p$PASSWORD  --no-create-info $DATABASE --tables person_relationship -w "person_a LIKE '100264%'" > tmp4.sql

mysqldump -u $USERNAME -p$PASSWORD  --no-create-info $DATABASE --tables core_person person_name users -w"person_id LIKE '100264%'"  > tmp2.sql

mysqldump -u $USERNAME -p$PASSWORD  --no-create-info $DATABASE --tables user_role -w" user_id LIKE '100264%' " > tmp3.sql

cat tmp2.sql tmp3.sql tmp1.sql tmp4.sql > $NM

rm tmp1.sql tmp2.sql tmp3.sql tmp4.sql

DIR=`pwd`
echo "GENERATED DUMP FILE : $DIR/$NM"

