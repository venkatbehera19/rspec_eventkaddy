###########################################
#Ruby script to import speaker data from
#spreadsheet (ODS) into EventKaddy CMS,
#to be used for the speaker portal
###########################################

require 'roo'
require 'mysql2'
require 'date'

require_relative './settings.rb' #config
require_relative './utility-functions.rb'

#for active record usage
require 'active_record'
require '../config/environment.rb' #load the rails 3 environment

ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)


#setup variables
event_id = ARGV[0] #1, 2, 3, etc
spreadsheet_file = ARGV[1] #session-data.ods, bobs-sessions.ods, etc


colLetter=['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']


# INPUT SPREADSHEET DATA
begin

	# connect to the MySQL server
	dbh = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass,:database => @db_name)

	#open the spreadsheet
	if ( spreadsheet_file.match(/.xls/) || spreadsheet_file.match(/.xlsx/) )
		oo = Roo::Excel.new(spreadsheet_file)

	elsif ( spreadsheet_file.match(/.ods/) )
		oo = Roo::Openoffice.new(spreadsheet_file)

	else
		puts "Spreadsheet format not supported"
		exit
	end


	#process all the sheets
	oo.sheets.each do |sheet|

		puts "--------- Processing sheet: #{sheet} ------------\n"
		oo.default_sheet = sheet

		#get field names from first row
		fields = []
		fieldcount=0
		1.upto(1) do |row|
			colLetter.each do |col|

				if (oo.cell(row,col)!=nil) then
					fields[fieldcount]=oo.cell(row,col)
					#puts fields[fieldcount] + "\n"
					fieldcount+=1
				end

			end #col
		end #row

		puts fields.inspect + "\n"

		#get records on sheet
		colvals=[]
		2.upto(oo.last_row) do |row|

			t = Time.now

			#collect all the column values for the row
			0.upto(fieldcount-1) do |colnum|

				#collect value, if any
				if (oo.cell(row,colLetter[colnum])==nil) then
					colvals[colnum]=''
				else
					colvals[colnum] =oo.cell(row,colLetter[colnum])
				end

			end #col

			#column mappings
			speaker_code = colvals[0]
			speaker_honor_prefix = colvals[1]
			speaker_first_name = colvals[2]
			speaker_middle_initial = colvals[3]
			speaker_last_name = colvals[4]
			speaker_honor_suffix = colvals[5]

			if (colvals[6].match(';')) then
				speaker_email= colvals[6].gsub!(/^(.*);(.*)/,'\\1')
			else
				speaker_email = colvals[6]
			end

			if ( speaker_email=='' or speaker_email==nil or ! /^\S+@\S+\.\S+$/.match(speaker_email) ) then
				speaker_email = ''+speaker_first_name+''+speaker_last_name+' email unavailable'
				#puts "RECORD ERROR: Missing speaker email, skipping record"
				#next
			end

			puts "speaker email: #{speaker_email} | #{speaker_last_name}"
			#speaker_notes= colvals[7]
			speaker_ssnum = colvals[7]
			speaker_pay_to_line1 = colvals[8]
			speaker_pay_to_line2 = colvals[9]
			speaker_city_state = colvals[10]
			speaker_approved_arrival_date = colvals[11]
			speaker_approved_departure_date = colvals[12]
			speaker_actual_arrival_date = colvals[13]
			speaker_actual_departure_date = colvals[14]
			speaker_hotel_name = colvals[15]
			speaker_hotel_confirmation_num = colvals[16]
			speaker_hotel_cost = colvals[17]
			speaker_hotel_reimbursement = colvals[18]
			speaker_airfare_cost = colvals[19]
			speaker_airfare_reimbursement = colvals[20]
			speaker_mileage = colvals[21]
			speaker_comments = colvals[22]
			speaker_title = colvals[23]
			speaker_company= colvals[24]
			speaker_address1= colvals[25]
			speaker_address2= colvals[26]
			speaker_address3= colvals[27]
			speaker_city=colvals[28]
			speaker_state=colvals[29]
			speaker_zip= colvals[30]
			speaker_country= colvals[31]
			speaker_work_phone= colvals[32]
			speaker_fax= colvals[33]
			speaker_mobile_phone= colvals[34]
			speaker_home_phone= colvals[35]
			speaker_vip_code=colvals[36]
			speaker_direct_bill_travel=colvals[37]
			speaker_direct_bill_housing=colvals[38]
			speaker_eligible_housing_nights=colvals[39]
			speaker_payment_type=colvals[40]
			speaker_eligible_payment_rate=colvals[41]
			speaker_total_honorarium=colvals[42]
			speaker_total_per_diem=colvals[43]
			speaker_bio= colvals[44]

			#speaker_photo_filename = nil


			### ADD SPEAKER ###

			speaker_attrs = {event_id:event_id,honor_prefix:speaker_honor_prefix,first_name:speaker_first_name,last_name:speaker_last_name,honor_suffix:speaker_honor_suffix,email:speaker_email,company:speaker_company,address1:speaker_address1,address2:speaker_address2,address3:speaker_address3,city:speaker_city,state:speaker_state,zip:speaker_zip,country:speaker_country,work_phone:speaker_work_phone,fax:speaker_fax,mobile_phone:speaker_mobile_phone,home_phone:speaker_home_phone,biography:speaker_bio }#,photo_filename:speaker_photo_filename }



			result = Speaker.where(email:speaker_email,event_id:event_id)
			role = Role.where(name:"Speaker").first

  		#add user account, if email address isn't in use by another user
			users = User.where(email:speaker_email)
			if (users.length==0) then
  				user = User.new
  				user.email = speaker_email
  				user.password = 'ekchangeme'
  				user.save()
  				puts "user id: #{user.id}"

  				user_role = UsersRole.new()
  				user_role.role_id=role.id
  				user_role.user_id=user.id
  				user_role.save()
  			else
  				puts "user already exists with email address: #{speaker_email}"
  				user = users.first
  			end


			if (result.length == 0 && speaker_email!=''+speaker_first_name+''+speaker_last_name+' email unavailable') then
				puts "\t\t-- creating new speaker: #{speaker_email} | #{speaker_first_name} #{speaker_last_name} --\n"
				speaker = Speaker.new(speaker_attrs)
				speaker.save()


 			elsif (result.length == 1 && speaker_email!=''+speaker_first_name+''+speaker_last_name+' email unavailable') then
				puts "\t\t-- updating speaker: #{speaker_email} | #{speaker_first_name} #{speaker_last_name} --\n"

 				speaker = result[0]
				speaker.update!(speaker_attrs)

			elsif (result.length > 1) then
				puts "ERROR -------------- DUPLICATE EMAIL ADDRESS -------------- ERROR"
				next

			elsif (result.length == 0 && speaker_email==''+speaker_first_name+''+speaker_last_name+' email unavailable') then
				puts "\t\t-- creating new speaker without useraccount: #{speaker_email} | #{speaker_first_name} #{speaker_last_name} --\n"

				speaker = Speaker.new(speaker_attrs)
				speaker.save()

			elsif (result.length == 1 && speaker_email==''+speaker_first_name+''+speaker_last_name+' email unavailable') then
				puts "\t\t-- updating speaker without useraccount: #{speaker_email} | #{speaker_first_name} #{speaker_last_name} --\n"

 				speaker = result[0]
				speaker.update!(speaker_attrs)
			end

			travel_attrs = {speaker_id:speaker.id,approved_arrival_date:speaker_approved_arrival_date,approved_departure_date:speaker_approved_departure_date,actual_arrival_date:speaker_actual_arrival_date,actual_departure_date:speaker_actual_departure_date,hotel_name:speaker_hotel_name,hotel_confirmation_number:speaker_hotel_confirmation_num,hotel_cost:speaker_hotel_cost,hotel_reimbursement:speaker_hotel_reimbursement,airfare_cost:speaker_airfare_cost,airfare_reimbursement:speaker_airfare_reimbursement,mileage:speaker_mileage,comments:speaker_comments }

			payment_attrs = { speaker_id:speaker.id,social_security_number:speaker_ssnum,pay_to_line1:speaker_pay_to_line1,
				pay_to_line2:speaker_pay_to_line2,direct_bill_travel:speaker_direct_bill_travel,direct_bill_housing:speaker_direct_bill_housing,
				eligible_housing_nights:speaker_eligible_housing_nights,payment_type:speaker_payment_type,eligible_payment_rate:speaker_eligible_payment_rate,
				total_honorarium:speaker_total_honorarium,total_per_diem:speaker_total_per_diem, vip_code:speaker_vip_code }

  			#add travel details row for speaker, if none exists
  			speaker_travel_details = SpeakerTravelDetail.where(speaker_id:speaker.id)
			if (speaker_travel_details.length==0) then
  				speaker_travel_detail = SpeakerTravelDetail.new(travel_attrs)
  				speaker_travel_detail.save()
  				puts "speaker id travel detail: #{speaker_travel_detail.speaker_id} created"
  			elsif (speaker_travel_details.length==1) then
  				speaker_travel_detail = speaker_travel_details[0]
				speaker_travel_detail.update!(travel_attrs)
  				puts "speaker id travel detail: #{speaker_travel_detail.speaker_id} updated"
  			end

  			#add speaker payment details row if none exists
  			speaker_payment_details = SpeakerPaymentDetail.where(speaker_id:speaker.id)
			if (speaker_payment_details.length==0) then
  				speaker_payment_detail = SpeakerPaymentDetail.new(payment_attrs)
  				speaker_payment_detail.save()
  				puts "speaker id payment detail: #{speaker_payment_detail.speaker_id} created"
  			elsif (speaker_payment_details.length==1) then
  				#puts payment_attrs.inspect
  				speaker_payment_detail = speaker_payment_details[0]
  				speaker_payment_detail.update!(payment_attrs)
  				#puts speaker_payment_detail.inspect
  				puts "speaker id payment detail: #{speaker_payment_detail.speaker_id} updated"
  			end

			if user then
			#associate user (speaker) and the event
			user = User.where(email:speaker_email).first
			users_event = UsersEvent.where(user_id:user.id,event_id:event_id).first_or_initialize
			users_event.save()
			end

		end #row

	end #sheet


rescue Mysql2::Error => e
	puts "Error code: #{e.errno}"
	puts "Error message: #{e.error}"
	puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
ensure
	# disconnect from server
	dbh.close if dbh
end








