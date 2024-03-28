###########################################
# Ruby script to import exhibitor data from
# spreadsheet (ODS) into EventKaddy CMS
###########################################

require 'roo'
require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'
require_relative '../delta_report.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(adapter:"mysql2", host:@db_host, username:@db_user, password:@db_pass, database:@db_name)

def makeJson(currentexhibitor, filenames, titles, types, event_id)
  custom_fields = ExhibitorFileUrlsEntity.new json: currentexhibitor.exhibitor_files_url

	filenames.each_with_index do |filename, i|
		filename.gsub!(/\s/,'_')
		puts "--- filename: #{filename} ---"

    path        = "/event_data/#{event_id}/exhibitor_files/#{filename}"
		event_files = EventFile.where event_id: event_id, path: path

		if event_files.length == 1
			puts "--- updating exhibitor_file ---"
      exhibitor_file = event_files.first.exhibitor_file
			exhibitor_file.update_column(:title, titles[i])
      event_files.first.update_column(:mime_type, types[i])
      custom_fields.remove_by [{ef_id: exhibitor_file.id}]
      custom_fields.add [{
        "title" => titles[i],
        "url"   => path,
        "type"  => types[i],
        "ef_id" => exhibitor_file.id
      }]
    elsif event_files.length == 0
			event_file = EventFile.where(
        name:               filename,
        path:               path,
        mime_type:          types[i],
				event_id:           event_id,
        event_file_type_id: EXHIBITOR_FILE_EVENT_FILE_TYPE_ID
      ).first_or_create

      exhibitor_file = ExhibitorFile.new(
        title:                  titles[i],
        description:            "Exhibitor File",
        exhibitor_file_type_id: EXHIBITOR_FILE_TYPE_ID,
        event_id:               event_id,
        exhibitor_id:           currentexhibitor.id,
        event_file_id:          event_file.id
      )
      exhibitor_file.save!(:validate => false) # ignore filesize validations

      custom_fields.remove_by [{ef_id: exhibitor_file.id}]
      custom_fields.add [{
        "title" => titles[i],
        "url"   => path,
        "type"  => types[i],
        "ef_id" => exhibitor_file.id
      }]
    else
      puts "---ERROR duplicate event files, #{event_files.inspect} ---"
    end
  end
	puts "--- adding #{custom_fields.inspect} to custom_fields ---"
	currentexhibitor.update_column(:custom_fields, custom_fields.array.length > 0 ? custom_fields.json : nil)
end

def generate_columns_error_log(nonexistant_columns, event_id)
	@error_log += "The following columns are incorrectly named:\n\n"
	nonexistant_columns.each {|c| @error_log += "\t" + c + "\n"}
	new_filename = "error_log.txt"
	filepath     = Rails.root.join('public','event_data', event_id.to_s,'error_logs',new_filename)
	dirname      = File.dirname(filepath)
	@error_log   = "Refresh Error Report\n\nNumber of Errors: #{@error_count}\n\n\n\n\n" + @error_log
	FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
	File.open(filepath, "w", 0777) { |file| file.puts @error_log }
end

event_id         = ARGV[0] #1, 2, 3, etc
SPREADSHEET_FILE = ARGV[1] #exhibitor-data.ods, bobs-exhibtors.ods, etc
JOB_ID           = ARGV[2]
USER_ID          = ARGV[3]

EXHIBITOR_FILE_TYPE_ID = ExhibitorFileType.where(name:"exhibitor_document").first.id
EXHIBITOR_FILE_EVENT_FILE_TYPE_ID = EventFileType.where(name:'exhibitor_file').first.id

if JOB_ID
	job = Job.find JOB_ID
	job.update!(original_file:SPREADSHEET_FILE, row:0, status:'In Progress')
end

@error_count     = 0
@error_log       = ''

colLetter = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']

job.start {

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

  delta_report = DeltaReport.new({ :company_name              => :string,
                                   :exhibitor_code            => :string,
                                   :booth_name                => :string,
                                   :logo                      => :string,
                                   :description               => :string,
                                   :address_1                 => :string,
                                   :address_2                 => :string,
                                   :city                      => :string,
                                   :state                     => :string,
                                   :zip                       => :string,
                                   :country                   => :string,
                                   :phone                     => :string,
                                   :fax                       => :string,
                                   :toll_free                 => :string,
                                   :contact_name              => :string,
                                   :email                     => :string,
                                   :contact_title             => :string,
                                   :message                   => :string,
                                   :url_facebook              => :string,
                                   :url_linkedin              => :string,
                                   :url_rss                   => :string,
                                   :url_twitter               => :string,
                                   :url_web                   => :string,
                                   :is_sponsor?               => :string,
                                   :sponsor_level_name          => :string,
                                   :exhibitor_tags            => :string,
                                   :exhibitor_file_titles     => :string,
                                   :exhibitor_file_filenames  => :string,
                                   :exhibitor_file_extensions => :string,
                                   :attendee_codes            => :string
  }, {
    treat_nil_and_blank_string_same: true,
    strip_strings_before_comparing:  true,
    ignore_linebreaks:               true,
    treat_falsey_values_equal:       true,
    user_id: USER_ID
  })

  # keys must match delta_report schema (headers), or they will not show up in xlsx output
  populate_hash_for_delta = ->(hash, model) {
    exhibitor_file_strings = model.exhibitor_file_strings
    hash.merge({
      company_name:              model.company_name,
      exhibitor_code:            model.exhibitor_code,
      booth_name:                model.location_name,
      logo:                      model.logo,
      description:               model.description,
      address_1:                 model.address_line1,
      address_2:                 model.address_line2,
      city:                      model.city,
      state:                     model.state,
      zip:                       model.zip,
      country:                   model.country,
      phone:                     model.phone,
      fax:                       model.fax,
      toll_free:                 model.toll_free,
      contact_name:              model.contact_name,
      email:                     model.email,
      contact_title:             model.contact_title,
      message:                   model.message,
      url_facebook:              model.url_facebook,
      url_linkedin:              model.url_linkedin,
      url_rss:                   model.url_rss,
      url_twitter:               model.url_twitter,
      url_web:                   model.url_web,
      is_sponsor?:               model.is_sponsor,
      sponsor_level_name:          model.sponsor_level_type.sponsor_type,
      exhibitor_tags:            model.tags_string,
      exhibitor_file_titles:     exhibitor_file_strings[:exhibitor_file_titles],
      exhibitor_file_filenames:  exhibitor_file_strings[:exhibitor_file_urls],
      exhibitor_file_extensions: exhibitor_file_strings[:exhibitor_file_filetypes],
      attendee_codes:            model.attendees.map(&:account_code).join(',')
    })

  }

	oo.sheets.each do |sheet|
		puts "--------- Processing sheet: #{sheet} ------------\n"
		oo.default_sheet = sheet

		#get field names from first row
		fields     = []
		fieldcount = 0
		1.upto(1) do |row|
			colLetter.each do |col|
				if oo.cell(row,col)!=nil
					fields[fieldcount] = oo.cell(row,col)
					#puts fields[fieldcount] + "\n"
					fieldcount += 1
				end
			end #col
		end #row

		puts fields.inspect.to_s + "\n"
    nonexistant_columns = []

    fields.each_with_index do |f, i|
      case f.downcase
      when 'company name'
        @company_name_col              = i
      when 'exhibitor code'
        @exhibitor_code_col            = i
      when 'booth name', 'booth number'
        @booth_name_col                = i
      when 'logo'
        @logo_col                      = i
      when 'description'
        @description_col               = i
      when 'address 1'
        @address1_col                  = i
      when 'address 2'
        @address2_col                  = i
      when 'city'
        @city_col                      = i
      when 'state'
        @state_col                     = i
      when 'zip', 'postal code'
        @zip_col                       = i
      when 'country'
        @country_col                   = i
      when 'phone'
        @phone_col                     = i
      when 'fax'
        @fax_col                       = i
      when 'toll free'
        @toll_free_col                 = i
      when 'contact name'
        @contact_name_col              = i
      when 'email'
        @email_col                     = i
      when 'password'
        @password_col                  = i
      when 'contact title'
        @contact_title_col             = i
      when 'message'
        @message_col                   = i
      when 'url facebook'
        @url_facebook_col              = i
      when 'url linkedin'
        @url_linkedin_col              = i
      when 'url rss'
        @url_rss_col                   = i
      when 'url twitter'
        @url_twitter_col               = i
      when 'url web', 'website'
        @url_web_col                   = i
      when 'is sponsor?'
        @is_sponsor_col                = i
      when 'sponsor level name'
        @sponsor_level_name_col          = i
      when 'exhibitor tags', 'exhibitor tag'
        @exhibitor_tags_col            = i
      when 'exhibitor file titles'
        @exhibitor_file_titles_col     = i
      when 'exhibitor file filenames'
        @exhibitor_file_filenames_col  = i
      when 'exhibitor file extensions'
        @exhibitor_file_extensions_col = i
      when 'attendee codes'
        @attendee_codes_col = i
      when 'complimentary passes'
        @exhibitor_complimentary_passes = i
      when 'discount passes'
        @exhibitor_discount_passes = i
      else
        nonexistant_columns << f
        @error_count += 1
      end
    end

    if nonexistant_columns.length > 0
      generate_columns_error_log(nonexistant_columns, event_id)
      raise "The following columns are incorrectly named: #{nonexistant_columns.inspect}".red
    end

		colvals    = []
		total_rows = oo.last_row - 1

		job.update!(total_rows:total_rows, status:'Processing Rows')

		2.upto(oo.last_row) do |row|

			job.row = job.row.to_i + 1
			job.write_to_file if job.row % job.rows_per_write == 0

			t = Time.now

			#collect all the column values for the row
			0.upto(fieldcount-1) do |colnum|

				#collect value, if any
				if oo.cell(row,colLetter[colnum])==nil
					colvals[colnum] = ''
				else
					colvals[colnum] = oo.cell(row,colLetter[colnum])
				end

			end #col

      valueFor = ->(index, default=nil) { index.nil? ? default : colvals[index] }

      # when a value, like a number, could include dashes or a +,
      # but also could be all numbers, we need to make sure it doesn't get
      # saved as a float
      valueForStringOrInt = ->(index, default=nil) {
        if colvals[ index ].is_a? Float
          colvals[ index ].to_i
        else
          colvals[ index ]
        end
      }

			company_name  = valueFor[@company_name_col]
			exhibitor_code= valueFor[@exhibitor_code_col]
      booth_name    = valueForStringOrInt[ @booth_name_col ]
      logo          = valueFor[@logo_col]
      description   = valueFor[@description_col]
      address_line1 = valueForStringOrInt[ @address1_col ]
      address_line2 = valueForStringOrInt[ @address2_col ]
      city          = valueFor[@city_col]
      state         = valueFor[@state_col]
      zip           = valueForStringOrInt[ @zip_col ]
      country       = valueFor[@country_col]
      phone         = valueForStringOrInt[ @phone_col ]
      fax           = valueForStringOrInt[ @fax_col ]
      toll_free     = valueForStringOrInt[@toll_free_col]
      contact_name  = valueFor[@contact_name_col]
      email         = valueFor[@email_col]
      contact_title = valueFor[@contact_title_col]
      message       = valueFor[@message_col]
      url_facebook  = valueFor[@url_facebook_col]
      url_linkedin  = valueFor[@url_linkedin_col]
      url_rss       = valueFor[@url_rss_col]
      url_twitter   = valueFor[@url_twitter_col]
      url_web       = valueFor[@url_web_col]
      complimentary_passes = valueFor[@exhibitor_complimentary_passes]
      discount_passes      = valueFor[@exhibitor_discount_passes]
      staffs        =  {
        discount_staff_count: discount_passes ? discount_passes : 0,
        complimentary_staff_count: complimentary_passes ? complimentary_passes : 0
      }

      is_sponsor    = valueFor[@is_sponsor_col]
      is_sponsor    = is_sponsor.to_s.downcase == "true" ? 1 : is_sponsor.to_i

      attendee_codes = valueFor[@attendee_codes_col]

      sponsor_level_name = valueFor[@sponsor_level_name_col]
      sponsor_level_type_id = SponsorLevelType.where(sponsor_type: sponsor_level_name).first_or_create.id

			if @exhibitor_tags_col
				exhibitor_tags = colvals[@exhibitor_tags_col].split('^^').map { |a| a.strip }
				exhibitor_tags.each_with_index do |item,i|
					exhibitor_tags[i] = item.split('||').map { |a| a.strip }
				end
			else
				exhibitor_tags = []
			end

			####### JSON STUFF ########
			if @exhibitor_file_filenames_col && @exhibitor_file_titles_col && @exhibitor_file_extensions_col
				if colvals[@exhibitor_file_filenames_col]
					exhibitor_files_filenames = colvals[@exhibitor_file_filenames_col].split(',').map { |a| a.strip }
					if colvals[@exhibitor_file_titles_col]
						exhibitor_files_titles = colvals[@exhibitor_file_titles_col].split(',').map { |a| a.strip }
					end
					if colvals[@exhibitor_file_extensions_col]
						exhibitor_files_types = colvals[@exhibitor_file_extensions_col].split(',').map { |a| a.strip }
					end
				else
					exhibitor_files_filenames = ''
					exhibitor_files_titles    = ''
					exhibitor_files_types     = ''
				end
			else
				exhibitor_files_filenames = ''
				exhibitor_files_titles    = ''
				exhibitor_files_types     = ''
			end

			puts "company_name: #{company_name}\n"

      # there is no reason for the intermediate values here, could be refactored
      # to be assigned directly to the result of the fetches
			exhibitor_attrs = {
        event_id:              event_id,
        exhibitor_code:        exhibitor_code,
        company_name:          company_name,
        logo:                  logo,
        description:           description,
        address_line1:         address_line1,
        address_line2:         address_line2,
        city:                  city,
        state:                 state,
        zip:                   zip,
        country:               country,
        contact_name:          contact_name,
        email:                 email,
        phone:                 phone,
        fax:                   fax,
        message:               message,
        url_facebook:          url_facebook,
        url_linkedin:          url_linkedin,
        url_rss:               url_rss,
        url_twitter:           url_twitter,
        url_web:               url_web,
        toll_free:             toll_free,
        contact_title:         contact_title,
        is_sponsor:            is_sponsor,
        sponsor_level_type_id: sponsor_level_type_id,
        staffs:                staffs.as_json
      }

      unless booth_name.blank?
        location_mapping_attrs = {
          event_id:     event_id,
          name:         booth_name,
          mapping_type: LocationMappingType.where(type_name:'Booth').first.id
        }

        location_mappings = LocationMapping.where(name:booth_name, event_id:event_id)

        if location_mappings.length===0
          location_mapping = LocationMapping.new(location_mapping_attrs)
        else
          location_mapping = location_mappings[0]
          location_mapping.update!(location_mapping_attrs)
        end

        location_mapping.save
      else
        location_mapping = nil
      end

      exhibitors = if exhibitor_code.blank?
                     Exhibitor.where( company_name: company_name, event_id: event_id )
                   else
                     Exhibitor.where( exhibitor_code: exhibitor_code, event_id: event_id )
                   end

			if exhibitors.length == 0
        delta_report.before = {}
				exhibitor = Exhibitor.create exhibitor_attrs
				if exhibitor_files_filenames!=""
					makeJson(exhibitor, exhibitor_files_filenames, exhibitor_files_titles, exhibitor_files_types, event_id)
				end
			elsif exhibitors.length == 1
				exhibitor = exhibitors[0]
        delta_report.before = populate_hash_for_delta[ {}, exhibitor ]
				exhibitor.update! exhibitor_attrs
				if exhibitor_files_filenames!=""
					makeJson(exhibitor, exhibitor_files_filenames, exhibitor_files_titles, exhibitor_files_types, event_id)
				end
			elsif exhibitors.length > 1
        if exhibitor_code.blank?
          job.add_warning "More than one exhibitor was found for #{company_name}, updating only first record found."
        else
          job.add_warning "More than one exhibitor was found for code #{exhibitor_code}, updating only first record found."
        end
				exhibitor = exhibitors[0]
        delta_report.before = populate_hash_for_delta[ {}, exhibitor ]
				exhibitor.update! exhibitor_attrs
				if exhibitor_files_filenames!=""
					makeJson(exhibitor, exhibitor_files_filenames, exhibitor_files_titles, exhibitor_files_types, event_id)
				end
			end

			exhibitor.location_mapping = location_mapping

			exhibitor.save
      exhibitor.update_tags exhibitor_tags, 'exhibitor'

      EventSponsorLevelType.where(event_id: exhibitor.event_id, sponsor_level_type_id: exhibitor.sponsor_level_type_id).first_or_create

      User.first_or_create_for_exhibitor(
        exhibitor, valueFor[@password_col]
      )

      if exhibitor.exhibitor_code.blank?
        exhibitor.update_column(:exhibitor_code, "o_#{exhibitor.id}")
      end

      exhibitor.update_booth_owners(
                                    attendee_codes.split(',')
                                   )[:errors].each do |e|
                                     job.add_warning e
                                   end

      # this extra find because we need to reload the exhibitor and its relations. Otherwise
      # we get issues where queries on the exhibitor don't find new relations in some cases
      delta_report.after = populate_hash_for_delta[ {}, Exhibitor.find(exhibitor.id) ] if exhibitor
      delta_report.compare

		end #row
	end #sheet

  # if an Exhibitor Type attendee no longer has a booth_owner association, that attendee's type
  # must be set back to Standard Attendee
  Attendee.cleanup_abandoned_booth_owners event_id

  job.update_column(:status,'Generating Delta Report')
  job.write_to_file

  delta_path = delta_report.export(
    "upload_exhibitors_delta_#{Time.now.strftime('%Y%m%d%H%M%S')}.xlsx",
    event_id
  ).to_s.split('public')[1]

  job.add_info "<a class='btn btn-success btn-sm' href='#{delta_path}'>Change Report</a>"

} # Job.start
