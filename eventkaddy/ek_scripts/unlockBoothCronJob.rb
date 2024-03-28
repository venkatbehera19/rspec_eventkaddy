################################################
# Unlock Location Mapping record that are locked
################################################

require 'date'
require_relative './settings.rb'
require_relative '../config/environment.rb'


ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

LocationMapping.where.not(locked_by: nil).each do |booth|
  time_left = (DateTime.now.utc - booth.locked_at) / 60
  if time_left > 10
    booth.locked_at = nil
    booth.locked_by = nil
    booth.save
  end
end
