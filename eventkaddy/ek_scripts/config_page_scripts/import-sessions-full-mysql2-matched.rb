###########################################
#Ruby script to import session data from
#spreadsheet (ODS) into EventKaddy CMS
###########################################

require 'roo'

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'
require_relative '../delta_report.rb'
require 'active_record'
require_relative '../../config/environment.rb'
require_relative '../modules/database_adjustment.rb'

ActiveRecord::Base.establish_connection(adapter:"mysql2", host:@db_host, username:@db_user, password:@db_pass, database:@db_name)

def makeJson(currentsession, filenames, titles, types, event_id)

	# session_file_urls = SessionFileUrlsEntity.new json:currentsession.session_file_urls
	puts "--------------------- All files-------------------------------------"
	p filenames
	filenames.each_with_index do |filename, i|
		filename.gsub!(/\s/,'_')
		puts "--- filename: #{filename} ---"
		if filename.length != 0
			# path = "/event_data/#{event_id}/session_files/#{filename}"

			# event_files = EventFile.where event_id:event_id, path:path

			event_files = EventFile.where event_id:event_id, name:filename

			if event_files.length == 1
				puts "--- updating session_file_version and session_file ---"
				event_file   = event_files.first
				session_file = event_file.session_file_version.session_file
				event_file.update! mime_type:types[i]
				session_file.update! title:titles[i]
				# session_file_urls.remove_by [{sf_id:session_file.id}]
				# session_file_urls.add [{"title" => titles[i], "url" => event_file.path, "type" => types[i], "sf_id" => session_file.id}]
			elsif event_files.length == 0
				path = "/event_data/#{event_id}/session_files/#{filename}"
				puts "--- creating session file, sessionfile version and placeholder event file"

				session_file = SessionFile.where(session_id:currentsession.id, title: titles[i],
					session_file_type_id:SESSION_FILE_TYPE_ID, description:"Primary Conference Note", event_id:event_id).first_or_create(unpublished: true)

				event_file = EventFile.where(name:filename, path:path, mime_type:types[i],
					event_id:event_id, event_file_type_id:SESSION_FILE_EVENT_FILE_TYPE_ID).first_or_create

				SessionFileVersion.new(event_id:event_id, session_file_id:session_file.id, event_file_id:event_file.id,
					final_version:0).save!(:validate => false)
				# session_file_urls.remove_by [{sf_id:session_file.id}]
				# session_file_urls.add [{"title" => titles[i], "url" => path, "type" => types[i], "sf_id" => session_file.id}]
			else
				puts "---ERROR duplicate event files, #{event_files.inspect} ---"
			end
		end
	end
	# puts "--- adding #{session_file_urls.inspect} to session_file_urls ---"
	# currentsession.update! session_file_urls: session_file_urls.json
  currentsession.update_session_file_urls_json
end

def generate_columns_error_log(nonexistant_columns, event_id)
	@error_log += "The following columns are incorrectly named:\n\n"

	nonexistant_columns.each {|c| @error_log += "\t" + c + "\n"}

	new_filename = "error_log.txt"
	filepath     = Rails.root.join('public','event_data', event_id.to_s,'error_logs',new_filename)
	dirname      = File.dirname(filepath)

	@error_log = "Refresh Error Report\n\nNumber of Errors: #{@error_count}\n\n\n\n\n" + @error_log

	FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

	File.open(filepath, "w", 0777) { |file| file.puts @error_log }
end

#setup variables
event_id         = ARGV[0] #1, 2, 3, etc
SPREADSHEET_FILE = ARGV[1] #session-data.ods, bobs-sessions.ods, etc
JOB_ID           = ARGV[2]
USER_ID          = ARGV[3]

SESSION_FILE_TYPE_ID = SessionFileType.where(name:"Conference Note").first.id
SESSION_FILE_EVENT_FILE_TYPE_ID = EventFileType.where(name:'session_file').first.id

if JOB_ID
	job = Job.find JOB_ID
	job.update!(original_file:SPREADSHEET_FILE, row:0, status:'In Progress')
end

@error_count     = 0
@error_log       = ''

colLetter = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']

# INPUT SPREADSHEET DATA
job.start {

	#open the spreadsheet
	if (SPREADSHEET_FILE.match(/.xlsx/))
		oo = Roo::Excelx.new(SPREADSHEET_FILE)
	elsif ( SPREADSHEET_FILE.match(/.xls/) )
		oo = Roo::Excel.new(SPREADSHEET_FILE)
	elsif ( SPREADSHEET_FILE.match(/.ods/) )
		oo = Roo::Openoffice.new(SPREADSHEET_FILE)
	else
		puts "Spreadsheet format not supported"
		exit
	end

  # based on session_ids and speaker_ids present in database
  DatabaseAdjustment.remove_sessions_speaker_associations event_id

  delta_report = DeltaReport.new({ 
    :session_code             => :string,
    :title                    => :string,
    :date                     => :string,
    :start_time               => :string,
    :end_time                 => :string,
    :room                     => :string,
    :description              => :string,
    :learning_objective       => :string,
    :session_tags             => :string,
    :audience_tags            => :string,
    :speaker_honor_prefix     => :string,
    :speaker_first_name       => :string,
    :speaker_last_name        => :string,
    :speaker_honor_suffix     => :string,
    :speaker_title            => :string,
    :speaker_biography        => :string,
    :online_speaker_photo_url => :string,
    :speaker_company          => :string,
    :speaker_email            => :string,
    :speaker_tax_id           => :string,
    :speaker_code             => :string,
    :credit_hours             => :string,
    :price                    => :string,
    :capactiy                 => :string,
    :published                => :string,
    :sessions_sponsors        => :string,
    :survey_url               => :string,
    :polling_url              => :string,
    :program_type             => :string,
    :ticketed                 => :string,
    :record                   => :string,
    :record_type              => :string,
    :video_thumbnail          => :string,
    :video_iphone             => :string,
    :video_ipad               => :string,
    :video_android            => :string,
    :twitter_tag              => :string,
    :session_file_titles      => :string,
    :session_file_filenames   => :string,
    :session_file_extensions  => :string,
    :session_cancelled        => :string,
    :custom_filter_1          => :string,
    :custom_filter_2          => :string,
	:custom_filter_3          => :string,
	:custom_fields            => :string,
    :promotion                => :string,
    :keywords                 => :string,
    :premium_access           => :string,
	:track_subtrack			=> :string
  }, { 
    treat_nil_and_blank_string_same: true,
    strip_strings_before_comparing: true,
    ignore_linebreaks: true,
		user_id: USER_ID
  })

  populate_hash_for_delta = ->(hash, model) {
    case model.class.name
    when "Session"
      session_file_strings = model.session_file_strings
      hash.merge({

        # Session.columns.map &:name # ["id", "event_id", "unpublished", "session_code", "poster_number", "session_cancelled", "title", "description", "location_mapping_id", "tag_twitter", "date", "start_at", "end_at", "timezone_offset", "published", "record_type", "embedded_video_url", "video_iphone", "video_ipad", "video_android", "video_thumbnail", "thumbnail_event_file_id", "video_duration", "price", "capacity", "credit_hours", "race_approved", "program_type_id", "ticketed", "wvctv", "created_at", "updated_at", "track_subtrack", "session_file_urls", "survey_url", "learning_objective", "poll_url", "tags_safeguard", "custom_filter_1", "custom_filter_2", "custom_filter_3", "custom_fields", "feedback_enabled", "qa_enabled", "promotion", "keyword"]

        session_code:            model.session_code,
        title:                   model.title,
        date:                    model.date,
        start_time:              return_time_value( model.start_at ),
        end_time:                return_time_value( model.end_at ),
        room:                    model.location_mapping && model.location_mapping.name,
        description:             model.description,
        session_tags:            model.tags_string,
        credit_hours:            model.credit_hours,
        sessions_sponsors:       model.sponsors_string,
        survey_url:              model.survey_url,
        polling_url:             model.poll_url,
        program_type:            model.program_type && model.program_type.name,
        ticketed:                model.ticketed,
        record:                  model.wvctv,
        video_thumbnail:         model.video_thumbnail,
        session_file_titles:     session_file_strings[:session_file_titles],
        session_file_filenames:  session_file_strings[:session_file_urls],
        session_file_extensions: session_file_strings[:session_file_filetypes],
        custom_filter_1:         model.custom_filter_1,
        custom_filter_2:         model.custom_filter_2,
        custom_filter_3:         model.custom_filter_3,
        custom_fields:           model.custom_fields,
        promotion:               model.promotion,
        keywords:                model.keyword,
        premium_access:          model.premium_access,
        track_subtrack:          model.track_subtrack,
        # full only fields
        learning_objective: model.learning_objective,
        audience_tags:      model.audience_tags_string,
        price:              model.price,
        capacity:           model.capacity,
        published:          model.published,
        record_type:        model.record_type && RecordType.find(model.record_type).record_type,
        video_iphone:       model.video_iphone,
        video_ipad:         model.video_ipad,
        video_android:      model.video_android,
        tag_twitter:        model.tag_twitter,
        session_cancelled:  model.session_cancelled
      })

    when "Speaker"
      hash.merge({
        speaker_honor_prefix:     model.honor_prefix,
        speaker_first_name:       model.first_name,
        speaker_last_name:        model.last_name,
        speaker_honor_suffix:     model.honor_suffix,
        speaker_title:            model.title,
        speaker_biography:        model.biography,
        online_speaker_photo_url: model.photo_filename,
        speaker_company:          model.company,
        speaker_email:            model.email,
        speaker_code:             model.speaker_code,
        # full only fields
        speaker_tax_id: model.fd_tax_id
      })
    end
  }


	oo.sheets.each do |sheet|

		puts "--------- Processing sheet: #{sheet} ------------\n"
		oo.default_sheet = sheet

		#get field names from first row
		fields     = []
		fieldcount = 0
		1.upto(1) do |row|
			colLetter.each do |col|

				if (oo.cell(row,col)!=nil)
					fields[fieldcount] = oo.cell(row,col)
					#puts fields[fieldcount] + "\n"
					fieldcount += 1
				end

			end #col
		end #row

		puts fields.inspect + "\n"

		nonexistant_columns = []

		fields.each_with_index do |f, i|
			case f.downcase
			when 'session code', 'session_code'
				@session_code_col            = i
			when 'title', 'description (lecture title)'
				@title_col                   = i
			when 'date'
				@date_col                    = i
			when 'start time', 'start_at'
				@start_at_col                = i
			when 'end time', 'end_at'
				@end_at_col                  = i
			when 'room', 'room_name'
				@room_col                    = i
			when 'description'
				@description_col             = i
			when 'session tags', 'session_tags (programsection)'
				@session_tags_col            = i
			when 'audience tags'
				@audience_tags_col           = i
			when 'speaker honor prefix', 'honor_prefix'
				@speaker_honor_prefix_col    = i
			when 'speaker first name', 'first_name'
				@speaker_first_name_col      = i
			when 'speaker middle name', 'middle_name', 'middle initial', 'middle_initial'
				@speaker_middle_initial_col  = i
			when 'speaker last name', 'last_name'
				@speaker_last_name_col       = i
			when 'speaker honor suffix', 'honor_suffix (credentials)'
				@speaker_honor_suffix_col    = i
      when 'speaker title'
        @speaker_title_col           = i
			when 'speaker biography', 'biography'
				@speaker_biography_col       = i
      when 'photo file name', 'photo_filename', 'online speaker photo url'
				@speaker_photo_col           = i
			when 'speaker company', 'organization'
				@speaker_company_col         = i
			when 'speaker email', 'email'
				@speaker_email_col           = i
			when 'speaker code', 'custid'
				@speaker_code_col            = i
			when 'credit hours', 'credit_hours'
				@credit_hours_col            = i
			when 'price'
				@price_col                   = i
			when 'capacity'
				@capacity_col                = i
			when 'session sponsors', 'session_sponsor'
				@session_sponsors_col        = i
			when 'published'
				@published_col               = i
			when 'survey url'
				@survery_url_col             = i
			when 'polling url'
				@polling_url_col             = i
			when 'program type', 'program_type'
				@program_type_col            = i
			when 'ticketed'
				@ticketed_col                = i
			when 'record'
				@record_col                  = i
			when 'record type'
				@record_type_col             = i
			when 'video thumbnail'
				@video_thumbnail_col         = i
			when 'video iphone'
				@video_iphone_col            = i
			when 'embedded video url'
				@embedded_video_url_col      = i
			when 'video ipad'
				@video_ipad_col              = i
			when 'video android'
				@video_android_col           = i
			when 'twitter tag'
				@twitter_tag_col             = i
			when 'session file titles'
				@session_file_titles_col     = i
			when 'session file filenames'
				@session_file_filenames_col  = i
			when 'session file extensions'
				@session_file_extensions_col = i
			when 'session cancelled'
				@session_cancelled_col       = i
			when 'speaker_goeshow_key'
			when 'speaker tax id'
				@speaker_tax_id                = i
			when 'learning objective', 'learning objectives'
				@learning_objective_col        = i
			when 'custom filter 1'
				@custom_filter_1_col           = i
     	when 'custom filter 2'
        @custom_filter_2_col           = i
      when 'custom filter 3'
        @custom_filter_3_col           = i
      when 'custom fields'
        @custom_fields_col             = i
      when 'promotion', 'promotions'
        @promotion_col                 = i
      when 'keyword', 'keywords'
        @keyword_col                   = i
      when 'premium access'
        @premium_access_col            = i
	  when 'track subtrack'
        @ptrack_subtrack_col           = i
			else
				nonexistant_columns << f
				@error_count += 1
			end

		end

		if nonexistant_columns.length > 0
			generate_columns_error_log(nonexistant_columns, event_id)
			raise "The following columns are incorrectly named: #{nonexistant_columns.inspect}".red
		end

		#get records on sheet
		colvals = []

		total_rows = oo.last_row - 1

		job.update!(total_rows:total_rows, status:'Processing Rows')

		2.upto(oo.last_row) do |row|

			job.row = job.row + 1
			job.write_to_file if job.row % job.rows_per_write == 0

			t = Time.now

			#collect all the column values for the row
			0.upto(fieldcount-1) do |colnum|

				#collect value, if any
				if (oo.cell(row,colLetter[colnum])==nil)
					colvals[colnum] = ''
				else
					colvals[colnum] = oo.cell(row,colLetter[colnum])
				end

			end #col

      valueFor = ->(index, default=nil) { index.nil? ? default : colvals[index] }

			#column mappings
			if @session_code_col
		
				if (is_number(colvals[@session_code_col]))
					#session_code     = sprintf("%.0f",colvals[@session_code_col].to_s)
					session_code = colvals[@session_code_col].to_s
					if session_code.include? ".0"
						session_code = session_code.chomp(".0")
					end
				else
					session_code = colvals[@session_code_col]
				end
			else
				session_code = nil
			end

      session_title = valueFor[@title_col]
			session_date  = valueFor[@date_col]

			def return_time_value(val)
				if !val.is_a?(String)
					result = Time.at(val.to_i).gmtime
					result = result + (1) if result.sec == 59
					result.strftime('%R:%S')
				else
					# Time.parse(val).gmtime.strftime('%T')
          # gmtime would cause the time to be translated from
          # the computer's local time, to greenwich mean time.
          # okay on production, but not okay locally
          # In the condition above, it might be okay because the
          # integer represents seconds since 1970, and cannot be
          # malformed, unlike parse, which automatically assumes
          # the local time zone
          # Time.parse(val).strftime('%T')
          ActiveSupport::TimeZone.new('UTC').parse(val).strftime('%T')
				end
			end

			if @start_at_col && @end_at_col
				session_start_at = return_time_value(colvals[@start_at_col])
				session_end_at   = return_time_value(colvals[@end_at_col])
			else
				session_start_at = nil
				session_end_at   = nil
			end

			room_name           = valueFor[@room_col]
			session_description = valueFor[@description_col]

			if @session_tags_col
				#split out the session tagsets
				session_tags = colvals[@session_tags_col].split('^^').map { |a| a.strip }
				session_tags.each_with_index do |item,i|
					session_tags[i] = item.split('||').map { |a| a.strip }
				end
			else
				session_tags = []
			end

			if @audience_tags_col
				#split out the session-audience tagsets
				audience_tags = colvals[@audience_tags_col].split('^^').map { |a| a.strip }
				audience_tags.each_with_index do |item,i|
					audience_tags[i] = item.split('||').map { |a| a.strip }
				end
			else
				audience_tags = []
			end

			speaker_honor_prefix   = valueFor[@speaker_honor_prefix_col]
			speaker_first_name     = valueFor[@speaker_first_name_col]
			speaker_middle_initial = valueFor[@speaker_middle_initial_col, '']
			speaker_last_name      = valueFor[@speaker_last_name_col]
			speaker_honor_suffix   = valueFor[@speaker_honor_suffix_col]
      speaker_title          = valueFor[@speaker_title_col]
			speaker_biography      = valueFor[@speaker_biography_col]
			speaker_photo_filename = valueFor[@speaker_photo_col]
			speaker_company        = valueFor[@speaker_company_col]
			speaker_email          = valueFor[@speaker_email_col, '']
			speaker_fd_tax_id      = valueFor[@speaker_tax_id]

			#speaker_biography = sanitize_for_db(speaker_biography)

      speaker_code = valueFor[@speaker_code_col]
      speaker_code = is_number(speaker_code) ? speaker_code.to_i.to_s : speaker_code

      credit_hours = valueFor[@credit_hours_col]
			credit_hours = credit_hours.blank? ? nil : sprintf("%.2f", credit_hours.to_f)
			price        = valueFor[@price_col]

      capacity = valueFor[@capacity_col]
      capactiy = is_number(capactiy) ? capactiy.to_i.to_s : capactiy

			published = valueFor[@published_col]

			session_sponsors = @session_sponsors_col ? colvals[@session_sponsors_col].split('##').map { |a| a.strip } : []

			survey_url = valueFor[@survery_url_col]
			poll_url   = valueFor[@polling_url_col]

			if @program_type_col
				program_type_id = ProgramType.where(name:colvals[@program_type_col]).first.id unless ProgramType.where(name:colvals[@program_type_col]).length===0
			else
				program_type_id = nil
			end

			ticketed        = valueFor[@ticketed_col]
			wvctv           = valueFor[@record_col]
			video_thumbnail = valueFor[@video_thumbnail_col]

			if @record_type_col
				record_type = RecordType.where(record_type:colvals[@record_type_col]).first.id unless RecordType.where(record_type:colvals[@record_type_col]).length===0
			else
				record_type = nil
			end

			video_iphone    = valueFor[@video_iphone_col]
			embedded_video_url    = valueFor[@embedded_video_url_col]
			video_ipad      = valueFor[@video_ipad_col]
			video_android   = valueFor[@video_android_col]
			tag_twitter     = valueFor[@twitter_tag_col]
			custom_filter_1 = valueFor[@custom_filter_1_col]
      custom_filter_2 = valueFor[@custom_filter_2_col]
custom_filter_3 = valueFor[@custom_filter_3_col]
custom_fields = valueFor[@custom_fields_col]
      
      keyword   = valueFor[@keyword_col]
      promotion = valueFor[@promotion_col]
      premium_access = valueFor[@premium_access_col]
	  track_subtrack = valueFor[@track_subtrack_col]

			learning_objective = valueFor[@learning_objective_col]

			####### JSON STUFF ########
			if @session_file_filenames_col && @session_file_titles_col && @session_file_extensions_col
				if colvals[@session_file_filenames_col] != nil
					session_files_filenames = colvals[@session_file_filenames_col].split(',').map { |a| a.strip }
					if colvals[@session_file_titles_col] != nil
						session_files_titles = colvals[@session_file_titles_col].split(',').map { |a| a.strip }
					end
					if colvals[@session_file_extensions_col] != nil
						session_files_types = colvals[@session_file_extensions_col].split(',').map { |a| a.strip }
					end
				else
					session_files_filenames = ''
					session_files_titles    = ''
					session_files_types     = ''
				end
			else
				session_files_filenames = ''
				session_files_titles    = ''
				session_files_types     = ''
			end

			@session_cancelled_col ? session_cancelled = colvals[@session_cancelled_col] : session_cancelled = 0

			puts "session title: #{session_title}\n"

			session_attrs = 
        {event_id:           event_id,
         session_code:       session_code,
         title:              session_title,
         description:        session_description,
         date:               session_date,
         start_at:           session_start_at,
         end_at:             session_end_at,
         credit_hours:       credit_hours,
         survey_url:         survey_url,
         poll_url:           poll_url,
         program_type_id:    program_type_id,
         ticketed:           ticketed,
         wvctv:              wvctv,
         record_type:        record_type,
         video_thumbnail:    video_thumbnail,
		 embedded_video_url: embedded_video_url,
         video_iphone:       video_iphone,
         video_ipad:         video_ipad,
         video_android:      video_android,
         session_cancelled:  session_cancelled,
         price:              price,
         capacity:           capacity,
         tag_twitter:        tag_twitter,
         published:          published,
         learning_objective: learning_objective,
         custom_filter_1:    custom_filter_1,
		 custom_filter_2:    custom_filter_2,
		 custom_filter_3:    custom_filter_3,
		 custom_fields:      custom_fields,
         keyword:            keyword,
         promotion:          promotion,
         premium_access:     premium_access,
     	track_subtrack:      track_subtrack}

			speaker_attrs = 
        {event_id:       event_id,
         first_name:     speaker_first_name,
         last_name:      speaker_last_name,
         honor_prefix:   speaker_honor_prefix,
         honor_suffix:   speaker_honor_suffix,
         title:          speaker_title,
         company:        speaker_company,
         biography:      speaker_biography,
         photo_filename: speaker_photo_filename,
         email:          speaker_email,
         fd_tax_id:      speaker_fd_tax_id,
         speaker_code:   speaker_code}

			location_mapping_type  = LocationMappingType.where(type_name:'Room')[0]
			location_mapping_attrs = { event_id: event_id, name: room_name, mapping_type: location_mapping_type.id }

			sessions = Session.where(session_code: session_code, event_id: event_id)
			if sessions.length==0
        delta_report.before = {}
				session = Session.new(session_attrs)
				session.save
				if session_files_filenames!=""
					makeJson(session, session_files_filenames, session_files_titles, session_files_types, event_id)
				end
			elsif sessions.length > 0
				session = sessions[0]

        delta_report.before = populate_hash_for_delta[ {}, session ]

				session.update!(session_attrs)
				if session_files_filenames!=""
					makeJson(session, session_files_filenames, session_files_titles, session_files_types, event_id)
				end
			end

			session.session_file_urls = nil if session.session_file_urls === "[]"

			program_type = ProgramType.where(name:program_type)
			if program_type.length==1
				session.program_type_id = program_type.first.id
			else
				session.program_type_id = 1
			end
			session.save

			location_mappings = LocationMapping.where(name:room_name,event_id:event_id)
			if location_mappings.length==0
				location_mapping = LocationMapping.new(location_mapping_attrs)
			else
				location_mapping = location_mappings[0]
				location_mapping.update!(location_mapping_attrs)
			end
			location_mapping.save
			session.location_mapping = location_mapping
			session.save

      session.update_tags session_tags, 'session'
      session.update_tags audience_tags, 'session-audience'

			if speaker_code!='' || speaker_email!='' || (speaker_first_name!='' && speaker_last_name!='')

				puts "adding/updating speaker: #{speaker_attrs}"

				if speaker_code!=''
					speakers = Speaker.where(event_id:event_id,speaker_code:speaker_code)
				elsif speaker_email!=''
					speakers = Speaker.where(event_id:event_id,email:speaker_email)
				else
					speakers = Speaker.where(first_name:speaker_first_name,last_name:speaker_last_name,event_id:event_id)
				end

				if speakers.length===0
					puts "creating speaker"
					speaker = Speaker.new(speaker_attrs)
				else
					puts "updating speaker"
					speaker = speakers.first
          delta_report.before = populate_hash_for_delta[ delta_report.before, speaker ]
					speaker.update!(speaker_attrs)
				end

        # I'm not sure that I actually want to change to this; it's possible
        # the cordova app or the online portal relies on the event_file.path
        # containing the full url, even though that is unintuitive.
        # For now online_photo? can just be used to determine the status of
        # the speaker form checkbox
				# unless speaker.online_photo?
					# speaker.createPhotoPlaceholder(speaker_photo_filename)
				# end

				if speaker_photo_filename!=''
					speaker.createPhotoPlaceholder(speaker_photo_filename)
				end

				speaker.save # this save is probably redundant
				default_speaker_type_id = SpeakerType.where(speaker_type: "Primary Presenter").first.id
				sessions_speaker = SessionsSpeaker.where(session_id:session.id,speaker_id:speaker.id).first_or_initialize
				sessions_speaker.speaker_type_id ||= default_speaker_type_id
				sessions_speaker.save!
			end

			session_sponsors.each do |sponsor_name|
				exhibitor_attrs = { event_id:event_id,company_name:sponsor_name,is_sponsor:1 }
				exhibitor = Exhibitor.where(event_id:event_id, company_name:sponsor_name).first_or_initialize
				exhibitor.update!(exhibitor_attrs)
				exhibitor.save
				session_sponsor = SessionsSponsor.where(session_id:session.id,sponsor_id:exhibitor.id).first_or_initialize
				session_sponsor.save
			end

      # this extra find because we need to reload the session and its relations. Otherwise
      # we get issues where queries on the session don't find new relations in some cases
      delta_report.after = populate_hash_for_delta[ {}, Session.find(session.id) ] if session
      delta_report.after = populate_hash_for_delta[ delta_report.after, speaker ] if speaker
      delta_report.compare

		end #row
	end #sheet

  if Event.find( event_id ).session_date_loc_meta_tags?
    job.update!(status:'Adding meta data to tags')
    job.write_to_file
    Tag.add_all_session_meta_tag_data event_id
  end

  job.update!(status:'Generating Delta Report')
  job.write_to_file

  delta_path = delta_report.export(
    "upload_sessions_full_delta_#{Time.now.strftime('%Y%m%d%H%M%S')}.xlsx",
    event_id
  ).to_s.split('public')[1]

  job.add_info "<a class='btn btn-success btn-sm' href='#{delta_path}'>Change Report</a>"

} # Job.start
