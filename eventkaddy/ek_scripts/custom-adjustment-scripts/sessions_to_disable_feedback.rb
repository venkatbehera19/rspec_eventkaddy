###########################################
#Custom Adjustment Script
#Update the track_subtrack field in the
#session table
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
event_id = 50 #ARGV[0] #1, 2, 3, etc
#spreadsheet_file = ARGV[1] #session-data.ods, bobs-sessions.ods, etc


session_codes = ["621","551","21","23","26","28","25","45","41","616","22","24","27","29","552","553","30","31","32","51","18","46","42","20","33","34","36","37","35","19","47","43","40","38","39","48","44"]

Session.where(event_id:event_id,session_code:session_codes).each do |session|
	
	puts "----- updating session: #{session.session_code} ------"

	session.update!(feedback_enabled:false)
end

