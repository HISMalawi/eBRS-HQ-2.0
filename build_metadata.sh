#!/usr/bin/env bash

unset username

# clear

echo "Specify database name:"

read database

STR=$'Enter username:\r'

echo "$STR"

read username

# clear

unset password

prompt="Enter Password:"
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt='*'
    password+="$char"
done

mysqldump -u $username -p$password $database --tables birth_registration_type level_of_education  location location_tag mode_of_delivery person_attribute_types person_relationship_types person_identifier_types person_type_of_births person_type role statuses > metadata.sql
clear

echo "Done!"
