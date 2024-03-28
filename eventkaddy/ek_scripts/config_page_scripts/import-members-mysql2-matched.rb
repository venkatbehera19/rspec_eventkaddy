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
require 'pry'

ActiveRecord::Base.establish_connection(adapter:"mysql2", host:@db_host, username:@db_user, password:@db_pass, database:@db_name)

def generate_columns_error_log(nonexistant_columns)
  @error_log += "The following columns are incorrectly named:\n\n"
  nonexistant_columns.each {|c| @error_log += "\t" + c + "\n"}
  new_filename = "error_log.txt"
  filepath     = Rails.root.join('public','organization_data', ORG_ID.to_s,'error_logs', new_filename)
  dirname      = File.dirname(filepath)
  @error_log   = "Refresh Error Report\n\nNumber of Errors: #{@error_count}\n\n\n\n\n" + @error_log
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  File.open(filepath, "w", 0777) { |file| file.puts @error_log }
end

EVENT_ID         = ARGV[0]
SPREADSHEET_FILE = ARGV[1]
JOB_ID           = ARGV[2]
USER_ID          = ARGV[3]
ORG_ID           = ARGV[4]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:SPREADSHEET_FILE, row:0, status:'In Progress')
end

job.start {

  @error_count     = 0
  @error_log       = ''

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

  organization = Organization.find_by(id: ORG_ID)
  if organization.blank?
    raise "Organization not found"
  end

  member_role = Role.find_by_name('Member')

  if member_role.blank?
    raise 'Member Role Not Found'
  end

  delta_report = DeltaReport.new({:first_name           => :string,
                                  :last_name            => :string,
                                  :title                => :string,
                                  :email                => :string,
                                  :password             => :string,
  }, { 
    treat_nil_and_blank_string_same: true,
    strip_strings_before_comparing:  true,
    ignore_linebreaks:               true,
    treat_falsey_values_equal:       true,
    user_id: USER_ID
  })

  # keys must match delta_report schema (headers), or they will not show up in xlsx output
  populate_hash_for_delta = ->(hash, model) {
    hash.merge({
      first_name:           model.first_name,
      last_name:            model.last_name,
      title:                model.title,
      email:                model.email,
      password:             model.password,

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

    puts fields.inspect + "\n"

    nonexistant_columns = []

    fields.each_with_index do |f, i|
      case f.downcase
      when 'first name'
        @first_name_col          = i

      when 'last name'
        @last_name_col           = i

      when 'title'
        @title_col               = i

      when 'email'
        @email_col               = i

      when 'password'
        @password_col            = i
      when 'is subscribed'
        @is_subscribed           = i
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
      title               = valueFor[@title_col]
      email               = valueFor[@email_col]
      password            = SecureRandom.hex(4)
      is_subscribed       = valueFor[@is_subscribed]
      is_subscribed       = is_subscribed.class != TrueClass && is_subscribed == 1

      user_attrs = {
        first_name:          first_name,
        last_name:           last_name,
        title:               title,
        email:               email,
        password:            password,
        is_subscribed:       is_subscribed,
      }

      user = User.find_by(email: email)
      
      if user.blank?
        puts "creating member #{first_name} #{last_name}"
        delta_report.before = {}
        user = User.new(user_attrs)
      else 
        puts "updating member #{first_name} #{last_name}"
        delta_report.before = populate_hash_for_delta[ {}, user ]
        user.assign_attributes(user_attrs)
      end
      
      if user.save
        # add user-organization record
        UsersRole.find_or_create_by(role_id: member_role.id, user_id: user.id)
        UsersOrganization.find_or_create_by(user: user, organization: organization)
        delta_report.after = populate_hash_for_delta[ {}, user ]
        delta_report.compare({status: 'success', message: nil})
      else
        delta_report.after = populate_hash_for_delta[ {}, user]
        delta_report.compare({status: 'failed', message: user.errors.full_messages })
      end #if end to check attendee validation error

    end #row
  end #sheet

  job.update!(status:'Generating Delta Report')
  job.write_to_file
  delta_path = delta_report.export(
    "upload_member_delta_#{Time.now.strftime('%Y%m%d%H%M%S')}.xlsx",
    EVENT_ID
  ).to_s.split('public')[1]

  job.add_info "<a class='btn btn-success btn-sm' href='#{delta_path}'>Change Report</a>"
} # Job.start

