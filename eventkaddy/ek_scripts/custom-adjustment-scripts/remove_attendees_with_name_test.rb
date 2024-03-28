###########################################
#Custom Adjustment Script
#Add attendees to PGA event (manually create hash)
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

EVENT_ID = 78#ARGV[0]

attendee_ids_to_remove              = []
names_of_attendees_being_removed = []

def has_test?(string)
	string = string.downcase
	string.include? 'test'
end

Attendee.select('id, first_name, last_name')
        .where(event_id:EVENT_ID)
        .each do |attendee|
        	if has_test?(attendee.first_name) || has_test?(attendee.last_name)
	        	names_of_attendees_being_removed << "#{attendee.first_name} #{attendee.last_name}"
						attendee_ids_to_remove << attendee.id
					end
				end

Attendee.where(id:attendee_ids_to_remove).destroy_all

puts "Number of Attendees Removed: #{attendee_ids_to_remove.length}".yellow
names_of_attendees_being_removed.each {|a|
	puts a.green}





