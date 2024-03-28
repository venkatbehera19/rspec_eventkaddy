require_relative '../settings.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

EVENT_ID           = ARGV[0]
JOB_ID             = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:@db_name, row:0, status:'In Progress')
end

job.start {

  SESSION_FILE_IDS = JSON.parse( ARGV[2] ) # here in case of failure to parse

  SessionFile.where(event_id:EVENT_ID).update_all(unpublished: true)
  sf = SessionFile.where(event_id:EVENT_ID, id: SESSION_FILE_IDS )
  sf.update_all(unpublished: false)

  sessions = Session.where(event_id: EVENT_ID)

  job.update!(total_rows:sessions.length, status:'Processing Rows')
  sessions.each do |session|
    job.row = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0
    session.update_session_file_urls_json
  end

}

