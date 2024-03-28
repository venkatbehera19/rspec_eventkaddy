require 'mysql2'
require_relative '../settings.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(adapter:"mysql2", host:@db_host, username:@db_user, password:@db_pass, database:@db_name)
event_id = ARGV[0]
puts Tag.add_all_session_order_tag_data(event_id).inspect.green

