require_relative './settings.rb'
require_relative '../config/environment.rb'


ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

register_form = RegistrationForm.all

current_date = DateTime.now.utc

count = 0

register_form.each do |record|
  saved_for = current_date - record.updated_at # in seconds
  saved_for_hour = saved_for / 3600 # in hours
  if saved_for_hour > 1.0
    record.destroy
    count += 1
  end
end

puts "Destroyed #{count} records of RegistrationForm"