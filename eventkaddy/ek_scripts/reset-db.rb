##################################################
# Script to import default values for a selction
# of EventKaddy CMS tables
#
##################################################

require 'rubygems'
require 'spreadsheet'
require 'nokogiri'
require 'builder'
require 'hpricot'
require 'oauth'
require 'zip/zipfilesystem'
require 'roo'
require 'mysql'

require './settings.rb' #config

# ------ RESET EVENTKADDY DB -------
begin	
	# connect to the MySQL server
	dbh = Mysql.real_connect(@db_host, @db_user, @db_pass, @db_name)
	# get server version string and display it
	puts "Server version: " + dbh.get_server_info
	
	#truncate the relevant tables
	tables=['coupons','enhanced_listings','events','exhibitor_links','exhibitors','home_button_entries','home_button_groups','link_types',
	'links','location_mapping_types','location_mappings','map_types','event_maps','event_files','notifications','organizations','record_comments','record_types',
	'sessions','sessions_speakers','sessions_subtracks','speaker_types','speakers','sponsor_level_types','sponsor_specifications','subtracks','tracks','roles','users','users_roles','users_events','users_organizations']

	tables.each do |tablename|
		sql='TRUNCATE TABLE `' + tablename + '`;' #empty the table, reset auto-increment to 0
		dbh.query(sql)
	end

	puts "Emptied EventKaddy DB \n"
	
rescue Mysql::Error => e
	puts "Error code: #{e.errno}"
	puts "Error message: #{e.error}"
	puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
ensure
	# disconnect from server
	dbh.close if dbh
end

	


	
	
	
	
	

