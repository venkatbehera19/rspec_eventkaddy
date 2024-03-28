###########################################
#Custom Adjustment Script
#Add users_events association for all
#speakers with given event_id
###########################################

require 'roo'
require 'mysql2'
require 'date'

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'


#for active record usage
require 'active_record'

#load the rails 3 environment
require_relative '../../config/environment.rb'  


ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

#setup variables
event_id = ARGV[0] #1, 2, 3, etc
#spreadsheet_file = ARGV[1] #session-data.ods, bobs-sessions.ods, etc


colLetter=['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']

Speaker.where(event_id:event_id).each do |speaker|

	#look up user
	users = User.where(email:speaker.email)

	if (users.length==1) then
		puts "linking #{users.first.email} with event id #{event_id}"
		users_event = UsersEvent.where(user_id:users.first.id,event_id:event_id).first_or_initialize
		users_event.save()

	elsif (users.length==0) then
		puts "db error: No user records with email address: #{speaker.email}"
		next
	elsif (users.length > 1) then
		puts "db error: Multiple user records with email address: #{speaker.email}"
		next
	end
end




	
	
	
	
	

