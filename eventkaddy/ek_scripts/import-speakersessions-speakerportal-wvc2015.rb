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
			if (is_number(colvals[0])) then
				session_code = colvals[0].to_i.to_s
			else
				session_code = colvals[0]
			end
			speaker_honor_prefix = colvals[1]
			speaker_last_name    = colvals[2]
			speaker_first_name   = colvals[3]
			middle_initial       = colvals[4]
			speaker_honor_suffix = colvals[5] + ' ' + colvals[6]

			speaker_type_id = SpeakerType.where(speaker_type:"Primary Presenter").first.id
			#session_group    = colvals[7]
			speaker_email     = colvals[9]

			program_type      = colvals[12]

			ce_hours          = colvals[14]
			race_approved     = colvals[15]


			program_area     = colvals[8] #first level tag
			program_category = colvals[10]	#second level tag
			additional_tag   = colvals[11] #another second level tag
			program_level    = colvals[13] #audience tag



			# if ProgramType.where(name:program_type).length > 0
			# 	program_type = ProgramType.where(name:program_type).id
			# else
			# 	program_type = ""
			# end

			session_title        = colvals[16]
			session_description  = colvals[17]
			session_date         = colvals[18]
			facility             = colvals[19] #event_map
			room_name            = colvals[20]

			session_start_at     = Time.at(colvals[21].to_i).gmtime.strftime('%R:%S')
			session_end_at       = Time.at(colvals[22].to_i).gmtime.strftime('%R:%S')

			if (is_number(colvals[23])) then
				capacity = colvals[23].to_i.to_s
			else
				capacity = colvals[23]
			end

			price            = colvals[24]
			# price_two      = colvals[25]
			session_sponsors = colvals[26].split('##').map { |a| a.strip } #comma separated list of company names
			room_set         = colvals[27]
			#split out av requirements
			av               = addslashes(colvals[28]).split(',').map { |a| a.strip }
			av_notes         = colvals[29]
			trackowner       = colvals[30].split(' ')
			trackowner_first_name = trackowner[0]
			trackowner_last_name = trackowner[1]

			trackowner_email = colvals[31]

			audience_tags    = []
			audience_tags    << []
			audience_tags[0] << program_level


			#split out the session tagsets
			session_tags = []
			session_tags << []
			session_tags << []
			session_tags[0] << program_area
			session_tags[0] << program_category
			if additional_tag != ''
				session_tags[1] << program_area
				session_tags[1] << additional_tag
			end


			# #split out the session tagsets
			# session_tags = addslashes(colvals[7]).split(',').map { |a| a.strip }
			# session_tags.each_with_index do |item,i|
			# 	session_tags[i] = addslashes(item).split(':').map { |a| a.strip }
			# end

			# session_track_subtrack = colvals[7]



			# credit_hours = sprintf("%.2f",colvals[20].to_f)
			# #puts "credit hours: #{credit_hours}"
			# program_type = colvals[21]

			# #split out the session-audience tagsets
			# audience_tags = addslashes(colvals[22]).split(',').map { |a| a.strip }
			# audience_tags.each_with_index do |item,i|
			# 	audience_tags[i] = addslashes(item).split(':').map { |a| a.strip }
			# end



			#video_iphone = colvals[22]
			#speaker_role = colvals[22] #what am I expecting in this field?

			puts "session title: #{session_title}\n"

			session_attrs = {event_id:event_id,session_code:session_code,title:session_title,description:session_description,
				date:session_date,start_at:session_start_at,end_at:session_end_at,credit_hours:ce_hours,capacity:capacity,
				price:price,race_approved:race_approved}#,program_type_id:program_type}

			speaker_attrs = {event_id:event_id,first_name:speaker_first_name,last_name:speaker_last_name,honor_prefix:speaker_honor_prefix,
				honor_suffix:speaker_honor_suffix,email:speaker_email,speaker_type_id:speaker_type_id}

			trackowner_attrs = {event_id:event_id,first_name:trackowner_first_name,last_name:trackowner_last_name,email:trackowner_email}

			location_mapping_type  = LocationMappingType.where(type_name:'Room')[0]
			location_mapping_attrs = {event_id:event_id,name:room_name,mapping_type:location_mapping_type.id }
			map_type_id            = MapType.where(map_type:"Session Map").first.id
			event_map_attrs        = {event_id:event_id,name:facility,map_type_id:map_type_id}


			#-- add/update session --

			sessions = Session.where(session_code:session_code,event_id:event_id)
			if (sessions.length==0) then
				session = Session.new(session_attrs)
			elsif (sessions.length==1) then
				session = sessions[0]
				session.update!(session_attrs)
			end

			#set session program_type
			program_type = ProgramType.where(name:program_type)
			if (program_type.length==1) then
				session.program_type_id = program_type.first.id
			else
				session.program_type_id = 1
			end

			session.save()

			#add facility / event map
			event_maps = EventMap.where(name:facility,event_id:event_id)
			#add/update event map
			if (event_maps.length==0) then
				event_map = EventMap.new(event_map_attrs)
			else
				event_map = event_maps[0]
				event_map.update!(event_map_attrs)
			end
			event_map.save()


			#add/update location mapping
			location_mappings = LocationMapping.where(name:room_name,event_id:event_id)
			if (location_mappings.length==0) then
				location_mapping = LocationMapping.new(location_mapping_attrs)
			else
				location_mapping = location_mappings[0]
				location_mapping.update!(location_mapping_attrs)
			end
			# if event_map
				location_mapping.map_id = event_map.id
			# end
			location_mapping.save()

			session.location_mapping = location_mapping

			session.save()




			### add session tags ###
			rows=dbh.query("SELECT id FROM `tag_types` WHERE name=\"session\";")
			tag_type_id=rows.first['id']

			addSessionTags(dbh,event_id,session_tags,tag_type_id,session_code)

			### add session-audience tags ###
			rows=dbh.query("SELECT id FROM `tag_types` WHERE name=\"session-audience\";")
			tag_type_id=rows.first['id']

			addSessionTags(dbh,event_id,audience_tags,tag_type_id,session_code)


			#-- add speaker --
			if (speaker_first_name!='' && speaker_last_name!='' && speaker_first_name != 'TBA') then

				puts "adding/updating speaker: #{speaker_attrs}"

				speakers = Speaker.where(email:speaker_email,event_id:event_id)

				if (speakers.length==0) then
					puts "creating speaker"
					speaker = Speaker.new(speaker_attrs)
				else
					puts "updating speaker"
					speaker = speakers[0]
					speaker.update!(speaker_attrs)
				end

				#create
				# if (speaker_photo_filename!='') then
				# 	speaker.createPhotoPlaceholder()
				# end

				speaker.save()

				#add session-speaker relationship
				sessions_speaker = SessionsSpeaker.where(session_id:session.id,speaker_id:speaker.id).first_or_initialize()
				sessions_speaker.update!(speaker_type_id:speaker_type_id)
				sessions_speaker.save()

				#add AV equipment and notes

				av_attrs = {session_id:session.id,speaker_id:speaker.id,event_id:event_id,additional_notes:av_notes}
				av.each do |a|
					type_id = AvListItem.where(name:a)
					if type_id.length === 0
						type_id = AvListItem.new(name:a)
						type_id.save
						type_id = type_id.id
					else
						type_id = type_id.first.id
					end

					session_av_requirements = SessionAvRequirement.where(session_id:session.id,speaker_id:speaker.id,event_id:event_id,av_list_item_id:type_id)
					if session_av_requirements.length < 1
						session_av_requirement = SessionAvRequirement.new(av_attrs)
						session_av_requirement.av_list_item_id = type_id
						session_av_requirement.save
					end
				end

			end#add speaker

			trackowner_role = Role.where(name:"TrackOwner").first.id

			#-- add trackowner --
			if (trackowner_email!='') then

				puts "adding/updating trackowner: #{trackowner_attrs}"

				trackowners = Trackowner.where(email:trackowner_email,event_id:event_id)

				if (trackowners.length==0) then
					puts "creating trackowner"
					trackowner = Trackowner.new(trackowner_attrs)
				else
					puts "updating trackowner"
					trackowner = trackowners[0]
					trackowner.update!(trackowner_attrs)
				end

				#create
				# if (trackowner_photo_filename!='') then
				# 	trackowner.createPhotoPlaceholder()
				# end

				trackowner.save()

		  		#add user account, if email address isn't in use by another user
				users = User.where(email:trackowner_email)
				if (users.length==0) then
					user          = User.new
					user.email    = trackowner_email
					user.password = 'ekchangeme'
	  				user.save()
	  				puts "user id: #{user.id}"
	  			else
	  				puts "user already exists with email address: #{trackowner_email}"
	  				user = users.first
	  			end

	  			user_roles = UsersRole.where(role_id:trackowner_role,user_id:user.id)

	  			if user_roles.length == 0
	  				user_role         = UsersRole.new()

					user_role.role_id = trackowner_role
					user_role.user_id = user.id
	  				user_role.save()
	  			end

				users_event = UsersEvent.where(user_id:user.id,event_id:event_id).first_or_initialize
				users_event.save()

	  			trackowner.update!(user_id:user.id)

				#add session-trackowner relationship
				sessions_trackowner = SessionsTrackowner.where(session_id:session.id,trackowner_id:trackowner.id).first_or_initialize()
				sessions_trackowner.save()

			end#add trackowner

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








