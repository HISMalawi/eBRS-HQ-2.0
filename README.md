0. Follow instructions properly

GENERAL
1. Copy all .yml.example files in config removing .example 

2. Edit the configuration paramaters properly. 
	 In couchdb.yml specify source couch databases for child records, users and npids. leave crtkey to 'password'

3. Get a copy of private.pem and public.pem and paste in config/ 

4. Edit elasticsearchsetting.yml and add a line on index to match one for ebrs application running

5. Run 
		bundle install --local 

6. Sync all facility records to DC. Both FC and DC Migration will be handled from DC database

7. Initialie mysql database by running following command
 		
		./setup.sh development|production
	
	  choose one environment


MIGRATION PROCESS - FC
1. Start by migrating facility records
		For each facility get the corresponging facility location_id from location_table AND SET AS location_id IN settting.yml
		Also set migration_mode to 'FC'

2. Start migration process 
			bundle exec rails runner bin/migration_data.rb

3. After migration of FC, a dump will be automatically generated at root of application


MIGRATION PROCESS - DC

1. Using the same couchdb database, changes will be made only in settings.yml
	  	
2. In settings.yml, change location_id to location_id of district e.g 261 for Machinga
	
3. In settings.yml, also change migration_mode to 'DC'

4. Re-run migration script with same command
		bundle exec rails runner bin/migration_data.rb

5. After script has finished another dump with district name will be generated

WHAT TO DO WITH DUMPS

1. The first dump will be loaded in corresponding Facility database

2. The second dump for district will be loaded in two databases, the DC and the HQ
	




