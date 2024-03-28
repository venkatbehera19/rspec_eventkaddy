class Message < ApplicationRecord

  belongs_to :event

  validates :message_type, presence: true

	# def email(event_id)
	# 	if (self.status=="active") then
	# 		if self.message_type==1 then
	# 			Speaker.where(event_id:event_id,unsubscribed:[0,nil]).each do |speaker|
	# 			    if speaker.token.nil?
	# 				    speaker.generate_token
	# 				    speaker.save
	# 			    end
	# 				MessageMailer.email_message(self,speaker.email,speaker.token)
	# 			end
	# 		elsif self.message_type==2 then
	# 			Exhibitor.where(event_id:event_id,unsubscribed:[0,nil]).each do |exhibitor|
	# 				if exhibitor.token.nil?
	# 					exhibitor.generate_token
	# 					exhibitor.save
	# 				end
	# 				MessageMailer.email_message(self,exhibitor.email,exhibitor.token)
	# 			end
	# 		elsif self.message_type==3 then
	# 			Speaker.where(event_id:event_id,unsubscribed:[0,nil]).each do |speaker|
	# 				if speaker.token.nil?
	# 					speaker.generate_token
	# 					speaker.save
	# 				end
	# 				MessageMailer.email_message(self,speaker.email,speaker.token)
	# 			end
	# 			Exhibitor.where(event_id:event_id,unsubscribed:[0,nil]).each do |exhibitor|
	# 				if exhibitor.token.nil?
	# 					exhibitor.generate_token
	# 					exhibitor.save
	# 				end
	# 				MessageMailer.email_message(self,exhibitor.email,exhibitor.token)
	# 			end
	# 		end#if type
	# 	end#if active
	# end#email

	def self.time_zone_aware_attributes #turn off auto-time zone adjustments for entire model
  	false
 	end

	#determine whether to send notification in the future
	# def futureSendCheck(event)
	# 	if (self.active_time!=nil) then

	# 		#Rails::logger.debug "ACTIVE TIME: #{self.active_time}"

	# 		ctime = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
	# 		atime = "#{self.active_time.strftime('%Y-%m-%d %H:%M:%S')} #{event.utc_offset}"
	# 		atime = Time.parse(atime).utc.strftime('%Y-%m-%d %H:%M:%S')
	# 		#Rails::logger.debug "ATIME: #{atime}"
	# 		self.active_time = atime

	# 		#Rails::logger.debug "ATIME: #{atime}"
	# 		#Rails::logger.debug "CTIME: #{ctime}"

	# 		if ( Time.parse(atime) <= Time.parse(ctime) ) then
	# 			self.status="active"
	# 		else
	# 			self.status="pending"
	# 		end

	# 	else
	# 		self.status = "active"
	# 		self.active_time = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
	# 	end
	# end

	#calculate localtime
	# def setLocalTime(event)

	# 	t_offset = event.utc_offset
	# 	if (t_offset==nil) then
	# 		t_offset = "+00:00" #default to UTC 0
	# 	end

	# 	if (self.status=="active")
	# 		self.local_time = Time.now.localtime(t_offset).strftime('%Y-%m-%d %H:%M:%S')
	# 	elsif (self.status=="pending")
	# 		self.local_time = Time.parse("#{self.active_time.strftime('%Y-%m-%d %H:%M:%S')}Z").localtime(t_offset).strftime('%Y-%m-%d %H:%M:%S')
	# 	end
	# end

	#immediately send push notification
	# def sendUAPush(ua_ak,ua_ams)

	# 	#iOS urbanairship push notification
	# 	ua_app_key = ua_ak
	# 	ua_app_master_secret = ua_ams

	# 	#ios
	# 	ua_curl_cmd_ios = "
	# 	/usr/bin/curl -X POST -u \"#{ua_app_key}:#{ua_app_master_secret}\" \
	# 	-H \"Content-Type: application/json\" \
	# 	--data '{
	# 	    \"aps\": {
	# 	         \"badge\": \"1\",
	# 	         \"alert\": \"#{self.description}\",
	# 	         \"sound\": \"default\"
	# 	    }
	# 	}' \
	# 	https://go.urbanairship.com/api/push/broadcast/
	# 	"

	# 	puts "CURL CMD #{ua_curl_cmd_ios}"
	# 	curl_result = `ROO_TMP='/tmp' #{ua_curl_cmd_ios} 2>&1`
	# 	puts "\n--------- curl cmd output ---------\n\n #{curl_result} \n------------------- \n"

	# 	#android
	# 	ua_curl_cmd_android = "
	# 	/usr/bin/curl -X POST -u \"#{ua_app_key}:#{ua_app_master_secret}\" \
	# 	-H \"Content-Type: application/json\" \
	# 	--data '{
	# 		\"android\": {
	# 		\"alert\": \"#{self.description}\"
	# 		  }
	# 	}' \
	# 	https://go.urbanairship.com/api/push/broadcast/
	# 	"

	# 	puts "CURL CMD #{ua_curl_cmd_android}"
	# 	curl_result = `ROO_TMP='/tmp' #{ua_curl_cmd_android} 2>&1`
	# 	puts "\n--------- curl cmd output ---------\n\n #{curl_result} \n------------------- \n"

	# end

end
