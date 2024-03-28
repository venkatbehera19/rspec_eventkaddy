require_relative '../settings.rb'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

event_id = ARGV[0]
puts event_id

attendees = Attendee.where(event_id:event_id)

puts attendees.length

attendees.each do |attendee|
  unless attendee.is_demo == true
    attendee.generate_and_save_simple_password
    puts attendee.password
  end
end

