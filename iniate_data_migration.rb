#!/usr/bin/env sh

echo "Initiating the scripts to run ...";



echo "Checking the script(s) ...";

 [ -f bin/migration_data.rb ]  &&  echo "Migrating the SINGLE birth registration. Please wait..."   &&  rails r bin/migration_data.rb  &&  echo "Log file path: app/assets/data/error_log.txt."  || echo "Error! File not found...";

echo "=================================== Data migration in progress. Please wait...";


[ -f bin/first_multiple_births.rb ]  &&  echo "Migrating the first multiple birth registrations..."  &&  rails r bin/first_multiple_births.rb  &&  echo "Log file path: app/assets/data/error_log.txt and app/assets/data/suspected.txt"  || echo "Error! File not found...";


echo "==================================== Data migration in progress. Please wait...";


[ -f bin/second_multiple_births.rb ]  &&  echo "Migrating the second MULTIPLE birth registrations..."  &&  rails r bin/second_multiple_births.rb  &&  echo "Log file path: app/assets/data/error.log AND app/assets/data/suspected.txt"  || echo "Error! File not found...";

