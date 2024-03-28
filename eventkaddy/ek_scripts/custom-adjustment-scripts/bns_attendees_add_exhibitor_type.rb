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

EVENT_ID = 77

attendee_names_updated = []
types_updated          = []

Attendee.select('id, first_name, last_name, account_code, custom_filter_1')
        .where(event_id:EVENT_ID)
				.where('custom_filter_1 IS NULL OR custom_filter_1=""')
        .each do |attendee|
        		attendee.update!(custom_filter_1:'Exhibitor')
	        	types_updated << " #{attendee.account_code} #{attendee.first_name} #{attendee.last_name} set to Exhibitor"
						attendee_names_updated << attendee.id
				end

puts "Number of Attendees Updated: #{attendee_names_updated.length}".yellow
types_updated.each {|a|
	puts a.green}
