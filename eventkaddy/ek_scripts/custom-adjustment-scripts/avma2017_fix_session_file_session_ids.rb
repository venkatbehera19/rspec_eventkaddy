###########################################
# Custom Adjustment Script
# use session_codes for correct event id
###########################################

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2", :host => @db_host, :username => @db_user,
  :password => @db_pass, :database => @db_name)

EVENT_ID = 118

SessionFile.where(event_id:EVENT_ID).each {|sf|
  puts "SessionFile id: #{sf.id}"
  original_session = sf.session
  unless original_session
    puts "Skipped because no session existed with session_file.session_id".red
    next
  end
  session_code = original_session.session_code
  session_id = Session
    .where(event_id:EVENT_ID, session_code:session_code)
    .first
    .id

  puts "Updating #{session_code}"
  sf.update! session_id: session_id

}
