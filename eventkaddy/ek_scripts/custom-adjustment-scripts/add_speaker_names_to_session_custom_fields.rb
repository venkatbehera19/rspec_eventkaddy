###########################################
#Custom Adjustment Script
#Update the custom_fields field in the
#session table
###########################################

require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

EVENT_ID = ARGV[0]

Session.select('id, session_code, title, custom_fields').where(event_id:EVENT_ID).each do |session|
	puts "updating session: #{session.session_code} #{session.title}"
	speaker_names = session.speakers.map {|s| "#{s.first_name.strip} #{s.last_name.strip} #{s.honor_suffix.strip}"}.join ', '
	speaker_names = speaker_names[0..80] + '...' if speaker_names.length > 83
	session.update_attribute :custom_fields, speaker_names
end
