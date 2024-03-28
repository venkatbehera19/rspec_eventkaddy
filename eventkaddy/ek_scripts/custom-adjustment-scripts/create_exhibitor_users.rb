###########################################
# Custom Adjustment Script
# to add exhibitor portal users based
# on exhibitor email
###########################################

require_relative '../settings.rb' #config

require 'active_record'

require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)

# bundle exec ruby ./create_exhibitor_users.rb 82 idemsg16

event_id     = ARGV[0]
default_pass = ARGV[1]
role_id      = Role.where(name:"Exhibitor").first.id
count        = 0

Exhibitor.select('id, email, user_id').where(event_id:event_id).each do |exhibitor|

  next if exhibitor.email.blank?

  users = User.where(email:exhibitor.email)

  if users.length==0
    puts "Creating user for #{exhibitor.email}".green
    user = User.create(email:exhibitor.email, password: default_pass)
    UsersRole.create(user_id:user.id, role_id:role_id)
    UsersEvent.create(user_id:user.id, event_id:event_id)
    exhibitor.update_column(:user_id, user.id) #doesn't invoke callbacks, ie before_save etc
    count = count + 1
  else
    puts "User already exists with email address: #{exhibitor.email}".red
  end

end

puts "Created #{count} new users."
