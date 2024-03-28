###########################################
# Custom Adjustment Script
# update attendee pn filters based on their
# custom_filter_1 type and their preexisting
# filters
###########################################

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

EVENT_ID = ARGV[0]

pn_filter_processor = PnFilterProcessor.new( EVENT_ID )

Attendee.where(event_id:EVENT_ID).each do |a|
  puts "Updating #{a.last_name}"

  processed_filters = pn_filter_processor.process_filters(
    a.custom_filter_1, # this could be based on a database stored column_name
    JSON.parse( a.pn_filters || '[]' )
  )

  puts "Attendee Type: #{a.custom_filter_1}".green
  puts "Old filters: #{a.pn_filters}"
  puts "New filters: #{processed_filters[:updated_filters]}"

  pn_filters = unless processed_filters[:updated_filters].blank?
                 processed_filters[:updated_filters].to_s
               else 
                 nil
               end
    
  a.update! pn_filters: pn_filters

end
