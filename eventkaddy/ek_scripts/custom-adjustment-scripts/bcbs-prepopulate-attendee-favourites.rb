###########################################
# Custom Adjustment Script
# Add Preassigned Favourites to all BCBS 2016 Attendees
###########################################

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)

def add_prefavourites(attendee_id)
  PREFAVOURITES.each {|p|
    SessionsAttendee.where(attendee_id:attendee_id, flag:'web', session_id:p[:session_id], session_code:p[:session_code]).first_or_create }
end

EVENT_ID = ARGV[0].to_i
JOB_ID   = ARGV[1].to_i

case EVENT_ID
when 77
  prefavourite_session_codes = [873,
                                874,
                                875,
                                876,
                                877,
                                878,
                                879,
                                880,
                                881,
                                882,
                                883,
                                884,
                                885,
                                886,
                                887,
                                888]
when 119
  prefavourite_session_codes = [10468,
                                10476,
                                10485,
                                10494,
                                10478,
                                10473,
                                10492,
                                10081,
                                10480,
                                10489,
                                10482,
                                10474,
                                10486,
                                10483,
                                10495,
                                10477]
when 161
  prefavourite_session_codes = [
    10850,
    10865,
    10866,
    10867,
    10868,
    10869,
    10870,
    10871,
    10854,
    10859,
    10861,
    10872,
    10873,
    10874
  ]
end

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'EK Database', row:0, status:'In Progress')
end

job.start {

  job.status  = 'Fetching data from API'
  job.write_to_file

  PREFAVOURITES = Session
    .select('id, session_code')
    .where(event_id:EVENT_ID, session_code:prefavourite_session_codes)
    .map {|session|
      { session_id:session.id, session_code:session.session_code }
    }

  attendee_ids = Attendee.where(event_id:EVENT_ID).pluck(:id)

  job.update!(total_rows:attendee_ids.length,
                        status:'Processing Rows')
  job.write_to_file

  attendee_ids.each {|a_id|
    job.row = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0
    add_prefavourites(a_id) }


  job.status  = 'Verifying no duplicate favourites.'
  job.write_to_file

  session_ids = PREFAVOURITES.map {|f| f[:session_id] }

  attendee_ids.each {|a_id|
    sas = SessionsAttendee.where(attendee_id:a_id, session_id:session_ids)
    next if sas.length <= session_ids.length
    session_ids.each {|s_id|
      sessions_attendees = sas.where(attendee_id:a_id, session_id:s_id)
      sessions_attendees.last.delete if sessions_attendees.length > 1}
  }
}
