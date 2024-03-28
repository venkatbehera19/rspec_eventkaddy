###########################################
#Custom Adjustment Script
#Add users_events association for all
#speakers with given event_id
###########################################

require 'roo'
require 'mysql2'
require 'date'

require_relative '../../settings.rb' #config
require_relative '../../utility-functions.rb'


#for active record usage
require 'active_record'

#load the rails 3 environment
require_relative '../../../config/environment.rb'  

ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

#setup variables
event_id = 161

puts "SPEAKERS WITH BROKEN CMS URL LINKS:\n"

Speaker.where(event_id:event_id).each do |speaker|
	
	if (speaker.photo_filename !=nil) then
		web_url = URI.escape(speaker.photo_filename)
		
		# puts "#{speaker.first_name} #{speaker.last_name}"
	# 	if (web_url!=nil) then
	# 		`wget #{web_url}`
	# 	end
		
		begin
	  	open(web_url)
	 	rescue OpenURI::HTTPError
	  	puts "#{speaker.first_name} #{speaker.last_name}"
	 	else
	   #success
	 	end
  end
	 
end




	
	
	
	
	

