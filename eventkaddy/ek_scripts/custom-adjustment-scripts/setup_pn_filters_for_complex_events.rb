###########################################
# Custom Adjustment Script
# Setup fiserv Sales Kickoff pn filters, when there are 30+ filters
###########################################

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2", :host => @db_host, :username => @db_user,
  :password => @db_pass, :database => @db_name)

EVENT_ID     = 245
@event = Event.find(245)
business_units = Attendee.where(event_id:EVENT_ID).pluck(:business_unit)

puts business_units.to_a
business_units = business_units.uniq
print "business_units:#{business_units}"

bu_hash = {}
business_units.each do |bu|
  bu_hash[bu] = [bu]
end

pn_filters = []

bu_hash.each do |type, filters|
  unless type.blank?
    results = []
    filters.each do |filter|
      ary = filter.split
      results << [ary[0][0].downcase + ary[0][1..-1]] # downcase first letter
          .concat(ary[1..-1].map(&:capitalize)).join # cap first letter
    end
    bu_hash[type] = results.uniq
  end
end

@event.update! type_to_pn_hash: bu_hash

