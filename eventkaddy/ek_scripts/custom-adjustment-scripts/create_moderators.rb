###########################################
#Custom Adjustment Script
#Update the track_subtrack field in the
#session table
###########################################

require 'roo'
require 'mysql2'
require 'date'

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'


#for active record usage
require 'active_record'

#load the rails 3 environment
require_relative '../../config/environment.rb'  


ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

#setup variables
event_id = 50 #ARGV[0] #1, 2, 3, etc
#spreadsheet_file = ARGV[1] #session-data.ods, bobs-sessions.ods, etc

event = Event.find(event_id)

event_name = event.name.gsub(/\s/,"").downcase

role_id = Role.where(name:"Moderator").first.id

# puts event_name

emails = ["#{event_name}@eventkaddy.net"]

emails.each do |email|

	#add user account, if email address isn't in use by another user
	users = User.where(email:email)
	if (users.length==0) then
		user          = User.new
		user.email    = email.to_s
		user.password = "#{event_name}AA33"
		if user.save!
			puts "user id: #{user.id}"

			user_role         = UsersRole.new()
			user_role.role_id = role_id
			user_role.user_id = user.id
			user_role.save()

			users_event = UsersEvent.where(user_id:user.id,event_id:event_id).first_or_initialize
			users_event.save()
		else
					puts "User failed to save."
		end
	else
		puts "user already exists with email address: #{email}"
	end

end

