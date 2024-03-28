###########################################
#Ruby script to import session data from
#spreadsheet (ODS) into EventKaddy CMS
###########################################

require 'rubygems'
require 'mysql2'
require 'date'
require 'time'

require_relative './settings.rb' #config

#for active record usage
require 'active_record'

#load the rails 3 environment
require_relative '../config/environment.rb'  

include Rails.application.routes.url_helpers


ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

  def sendMail(event_id)

  	@event=event_id

    Speaker.where(event_id:@event,unsubscribed:[0,nil]).each do |speaker|
	    #determine number of remaining requirements yet to be filled
	    @requirements = Requirement.joins(:requirement_type).where(event_id:@event,required:true).where(requirement_types: { requirement_for: 'speaker' })
	    @requirements.each do |requirement|
	      attribute=speaker.read_attribute(requirement.requirement_type.name)
	      if !(attribute.nil? || attribute=="")
	        @requirements = @requirements.reject {|n| n==requirement}
	      end
	    end
	    puts "#{speaker.first_name} : requirements left: #{@requirements.length}"
	    if @requirements.length>0 then
			    list= ""
			    @requirements.each do |requirement|
			    	if requirement.requirement_type.name==="photo_event_file_id"
			    		list+="<li>Speaker Photo</li>"
			    	else
			    		list+="<li>#{requirement.requirement_type.name.split('_').map(&:capitalize).join(' ')}</li>"
			    	end
			    end
			    @message=Message.new
			    @message.event_id=@event
			    @message.title="#{@message.event.name} Profile Reminder"
			    @message.content = "Your conference organizer has indicated some profile fields are mandatory for speakers. The following are missing from your profile:<br> <ul>#{list}</ul><br><br>Log into your Speaker Portal at <a href='#{root_url}'></a>"

		      if speaker.token.nil?
		        speaker.generate_token
		      end
			  MessageMailer.email_message(@message,speaker.email,speaker.token)
		    end
		end
  end


begin
	# connect to the MySQL server
	#dbh = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass,:database => @db_name)

		sendMail(28)

# 	end	


# rescue Mysql2::Error => e
# 	puts "Error code: #{e.errno}"
# 	puts "Error message: #{e.error}"
# 	puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
# ensure
# 	# disconnect from server
# 	dbh.close if dbh
end


