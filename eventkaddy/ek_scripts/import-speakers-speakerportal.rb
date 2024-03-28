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
	if (spreadsheet_file.match(/.xlsx/))
		oo = Roo::Excelx.new(spreadsheet_file)

	elsif ( spreadsheet_file.match(/.xls/) )
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
		fields     = []
		fieldcount = 0
		1.upto(1) do |row|
			colLetter.each do |col|

				if (oo.cell(row,col)!=nil) then
					fields[fieldcount] = oo.cell(row,col)
					#puts fields[fieldcount] + "\n"
					fieldcount+=1
				end

			end #col
		end #row

		puts fields.inspect + "\n"

		#get records on sheet
		colvals = []
		2.upto(oo.last_row) do |row|

			t = Time.now

			#collect all the column values for the row
			0.upto(fieldcount-1) do |colnum|

				#collect value, if any
				if (oo.cell(row,colLetter[colnum])==nil) then
					colvals[colnum] = ''
				else
					colvals[colnum] = oo.cell(row,colLetter[colnum])
				end

			end #col

			#column mappings
			speaker_honor_prefix   = colvals[0]
			speaker_first_name     = colvals[1]
			speaker_middle_initial = colvals[2]
			speaker_last_name      = colvals[3]
			speaker_honor_suffix   = colvals[4] + '  ' + colvals[5]

			if (colvals[6].match(';')) then
				speaker_email= colvals[6].gsub!(/^(.*);(.*)/,'\\1')
			else
				speaker_email = colvals[6]
			end

			# if ( speaker_email=='' or speaker_email==nil or ! /^\S+@\S+\.\S+$/.match(speaker_email) ) then
			# 	puts "RECORD ERROR: Missing speaker email, skipping record"
			# 	next
			# end
			if ( speaker_email=='' || speaker_email=='tba' || speaker_email==nil || ! /^\S+@\S+\.\S+$/.match(speaker_email) ) then
				speaker_email = ''+speaker_first_name+''+speaker_last_name+' email unavailable'
				puts "RECORD ERROR: Missing speaker email, skipping record"
				next
			end

			puts "speaker email: #{speaker_email} | #{speaker_last_name}"
			#speaker_notes       = colvals[7]
			speaker_company      = colvals[7]
			speaker_address1     = colvals[8]
			speaker_address2     = colvals[9]
			speaker_address3     = colvals[10]
			speaker_city         = colvals[11]
			speaker_state        = colvals[12]
			speaker_country      = colvals[13]
			speaker_zip          = colvals[14]
			speaker_work_phone   = colvals[15]
			speaker_mobile_phone = colvals[16]
			speaker_home_phone   = colvals[17]
			speaker_fax          = colvals[18]
			speaker_bio          = colvals[19]

			# if (speaker_type == "Speaker") then
			# 	speaker_type = "Primary Presenter"
			# end

			# if !(speaker_type == "") then
			# 	speaker_type_id = SpeakerType.where(speaker_type:speaker_type).first.id
			# else
				speaker_type_id = SpeakerType.where(speaker_type:"Primary Presenter").first.id
			# end

			speaker_photo_filename = nil

			speaker_attrs = {event_id:event_id,honor_prefix:speaker_honor_prefix,first_name:speaker_first_name,last_name:speaker_last_name,honor_suffix:speaker_honor_suffix,email:speaker_email,company:speaker_company,address1:speaker_address1,address2:speaker_address2,address3:speaker_address3,city:speaker_city,state:speaker_state,zip:speaker_zip,country:speaker_country,work_phone:speaker_work_phone,fax:speaker_fax,mobile_phone:speaker_mobile_phone,home_phone:speaker_home_phone,biography:speaker_bio,speaker_type_id:speaker_type_id}#,photo_filename:speaker_photo_filename }


			### ADD SPEAKER ###

			result = Speaker.where(email:speaker_email,event_id:event_id)
			role = Role.where(name:"Speaker").first

  		#add user account, if email address isn't in use by another user
			users = User.where(email:speaker_email)
			if (users.length==0) then
				user          = User.new
				user.email    = speaker_email
				user.password = 'ekchangeme'
  				user.save()
  				puts "user id: #{user.id}"

				user_role         = UsersRole.new()
				user_role.role_id = role.id
				user_role.user_id = user.id
  				user_role.save()

				users_event = UsersEvent.where(user_id:user.id,event_id:event_id).first_or_initialize
				users_event.save()
  			else
  				puts "user already exists with email address: #{speaker_email}"
  				user = users.first

				users_event = UsersEvent.where(user_id:user.id,event_id:event_id).first_or_initialize
				users_event.save()
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








