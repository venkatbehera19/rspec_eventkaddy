###########################################
#Custom Adjustment Script
#Remove all session files, session file versions
# and associated event_files
###########################################

require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

EVENT_ID = ARGV[0]

# use delete_all because destroy_all breaks on session_file_urls update when associated session does not exist
SessionFile.where(event_id:EVENT_ID).delete_all
SessionFileVersion.where(event_id:EVENT_ID).delete_all
EventFile.where(event_id:EVENT_ID, event_file_type_id:13).delete_all

Session.where(event_id:EVENT_ID).each {|s|
  s.update_attribute(:session_file_urls, nil)
}
