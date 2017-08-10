# eBRS-HQ-2.0i

Initial Setup Instructions

1. Usual Things
   	-Copy all .yml.example files in config to .yml files
	-Specify the required paramters in the yml files
	
2. Run bundle install --local
3. Create the specified couch databases manually in couch db (This will later be removed; app to be doing this automatically)
3. Run the following in the sequence provided
	bundle exec rake db:create db:schema:load db:seed

4. Get sql metadata by running the following from application root
	./build_metadata.sh
	
	You will be asked to provide SQL  database, username and password
	This command generates metadata.sql file at root 
	This file will be loaded to all DC and FC applications soon after they are initialied

Good Luck!!

