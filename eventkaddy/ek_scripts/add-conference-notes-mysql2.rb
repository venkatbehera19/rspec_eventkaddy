###########################################
#Ruby script to import session data from
#spreadsheet (ODS) into EventKaddy CMS
###########################################

require 'roo'
require 'mysql2'
require 'date'

require_relative './settings.rb' #config
require_relative './utility-functions.rb'


#for active record usage
require 'active_record'

#load the rails 3 environment
require_relative '../config/environment.rb'  


ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

#setup variables
event_id = ARGV[0] #1, 2, 3, etc

### for each session, add a conference note ###
sessions = Session.where(event_id:event_id)

session_file_type = SessionFileType.where(name:'conference note').first

sessions.each do |session|

	puts "creating/updating conference note for session #{session.title}"
	session_file = SessionFile.where({event_id:event_id,session_id:session.id,session_file_type_id:session_file_type.id}).first_or_initialize()
	session_file.update!(title:'Convention Note',description:'Please upload a Word or PDF document')

end




	
	
	
	
	

