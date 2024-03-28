###########################################
# Custom Adjustment Script
# set all flags to web for bcbs 2017 attendee sessions
###########################################

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2", :host => @db_host, :username => @db_user,
  :password => @db_pass, :database => @db_name)

EVENT_ID     = 119
attendee_ids = Attendee.where(event_id:EVENT_ID).pluck(:id)

SessionsAttendee
  .where(attendee_id:attendee_ids)
  .where('flag != "web"')
  .each { |sa| sa.update!(flag:'web') }
