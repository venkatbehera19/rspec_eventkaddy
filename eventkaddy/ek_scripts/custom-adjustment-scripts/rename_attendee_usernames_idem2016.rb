###########################################
#Custom Adjustment Script
# Attendee usernames mistakenly has .0 at the end,
# from their account code being interpretted as a float
# so remove it
###########################################

require 'mysql2'

require_relative '../settings.rb'
require_relative '../utility-functions.rb'

require 'active_record'

require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

EVENT_ID = 82#ARGV[0]

attendee_names_updated = []
usernames_updated      = []

def has_dot_zero_ending?(string)
	string.include? '.0'
end

Attendee.select('id, username')
        .where(event_id:EVENT_ID)
        .each do |attendee|
        	if has_dot_zero_ending? attendee.username
        		old_name = attendee.username
        		attendee.update!(username:old_name.chomp('.0'))
	        	usernames_updated << "#{old_name} to #{attendee.username}"
						attendee_names_updated << attendee.id
					end
				end

puts "Number of Attendees Removed: #{attendee_names_updated.length}".yellow
usernames_updated.each {|a|
	puts a.green}





