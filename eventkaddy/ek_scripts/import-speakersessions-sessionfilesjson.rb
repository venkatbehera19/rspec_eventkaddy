###########################################
#Ruby script to import session data from
#spreadsheet (ODS) into EventKaddy CMS
###########################################

require 'roo'
require 'mysql2'
require 'date'

require_relative './settings.rb' #config
require_relative './utility-functions.rb'


#for active record usage
require 'active_record'

#load the rails 3 environment
require_relative '../config/environment.rb'


ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

def makeJson(currentsession,session_files_url,session_files_title,session_files_type,event_id)
	hash = currentsession.session_file_urls
	if !(hash.blank?)
		hash = JSON.parse(hash)
	else
		hash = JSON.parse("[]")
	end

	session_files_url.each_with_index do |url, i|
		url.gsub!(/\s/,'_')
		puts "--- url: #{url} ---"
		hash.reject! {|x| x["url"]==="/event_data/#{event_id}/session_files/#{url}"}
		hash << {"title"=>"#{session_files_title[i]}","url"=>"/event_data/#{event_id}/session_files/#{url}","type"=>"#{session_files_type[i]}"}

		#make session_file and session_file_version
		event_files = EventFile.where(event_id:event_id,path:"/event_data/#{event_id}/session_files/#{url}")
		if event_files.length > 0
			puts "--- updating session_file_version and session_file ---"
			event_file   = event_files.first
			session_file = event_file.session_file_version.session_file

			event_file.update!(mime_type:session_files_type[i])
			session_file.update!(title:session_files_title[i])
		elsif event_files.length===0
			puts "--- creating session file, sessionfile version and placeholder event file"

			session_file                         = SessionFile.new()
			session_file.title                   = session_files_title[i]
			session_file.session_file_type_id    = SessionFileType.where(name:"Conference Note").first.id
			session_file.description             = "Primary Conference Note"
			session_file.event_id                = event_id
			session_file.session_id              = currentsession.id
			session_file.save()

			event_file                           = EventFile.new()
			event_file.name                      = url
			event_file.path                      = "/event_data/#{event_id}/session_files/#{url}"
			event_file.mime_type                 = session_files_type[i]
			event_file.event_id                  = event_id
			event_file.save()

			session_file_version                 = SessionFileVersion.new()
			session_file_version.event_id        = event_id
			session_file_version.session_file_id = session_file.id
			session_file_version.event_file_id   = event_file.id
			session_file_version.final_version   = 0
			session_file_version.save!(:validate => false)

		else
			puts "---ERROR duplicate event files, #{event_files.inspect} ---"
		end

	end
	puts "--- adding #{hash} to session_file_urls ---"
	currentsession.update!(:session_file_urls => hash.to_json)

end

#setup variables
event_id         = ARGV[0] #1, 2, 3, etc
spreadsheet_file = ARGV[1] #session-data.ods, bobs-sessions.ods, etc


colLetter = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']


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

	#remove existing session, speaker, and session/audience tagging data
	#@sessions = Session.where(event_id:event_id)
	#@sessions.destroy_all

	#@session_tags = Tag.where('event_id=? AND tag_types.name=?',event_id,'session').joins('
	#		LEFT JOIN tag_types ON tag_types.id=tags.tag_type_id
	#		').destroy_all

	#@audience_tags = Tag.where('event_id=? AND tag_types.name=?',event_id,'session-audience').joins('
	#		LEFT JOIN tag_types ON tag_types.id=tags.tag_type_id
	#		').destroy_all

	#@speakers = Speaker.where(event_id:event_id)
  	#@speakers.destroy_all


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
					fieldcount += 1
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
			if (is_number(colvals[0])) then
				session_code = colvals[0].to_i.to_s
			else
				session_code = colvals[0]
			end

			#puts "session code: #{session_code}"

			session_title       = colvals[1]
			session_date        = colvals[2]
			session_start_at    = Time.at(colvals[3].to_i).gmtime.strftime('%R:%S')
			session_end_at      = Time.at(colvals[4].to_i).gmtime.strftime('%R:%S')
			room_name           = colvals[5]
			session_description = colvals[6]

			#split out the session tagsets
			session_tags = addslashes(colvals[7]).split('||').map { |a| a.strip }
			session_tags.each_with_index do |item,i|
				session_tags[i] = addslashes(item).split(';').map { |a| a.strip }
			end

			session_track_subtrack = colvals[7]


			#record_type           = colvals[9]
			speaker_honor_prefix   = colvals[8]
			speaker_first_name     = colvals[9]
			speaker_last_name      = colvals[10]
			speaker_honor_suffix   = colvals[11]
			speaker_biography      = colvals[12]
			speaker_photo_filename = colvals[13]
			# speaker_title        = colvals[14] #currently empty??
			#speaker_type          = colvals[16]
			speaker_company        = colvals[14]
			speaker_email          = colvals[15]
			# speaker_type         = colvals[17]

			# if (speaker_type == "Speaker") then
			# 	speaker_type = "Primary Presenter"
			# end

			# if !(speaker_type == "") then
			 	# speaker_type_id = SpeakerType.where(speaker_type:speaker_type).first.id
			# else
			# 	speaker_type_id = nil
			# end

			#puts speaker_type


			#additional session columns
			# price = colvals[18]

			# if (is_number(colvals[18])) then
			# 	capacity = colvals[18].to_i.to_s
			# else
			# 	capacity = colvals[18]
			# end

			credit_hours = sprintf("%.2f",colvals[16].to_f)
			#puts "credit hours: #{credit_hours}"
			program_type = colvals[17]
			if !(program_type == "") then
			 	program_type_id = ProgramType.where(name:program_type).first.id
			else
				program_type_id = nil
			end

			#split out the session-audience tagsets
			# audience_tags = addslashes(colvals[21]).split(',').map { |a| a.strip }
			# audience_tags.each_with_index do |item,i|
			# 	audience_tags[i] = addslashes(item).split(':').map { |a| a.strip }
			# end

			session_sponsors = colvals[18].split('##').map { |a| a.strip } #comma separated list of company names
			speaker_id       = colvals[19] #what is this for, speaker might not exist yet
			survey_url       = colvals[20]
			polling_url      = colvals[21]

			####### JSON STUFF ########
			if colvals[22] != nil then
				session_files_url = colvals[22].split(',').map { |a| a.strip }
				if colvals[23] != nil then
					session_files_title = colvals[23].split(',').map { |a| a.strip }
				end
				if colvals[24] != nil then
					session_files_type = colvals[24].split(',').map { |a| a.strip }
				end
			else
				session_files_url   = ""
				session_files_title = ""
				session_files_type  = ""
			end

			session_attrs = {event_id:event_id,session_code:session_code,title:session_title,description:session_description,
				date:session_date,start_at:session_start_at,end_at:session_end_at,credit_hours:credit_hours,
				track_subtrack:session_track_subtrack,program_type_id:program_type_id,survey_url:survey_url,poll_url:polling_url}#,session_file_urls:jsonstring }

			speaker_attrs = {event_id:event_id,first_name:speaker_first_name,last_name:speaker_last_name,honor_prefix:speaker_honor_prefix,
				honor_suffix:speaker_honor_suffix,company:speaker_company,biography:speaker_biography,photo_filename:speaker_photo_filename,
				email:speaker_email }

			location_mapping_type  = LocationMappingType.where(type_name:'Room')[0]
			location_mapping_attrs = {event_id:event_id,name:room_name,mapping_type:location_mapping_type.id }


			#-- add/update session --

			sessions = Session.where(session_code:session_code,event_id:event_id)
			if (sessions.length==0) then
				session = Session.new(session_attrs)
				session.save()
				if session_files_url!=""
					makeJson(session,session_files_url,session_files_title,session_files_type,event_id)
				end
			elsif (sessions.length==1) then
				session = sessions[0]
				session.update!(session_attrs)
				if session_files_url!=""
					makeJson(session,session_files_url,session_files_title,session_files_type,event_id)
				end
			end

			#set session program_type
			program_type = ProgramType.where(name:program_type)
			if (program_type.length==1) then
				session.program_type_id = program_type.first.id
			else
				session.program_type_id = 1
			end

			session.save()

			#add/update location mapping
			location_mappings = LocationMapping.where(name:room_name,event_id:event_id)
			if (location_mappings.length==0) then
				location_mapping = LocationMapping.new(location_mapping_attrs)
			else
				location_mapping = location_mappings[0]
				location_mapping.update!(location_mapping_attrs)
			end
			location_mapping.save()

			session.location_mapping = location_mapping

			session.save()


			### add session tags ###
			rows        = dbh.query("SELECT id FROM `tag_types` WHERE name=\"session\";")
			tag_type_id = rows.first['id']

			addSessionTags(dbh,event_id,session_tags,tag_type_id,session_code)

			### add session-audience tags ###
			# rows=dbh.query("SELECT id FROM `tag_types` WHERE name=\"session-audience\";")
			# tag_type_id=rows.first['id']

			# addSessionTags(dbh,event_id,audience_tags,tag_type_id,session_code)


			#-- add speaker --
			if (speaker_first_name!='' && speaker_last_name!='') then

				puts "adding/updating speaker: #{speaker_attrs}"

				speakers = Speaker.where(first_name:speaker_first_name,last_name:speaker_last_name,event_id:event_id)

				if (speakers.length==0) then
					puts "creating speaker"
					speaker = Speaker.new(speaker_attrs)
				else
					puts "updating speaker"
					speaker = speakers[0]
					speaker.update!(speaker_attrs)
				end

				#create
				if (speaker_photo_filename!='') then
					speaker.createPhotoPlaceholder()
				end

				speaker.save()

				#add session-speaker relationship
				sessions_speaker = SessionsSpeaker.where(session_id:session.id,speaker_id:speaker.id).first_or_initialize()
				# sessions_speaker.update!(speaker_type_id:speaker_type_id)
				sessions_speaker.save()

			end

			#add session-sponsor relationship
			session_sponsors.each do |sponsor_name|

				exhibitor_attrs = { event_id:event_id,company_name:sponsor_name,is_sponsor:1 }

				#exhibitor = Exhibitor.where(event_id:event_id, company_name:sponsor_name).first_or_initialize(exhibitor_attrs)
				exhibitor = Exhibitor.where(event_id:event_id, company_name:sponsor_name).first_or_initialize
				exhibitor.update!(exhibitor_attrs)
				exhibitor.save()

				session_sponsor = SessionsSponsor.where(session_id:session.id,sponsor_id:exhibitor.id).first_or_initialize()
				session_sponsor.save()

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








