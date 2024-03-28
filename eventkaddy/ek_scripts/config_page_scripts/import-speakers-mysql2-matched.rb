###########################################
# Ruby script to import speaker data from
# spreadsheet into EventKaddy CMS
###########################################

# this loads rails, active record, and the dev database
require_relative '../../config/environment.rb'

# abtracted methods shared by xlsx imports
require_relative '../import.rb'
require_relative '../delta_report.rb'

# spreadsheet gem
require 'roo'

# these two lines allow you to change the database that was connected
# to by loading environement.rb;
require_relative '../settings.rb'
Import.connect_to_database

EVENT_ID         = ARGV[0]
SPREADSHEET_PATH = ARGV[1]
JOB_ID           = ARGV[2]
USER_ID          = ARGV[3]

# EVENT_ID         = 20
# SPREADSHEET_PATH = '/Users/edwardgallant/working_copies/lodestar/eventkaddy/ek_scripts/config_page_scripts/s.xlsx'
# JOB_ID           = Job.try_to_create_job(name: "my test", event_id:EVENT_ID)[:job_id]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:SPREADSHEET_PATH, row:0, status:'In Progress')
end

job.start {

  speaker_import = Import.new({
    spreadsheet_path: SPREADSHEET_PATH,
    possible_fields: [
      ['speaker code'],
      ['honor prefix'], ['first name'], ['middle initial'], ['last name'],
      ['honor suffix'],
      ['title'], ['company'], ['biography'],
      ['home phone'], ['work phone'], ['mobile phone'], ['email'], ['password'], ['fax'],
      ['city'], ['state'], ['country'], ['zip'], ['address'],
      ['speaker id'] ]
  })

  job.update!(total_rows:speaker_import.spreadsheet.last_row - 1,
                        status:'Processing Rows')

  # should I include password in the delta? Not sure. Don't remember if I do it
  # already for exhibitor either
  delta_report = DeltaReport.new [:speaker_code,:honor_prefix,:first_name,:middle_initial,:last_name,:honor_suffix,:title,:company,:biography,:home_phone,:work_phone,:mobile_phone,:email,:fax,:city,:state,:country,:zip,:address], { treat_nil_and_blank_string_same: true, strip_strings_before_comparing: true, ignore_linebreaks: true, user_id: USER_ID }

  populate_hash_for_delta = ->(hash, model) {
    hash.merge(
      [ :speaker_code, :honor_prefix, :first_name, :middle_initial, :last_name, :honor_suffix, :title, :company, :biography, :home_phone, :work_phone, :mobile_phone, :email, :fax, :city, :state, :country, :zip, :address1
      ].each_with_object({}) {|col, memo| memo[col] = model.send(col) }
    )
  }

  speaker_import.step_through_rows do |row_number|

    job.row = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0

    speaker_attrs = {
      event_id:       EVENT_ID,
      speaker_code:   speaker_import.maybeIntValueToString( 'speaker code' ),
      honor_prefix:   speaker_import.valueFor( 'honor prefix' ),
      honor_suffix:   speaker_import.valueFor( 'honor suffix' ),
      first_name:     speaker_import.valueFor( 'first name' ),
      middle_initial: speaker_import.valueFor( 'middle initial' ),
      last_name:      speaker_import.valueFor( 'last name' ),
      title:          speaker_import.valueFor( 'title' ),
      company:        speaker_import.valueFor( 'company' ),
      biography:      speaker_import.valueFor( 'biography' ),
      home_phone:     speaker_import.maybeIntValueToString( 'home phone' ),
      work_phone:     speaker_import.maybeIntValueToString( 'work phone' ),
      mobile_phone:   speaker_import.maybeIntValueToString( 'mobile phone' ),
      email:          speaker_import.valueFor( 'email' ),
      fax:            speaker_import.maybeIntValueToString( 'fax' ),
      city:           speaker_import.valueFor( 'city' ),
      state:          speaker_import.valueFor( 'state' ),
      country:        speaker_import.valueFor( 'country' ),
      zip:            speaker_import.maybeIntValueToString( 'zip' ),
      address1:       speaker_import.valueFor( 'address' )
    }
    puts speaker_attrs
    delta_report.before = {}

    speakers = if speaker_attrs[:speaker_code].blank?
                 Speaker.where(email:speaker_attrs[:email], event_id:EVENT_ID)
               else
                 Speaker.where(speaker_code:speaker_attrs[:speaker_code], event_id:EVENT_ID)
               end

    if speakers.length == 0
      speaker = Speaker.new(email:speaker_attrs[:email], event_id:EVENT_ID)
    else
      speaker = speakers.first
      delta_report.before = populate_hash_for_delta[ {}, speaker ]
    end

    speaker.update! speaker_attrs

    if speaker.speaker_code.blank?
      speaker.update! speaker_code:"ourcode" + speaker.id.to_s
    end

    speaker_import.valueFor( 'password' ) {|pass| User.first_or_create_for_speaker( speaker, pass )}

    delta_report.after = populate_hash_for_delta[ {}, speaker ]
    delta_report.compare
  end

  job.update!(status:'Generating Delta Report')
  job.write_to_file

  delta_path = delta_report.export(
    "upload_speakers_delta_#{Time.now.strftime('%Y%m%d%H%M%S')}.xlsx",
    EVENT_ID
  ).to_s.split('public')[1]

  job.add_info "<a class='btn btn-success btn-sm' href='#{delta_path}'>Change Report</a>"

}


