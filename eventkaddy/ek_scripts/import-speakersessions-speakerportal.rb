###########################################
#Ruby script to import speaker session data from
#spreadsheet (ODS) into EventKaddy CMS,
#to be used for the speaker portal
###########################################

require 'roo'
require 'mysql2'
require 'date'
require 'devise'

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
			program_area = colvals[10].gsub(/[:,]/,'-')
			program_category = colvals[12].gsub(/[:,]/,'-')
			presentation_type = colvals[13].gsub(/[:,]/,'-')
			audience_type = colvals[14]
			session_track_subtrack = "#{program_area}/#{program_category}/#{presentation_type}"

			session_code = colvals[1]
			session_title = colvals[18]
			session_description = colvals[19]

			speaker_email = colvals[11]
			speaker_role = colvals[8]

			#split out the session tagsets
			wvc_session_tag = "#{program_area}:#{program_category}"
			session_tags = addslashes(wvc_session_tag).split(',').map { |a| a.strip }
			session_tags.each_with_index do |item,i|
				session_tags[i] = addslashes(item).split(':').map { |a| a.strip }
			end


			### ADD SESSION ###

			session_hash = {event_id:event_id,session_code:session_code,title:session_title,
				description:session_description,track_subtrack:session_track_subtrack}

			sessions = Session.where(session_code:session_code,event_id:event_id)

			if (sessions.length == 0) then

				puts "-- creating session: #{session_code} --\n"
				session = Session.new(session_hash)
				session.save()
			elsif (sessions.length == 1)

				puts "---- updating session: #{session_code} ----\n"
				session = sessions[0]
				session.update!(session_hash)
			else
				puts "--- ERROR: potential duplicate session code: #{session_code}"
				next
			end

			### add session tags ###
			tag_type_id = TagType.where(name:"session").first.id
			addSessionTags(dbh,event_id,session_tags,tag_type_id,session_code)


			### ADD SPEAKER-SESSION ASSOCIATION ###
			puts "speaker email: #{speaker_email}"
			rows = Speaker.where(email:speaker_email,event_id:event_id)

			if (rows.length == 1) then
				speaker = rows[0]
			else
				puts "skipping speaker-session linking, invalid email address"
				next #skip all rows without a valid speaker
			end

			#get speaker role
			speaker_role = SpeakerType.where(speaker_type:speaker_role)
			if (speaker_role.length >0) then
				speaker_role_id = speaker_role[0].id
			else
				speaker_role_id = 1
			end

			sessions_speaker_hash = {session_id:session.id,speaker_id:speaker.id,speaker_type_id:speaker_role_id}
			rows = SessionsSpeaker.where(sessions_speaker_hash)

			if (rows.length == 0) then

				puts "-- creating association between session: #{session_code} and #{speaker.email} --\n"
				sessions_speaker = SessionsSpeaker.new(sessions_speaker_hash)
				sessions_speaker.save()
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








