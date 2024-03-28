###########################################
# Custom Adjustment Script
# Remove all sessions without video urls and
# then abandoned speakers for given event_id
###########################################

require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

EVENT_ID = ARGV[0]

def sessions_without_video_urls
  Session.where(
    'event_id = ? AND (embedded_video_url IS NULL OR embedded_video_url = "")',
    EVENT_ID
  )
end

sessions_without_video_urls.destroy_all

# probably this where should be put in the Speaker class definition, it's pretty useful
Speaker.where("event_id = ? AND NOT EXISTS(SELECT * FROM sessions_speakers as a WHERE speakers.id = a.speaker_id )", EVENT_ID).destroy_all

