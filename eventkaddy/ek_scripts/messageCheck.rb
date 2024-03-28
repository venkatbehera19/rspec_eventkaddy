# ###########################################
# #Ruby script to import session data from
# #spreadsheet (ODS) into EventKaddy CMS
# ###########################################

# require 'rubygems'
# require 'mysql2'
# require 'date'
# require 'time'

# require_relative './settings.rb' #config

# #for active record usage
# require 'active_record'

# #load the rails 3 environment
# require_relative '../config/environment.rb'


# ActiveRecord::Base.establish_connection(
# 	:adapter => "mysql2",
# 	:host => @db_host,
# 	:username => @db_user,
# 	:password => @db_pass,
# 	:database => @db_name
# )

# #from PHP land
# def addslashes(str)
#   str.gsub(/['"\\\x0]/,'\\\\\0').gsub(/\r\n/, "\n").gsub(/\n/, " ")
# end

#   def sendMail(message_id)
#   	  @message = Message.where(id:message_id).first
#   	  @event=@message.event_id

#       if @message.message_type==1 then
#         Speaker.where(event_id:@event,unsubscribed:[0,nil]).each do |speaker|
#           if speaker.token.nil?
#             speaker.generate_token
#             speaker.save
#           end
# 		MessageMailer.email_message(@message,speaker.email,speaker.token)
#         end
#       elsif @message.message_type==2 then
#         Exhibitor.where(event_id:@event,unsubscribed:[0,nil]).each do |exhibitor|
#           if exhibitor.token.nil?
#             exhibitor.generate_token
#             exhibitor.save
#           end
#           MessageMailer.email_message(@message,exhibitor.email,exhibitor.token)
#         end
#       elsif @message.message_type==3 then
#         Speaker.where(event_id:@event,unsubscribed:[0,nil]).each do |speaker|
#           if speaker.token.nil?
#             speaker.generate_token
#             speaker.save
#           end
#           MessageMailer.email_message(@message,speaker.email,speaker.token)
#         end
#         Exhibitor.where(event_id:@event,unsubscribed:[0,nil]).each do |exhibitor|
#           if exhibitor.token.nil?
#             exhibitor.generate_token
#             exhibitor.save
#           end
#           MessageMailer.email_message(@message,exhibitor.email,exhibitor.token)
#         end
#       end#if type

#   end


# begin
# 	# connect to the MySQL server
# 	dbh = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass,:database => @db_name)


# 	rows=dbh.query("SELECT messages.id AS n_id,status,active_time,messages.event_id,events.utc_offset AS utc_offset, messages.content AS n_content
# 	 FROM `messages` JOIN events ON events.id=messages.event_id WHERE status=\"pending\";").to_a

# 	rows.each do |row|
# 		ctime = Time.now.utc
# 		atime = "#{row['active_time'].strftime('%Y-%m-%d %H:%M:%S')}Z"
# #		atime = "#{row['active_time']}Z"
# 		atime = Time.parse(atime)
# 		puts "ctime: #{ctime}"
# 		puts "atime: #{atime}"

# 		if (atime <= ctime) then
# 			puts "message id #{row['n_id']} set to active"
# 			result = dbh.query("UPDATE messages SET status=\"active\" WHERE id=\"#{row['n_id']}\";")
# 			sendMail(row['n_id'])
# 		else
# 			puts "message id #{row['n_id']} still pending"
# 		end

# 	end


# rescue Mysql2::Error => e
# 	puts "Error code: #{e.errno}"
# 	puts "Error message: #{e.error}"
# 	puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
# ensure
# 	# disconnect from server
# 	dbh.close if dbh
# end


