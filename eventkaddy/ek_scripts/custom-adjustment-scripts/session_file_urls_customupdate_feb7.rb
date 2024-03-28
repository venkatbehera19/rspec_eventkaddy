###########################################
#Custom Adjustment Script
#Set the production URLs in the session
#table for the finalized conference notes
#for WVC 2014
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
	:adapter  => "mysql2",
	:host     => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

#setup variables
event_id = ARGV[0] #1, 2, 3, etc
#spreadsheet_file = ARGV[1] #session-data.ods, bobs-sessions.ods, etc

Session.where(event_id:event_id).each do |session|

	puts "======= #{session.title} ======="

	unless session.session_file_urls.blank?
		puts "----- updating session_file_urls ------"
		session_file_urls = session.session_file_urls.gsub(/2015_/,"2015-")
		session.update!(session_file_urls:session_file_urls)
		puts "----- updated to #{session_file_urls} ------"
	end

end