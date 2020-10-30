#!/usr/bin/env bash
ENV=$1

echo "READING CONFIGURATIONS FOR METADATA"

echo $ENV
echo 'BUILDING DATA WITHOUT SCHEMA'


mysqldump -u root -pebrs.root ebrs2_hq --tables users user_role -w" user_id LIKE '100279%'"  > new_hq_users.sql

DIR=`pwd`
echo "GENERATED DUMP FILE : $DIR/new_hq_users.sql"

