# eBRS-HQ-2.0i
The order of SETTING up EBRS is
  HQ to DC to FC
Metadata is moved from HQ to DC and FC

`
Initial Setup Instructions

1. Usual Things
   	-Copy all .yml.example files in config to .yml files
	-Specify the required paramaters in the yml files

2. Run bundle install --local

3. Run the command

   ./setup.sh production

    when in development change production to development


Good Luck!!

./setup.sh development /var/www/ebrs-touch/metadata.sql
