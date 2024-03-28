###########################################
# Custom Adjustment Script
# Remove all speakers and their associations
# for given event_id
###########################################

require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

EVENT_ID = ARGV[0]

speakers = Speaker.where("event_id = ? AND NOT EXISTS(SELECT * FROM sessions_speakers as a WHERE speakers.id = a.speaker_id )", EVENT_ID).destroy_all
