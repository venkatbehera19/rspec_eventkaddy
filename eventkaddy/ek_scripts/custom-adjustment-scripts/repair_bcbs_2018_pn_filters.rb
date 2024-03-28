# attendees had incorrectly plain strings as their filters,
# so convert them to JSON arrays

require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(
  :adapter  => "mysql2",
  :host     => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)

EVENT_ID = 161

def repair_attendee_pn_filter a
  # unless null, empty string, or maybe a json array
  unless a.pn_filters.blank? || a.pn_filters.include?("[")
    a.update! pn_filters: a.pn_filters.split(',').as_json.to_s
  end
end

Attendee.where(event_id:EVENT_ID).each {|a| repair_attendee_pn_filter a }

# attendee = Attendee.find(260352)
# repair_attendee_pn_filter attendee
# attendee.pn_filters
