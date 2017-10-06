#!/usr/bin/env sh

echo "Initiating the scripts to run ...";


echo "Checking the script(s) ...";

echo "";

 [ -f bin/migration_data.rb ]  &&  echo "Migrating the SINGLE birth registration. Please wait..."   &&  rails r bin/migration_data.rb  &&  echo "Log file path: app/assets/data/error_log.txt."  || echo "Error! File not found...";

echo "";

