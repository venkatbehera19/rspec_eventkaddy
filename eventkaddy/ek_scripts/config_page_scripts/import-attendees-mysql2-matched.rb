###########################################
#Ruby script to import attendee data from
#spreadsheet into EventKaddy CMS
###########################################

require 'roo'
require 'date'
require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'
require_relative '../delta_report.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(adapter:"mysql2", host:@db_host, username:@db_user, password:@db_pass, database:@db_name)

def generate_columns_error_log(nonexistant_columns)
  @error_log += "The following columns are incorrectly named:\n\n"
  nonexistant_columns.each {|c| @error_log += "\t" + c + "\n"}
  new_filename = "error_log.txt"
  filepath     = Rails.root.join('public','event_data', EVENT_ID.to_s,'error_logs',new_filename)
  dirname      = File.dirname(filepath)
  @error_log   = "Refresh Error Report\n\nNumber of Errors: #{@error_count}\n\n\n\n\n" + @error_log
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  File.open(filepath, "w", 0777) { |file| file.puts @error_log }
end

EVENT_ID         = ARGV[0]
SPREADSHEET_FILE = ARGV[1]
JOB_ID           = ARGV[2]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:SPREADSHEET_FILE, row:0, status:'In Progress')
end

job.start {

  @error_count     = 0
  @error_log       = ''

  # app/services/pn_filter_processor.rb
  pn_filter_processor = PnFilterProcessor.new( EVENT_ID )

  colLetter = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']

  #open the spreadsheet
  if SPREADSHEET_FILE.match /.xlsx/
    oo = Roo::Excelx.new SPREADSHEET_FILE
  elsif SPREADSHEET_FILE.match /.xls/
    oo = Roo::Excel.new SPREADSHEET_FILE
  elsif SPREADSHEET_FILE.match /.ods/
    oo = Roo::Openoffice.new SPREADSHEET_FILE
  else
    raise "Spreadsheet format not supported."
  end


  delta_report = DeltaReport.new({:first_name           => :string,
                                  :last_name            => :string,
                                  :honor_prefix         => :string,
                                  :honor_suffix         => :string,
                                  :title                => :string,
                                  :company              => :string,
                                  :temp_photo_filename  => :string,
                                  :attendee_tags        => :string,
                                  :biography            => :string,
                                  :business_unit        => :string,
                                  :business_phone       => :string,
                                  :mobile_phone         => :string,
                                  :email                => :string,
                                  :registration_id      => :string,
                                  :username             => :string,
                                  :password             => :string,
                                  :registered_sessions  => :string,
                                  :assignment           => :string,
                                  :custom_filter_1      => :string,
                                  :custom_filter_2      => :string,
                                  :custom_filter_3      => :string,
                                  :messaging_opt_out    => :string,
                                  :app_listing_opt_out  => :string,
                                  :game_opt_out         => :string,
                                  :notification_filters => :string,
                                  :custom_fields_1      => :string,
 								                  :custom_fields_2      => :string,
								                  :custom_fields_3      => :string,
                                  :travel_info          => :string,
                                  :table_assignment     => :string,
                  								:city			            => :string,
                  								:state			          => :string,
                  								:country  		        => :string,
                                  :premium_member       => :string
  }, { 
    treat_nil_and_blank_string_same: true,
    strip_strings_before_comparing:  true,
    ignore_linebreaks:               true,
    treat_falsey_values_equal:       true
  })

  # keys must match delta_report schema (headers), or they will not show up in xlsx output
  populate_hash_for_delta = ->(hash, model) {
    hash.merge({
      first_name:           model.first_name,
      last_name:            model.last_name,
      honor_prefix:         model.honor_prefix,
      honor_suffix:         model.honor_suffix,
      title:                model.title,
      company:              model.company,
      temp_photo_filename:  model.temp_photo_filename,
      attendee_tags:        ReturnTagsAsStringForModel.new(model:model, tag_type:'attendee').call,
      biography:            model.biography,
      business_unit:        model.business_unit,
      business_phone:       model.business_phone,
      mobile_phone:         model.mobile_phone,
      email:                model.email,
      registration_id:      model.account_code,
      username:             model.username,
      password:             model.password,
      registered_sessions:  model.favourited_sessions_as_string,
      assignment:           model.assignment,
      custom_filter_1:      model.custom_filter_1,
      custom_filter_2:      model.custom_filter_2,
      custom_filter_3:      model.custom_filter_3,
      messaging_opt_out:    model.messaging_opt_out,
      app_listing_opt_out:  model.app_listing_opt_out,
      game_opt_out:         model.game_opt_out,
      notification_filters: model.pn_filters ? JSON.parse(model.pn_filters).join(', ') : nil,
      custom_fields_1:      model.custom_fields_1,
      custom_fields_2:      model.custom_fields_2,
      custom_fields_3:      model.custom_fields_3,
      travel_info:          model.travel_info,
      table_assignment:     model.table_assignment,
  	  city: 			          model.city,
  	  state:     		        model.state,
  	  country:     		      model.country, 
      premium_member:       model.premium_member
    })
  }


  exhibitor_attendee_type_id = AttendeeType.where(name:"Exhibitor").first.id

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

    puts fields.inspect + "\n"

    nonexistant_columns = []

    fields.each_with_index do |f, i|
      case f.downcase
      when 'first name'
        @first_name_col          = i
      when 'last name'
        @last_name_col           = i
      when 'honor prefix'
        @honor_prefix_col        = i
      when 'honor suffix'
        @honor_suffix_col        = i
      when 'title'
        @title_col               = i
      when 'company'
        @company_col             = i
      when 'biography'
        @biography_col           = i
      when 'business unit'
        @business_unit_col       = i
      when 'business phone'
        @business_phone_col      = i
      when 'mobile phone'
        @mobile_phone_col        = i
      when 'email'
        @email_col               = i
      when 'temp photo filename'
        @temp_photo_filename_col = i
      when 'registration id'
        @registration_id_col     = i
      when 'username'
        @username_col            = i
      when 'password'
        @password_col            = i
      when 'registered sessions'
        @registered_sessions_col = i
      when 'assignment'
        @assignment_col          = i
      when 'custom filter 1'
        @custom_filter_1         = i
      when 'custom filter 2'
        @custom_filter_2         = i
      when 'custom filter 3'
        @custom_filter_3         = i
      when 'messaging opt out'
        @messaging_opt_out       = i
      when 'app listing opt out'
        @app_listing_opt_out     = i
      when 'game opt out'
        @game_opt_out            = i
      when 'custom fields 1'
        @custom_fields_1_col     = i
      when 'custom fields 2'
        @custom_fields_2         = i
      when 'custom fields 3'
        @custom_fields_3         = i
      when 'travel info'
        @travel_info             = i
      when 'table assignment'
        @table_assignment        = i
  	  when 'city'
        @city                    = i
  	  when 'state'
        @state                   = i
  	  when 'country'
        @country                 = i
      when 'premium member'
        @premium_member_col      = i
      when 'attendee tags'
        @attendee_tags_col       = i
      when 'pn filters', 'notification filters', 'notification filter'
        @pn_filters_col          = i
      else
        nonexistant_columns << f
        @error_count += 1
      end

    end

    if nonexistant_columns.length > 0
      generate_columns_error_log(nonexistant_columns)
      raise "The following columns are incorrectly named: #{nonexistant_columns.inspect}".red
    end

    colvals = []
    total_rows = oo.last_row - 1
    job.update!(total_rows:total_rows, status:'Processing Rows')

    2.upto(oo.last_row) do |row|

      job.row = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0

      0.upto(fieldcount-1) do |colnum|

        #collect value, if any
        if oo.cell(row,colLetter[colnum])==nil
          colvals[colnum] = ''
        else
          colvals[colnum] = oo.cell(row,colLetter[colnum])
        end

      end #col

      valueFor = ->(index, default=nil) { index.nil? ? default : colvals[index] }

      first_name          = valueFor[@first_name_col]
      last_name           = valueFor[@last_name_col]
      honor_prefix        = valueFor[@honor_prefix_col]
      honor_suffix        = valueFor[@honor_suffix_col]
      title               = valueFor[@title_col]
      company             = valueFor[@company_col]
    #  temp_photo_filename = valueFor[@temp_photo_filename_col]
      biography           = valueFor[@biography_col]
      business_unit       = valueFor[@business_unit_col]

      if @business_phone_col
        business_phone = is_number(colvals[@business_phone_col]) ? colvals[@business_phone_col].to_i.to_s : colvals[@business_phone_col]
      else
        business_phone = nil
      end

      if @mobile_phone_col
        mobile_phone = is_number(colvals[@mobile_phone_col]) ? colvals[@mobile_phone_col].to_i.to_s : colvals[@mobile_phone_col]
      else
        mobile_phone = nil
      end

      email = valueFor[@email_col]

      if @registration_id_col
        registration_id = is_number(colvals[@registration_id_col]) ? colvals[@registration_id_col].to_i.to_s : colvals[@registration_id_col]
      else
        registration_id = nil
      end

      if @username_col
        username = is_number(colvals[@username_col]) ? colvals[@username_col].to_i.to_s : colvals[@username_col]
      else
        username = nil
      end

      if @password_col
        password = is_number(colvals[@password_col]) ? colvals[@password_col].to_i.to_s : colvals[@password_col]
      else
        password = nil
      end

      #split out the registered sessions into an array
      if @registered_sessions_col
        registered_sessions = colvals[@registered_sessions_col].to_s.split(',').map { |a| a.strip }
      else
        registered_sessions = []
      end

      if @assignment_col
        assignment = is_number(colvals[@assignment_col]) ? colvals[@assignment_col].to_i.to_s : colvals[@assignment_col]
      else
        assignment = nil
      end

      custom_filter_1 = valueFor[@custom_filter_1]
      custom_filter_2 = valueFor[@custom_filter_2]
      custom_filter_3 = valueFor[@custom_filter_3]

      # if @custom_fields_1
      #    custom_fields_1 = is_number(colvals[@custom_fields_1_col]) ? colvals[@custom_fields_1_col].to_i.to_s : colvals[@custom_fields_1_col]
      # else
      #    custom_fields_1 = nil
      # end
      custom_fields_1 = colvals[@custom_fields_1_col]    
      custom_fields_2 = valueFor[@custom_fields_2]
      custom_fields_3 = valueFor[@custom_fields_3]
      
      travel_info = valueFor[@travel_info]
      table_assignment = valueFor[@table_assignment]
	  city = valueFor[@city]
 	  state = valueFor[@state]
 	  country = valueFor[@country]
    premium_member = valueFor[@premium_member_col]

      messaging_opt_out   = @messaging_opt_out   ? colvals[@messaging_opt_out].to_i : 1
      app_listing_opt_out = @app_listing_opt_out ? colvals[@app_listing_opt_out].to_i : 1
      game_opt_out        = @game_opt_out        ? colvals[@game_opt_out].to_i : 1

      if @attendee_tags_col
        tags_safeguard = colvals[@attendee_tags_col]
        attendee_tags = colvals[@attendee_tags_col]
          .split('^^').map { |a| a.strip }
          .inject([]) {|ary, set| ary << set.split('||').map { |a| a.strip }}
      else
        attendee_tags = []
      end

      processed_filters = pn_filter_processor.process_filters(
        custom_filter_1, # this could be based on a database stored column_name
        valueFor[@pn_filters_col]
      )

      pn_filters = unless processed_filters[:updated_filters].blank?
                     processed_filters[:updated_filters].to_s
                   else 
                     nil
                   end
      
      processed_filters[:errors].each do |error|
        warning_msg = "Row #{ job.row }: " + error
        job.warnings = job.warnings.blank? ? warning_msg 
                                           : job.warnings + '||' + warning_msg
        job.write_to_file
      end

      attendee_attrs = {
        event_id:            EVENT_ID,
        first_name:          first_name,
        last_name:           last_name,
        honor_prefix:        honor_prefix,
        honor_suffix:        honor_suffix,
        title:               title,
        company:             company,
        biography:           biography,
        business_unit:       business_unit,
        business_phone:      business_phone,
        mobile_phone:        mobile_phone,
        email:               email,
        account_code:        registration_id,
        username:            username,
        password:            password,
        assignment:          assignment,
        custom_filter_1:     custom_filter_1,
        custom_filter_2:     custom_filter_2,
        custom_filter_3:     custom_filter_3,
        custom_filter_1:     custom_filter_1,
        custom_fields_1:     custom_fields_1,
        custom_fields_2:     custom_fields_2,
        custom_fields_3:     custom_fields_3,
        travel_info:         travel_info,
        table_assignment:    table_assignment,
		    city:                city,
		    state:               state,
		    country:             country,
        premium_member:      premium_member,
        messaging_opt_out:   messaging_opt_out,
        app_listing_opt_out: app_listing_opt_out,
        game_opt_out:        game_opt_out,
        tags_safeguard:      tags_safeguard,
        pn_filters:          pn_filters
      }

      if !registration_id.blank?
        attendees = Attendee.where(account_code:registration_id,event_id:EVENT_ID)
      elsif !email.blank?
        attendees = Attendee.where(email:email,event_id:EVENT_ID)
      else
        attendees = []
      end

      if attendees.length==0
        puts "creating attendee #{first_name} #{last_name}"
        delta_report.before = {}
        attendee = Attendee.create(attendee_attrs)
      elsif attendees.length>=1
        puts "updating attendee #{first_name} #{last_name}"
        attendee = attendees[0]
        delta_report.before = populate_hash_for_delta[ {}, attendee ]
        attendee.update!(attendee_attrs)
      else
        puts "problem with attendee with email #{email} account_code #{registration_id}"
      end

      current_codes = []

      SessionsAttendee.where(attendee_id:attendee.id).each do |sa|
        unless sa.session_code.blank?
          current_codes << sa.session_code
        else
          current_codes << sa.session.session_code
        end
      end

      registered_sessions = registered_sessions - current_codes

      registered_sessions.each do |session_code|

        session = Session.where(event_id:EVENT_ID, session_code:session_code).first
        if (session==nil); next end

        puts "creating/updating association between #{session.session_code} and #{attendee.first_name} #{attendee.last_name}"

        # we know this is the right event_id by implication of attendee_id
        # At some point, our system could receive records which had session_codes
        # and attendee_ids, but not session_ids. So this avoids duplication of 
        # records, and appends the missing session_id
        session_attendee = SessionsAttendee.where(
          session_code: session.session_code,
          attendee_id:  attendee.id
        ).first_or_initialize

        # only session_id and flag should need to be updated
        session_attendee.update!(
          session_id:   session.id,
          attendee_id:  attendee.id,
          session_code: session.session_code,
          flag:         'cms_external_api'
        )

        # this is redundant most likely
        session_attendee.save

      end

      BoothOwner.where(attendee_id:attendee.id).destroy_all

      if !company.blank?
        exhibitors = Exhibitor.where(event_id:EVENT_ID,company_name:company)
        if exhibitors.length > 0
          puts "---creating link between attendee #{attendee.id} and #{company}----"
          exhibitor = exhibitors.first
          BoothOwner.create(exhibitor_id:exhibitor.id,attendee_id:attendee.id)
          attendee.update!(attendee_type_id:exhibitor_attendee_type_id)
        else
          attendee.update!(attendee_type_id:AttendeeType.where(name:"Standard Attendee").first.id)
          puts "Exhibitor with name #{company} does not exist; no association created."
        end
      else
        attendee.update!(attendee_type_id:AttendeeType.where(name:"Standard Attendee").first.id)
      end

      attendee.update_tags attendee_tags, 'attendee'

      # this extra find because we need to reload the attendee and its relations. Otherwise
      # we get issues where queries on the attendee don't find new relations in some cases
      delta_report.after = populate_hash_for_delta[ {}, Attendee.find(attendee.id) ] if attendee
      delta_report.compare

    end #row
  end #sheet

  job.update!(status:'Generating Delta Report')
  job.write_to_file

  delta_path = delta_report.export(
    "upload_attendees_delta_#{Time.now.strftime('%Y%m%d%H%M%S')}.xlsx",
    EVENT_ID
  ).to_s.split('public')[1]

  job.add_info "<a class='btn btn-success btn-sm' href='#{delta_path}'>Change Report</a>"
} # Job.start

