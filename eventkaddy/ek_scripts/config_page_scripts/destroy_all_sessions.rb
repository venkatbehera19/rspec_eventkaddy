# ###########################################
# # Ruby script to delete sessions and their
# # associations, while tracking progress
# # via a Job
# ###########################################

# require_relative '../modules/memory_info.rb'
# # MemoryInfo.stats 'line 7 start of script'
# require_relative '../settings.rb'
# require 'active_record'
# require_relative '../../config/environment.rb'

# ActiveRecord::Base.establish_connection(
#   adapter:  "mysql2",
#   host:     @db_host,
#   username: @db_user,
#   password: @db_pass,
#   database: @db_name
# )

# EVENT_ID = ARGV[0]
# JOB_ID   = ARGV[1]

# if JOB_ID
# 	job = Job.find JOB_ID
# 	job.update!(original_file:'N/A', row:0, status:'In Progress')
# end

# @error_count     = 0
# @error_log       = ''

# # ModelInfo.get_dependent_destroy_associations(Session) 

# job.start {


#   # total_rows = oo.last_row - 1
#   total_rows = Session.where(event_id: EVENT_ID).count + Speaker.where(event_id: EVENT_ID).count

#   job.update!(total_rows:total_rows, status:'Processing Rows')

#   session_ids    = Session.where(event_id:EVENT_ID).pluck(:id)
#   speaker_ids    = Speaker.where(event_id:EVENT_ID).pluck(:id)
#   event_file_ids = []

#   event_file_ids << SpeakerFile.where(event_id:EVENT_ID).pluck(:event_file_id).reject { |f| f.nil? || f.blank? }
#   event_file_ids << SessionFileVersion.where(event_id:EVENT_ID).pluck(:event_file_id).reject { |f| f.nil? || f.blank? }
#   event_file_ids << Speaker.where(event_id:EVENT_ID).pluck(:photo_event_file_id).reject { |f| f.nil? || f.blank? }
#   event_file_ids << Speaker.where(event_id:EVENT_ID).pluck(:cv_event_file_id).reject { |f| f.nil? || f.blank? }
#   event_file_ids << Speaker.where(event_id:EVENT_ID).pluck(:fd_event_file_id).reject { |f| f.nil? || f.blank? }

#   event_file_ids.flatten!

#   EventFile.where(id:event_file_ids).delete_all

#   #delete related session rows
#   # could be refactored into a lambda which just takes the classes
#   SessionsTrackowner.where(session_id:session_ids).delete_all
#   SessionsSubtrack.where(session_id:session_ids).delete_all
#   SessionsSponsor.where(session_id:session_ids).delete_all
#   SessionsAttendee.where(session_id:session_ids).delete_all
#   SurveySession.where(session_id:session_ids).delete_all
#   TagsSession.where(session_id:session_ids).delete_all
#   SessionFile.where(event_id:EVENT_ID).delete_all
#   SessionFileVersion.where(event_id:EVENT_ID).delete_all
#   SessionAvRequirement.where(event_id:EVENT_ID).delete_all
#   SessionsRoomLayout.where(event_id:EVENT_ID).delete_all

#   # mainly we only need to delete_all on sessions_attendees, which
#   # sometimes has many 10,000s of records. After that it should be
#   # safe and quick to stay within rails callback territory. I maintain
#   # the above delete_alls as the cms has functioned with them for years
#   # now, and it seems the path of least surprise to only update this
#   # Session.where(event_id:EVENT_ID).destroy_all

#   #delete related Speaker rows
#   SpeakerTravelDetail.where(speaker_id:speaker_ids).delete_all
#   SpeakerPaymentDetail.where(speaker_id:speaker_ids).delete_all
#   SpeakerFile.where(event_id:EVENT_ID).delete_all
#   SessionsSpeaker.where(session_id:session_ids).delete_all

#   # Same as session
#   # Speaker.where(event_id:EVENT_ID).destroy_all


#   Session.
#     where(event_id: EVENT_ID).
#     find_each(batch_size: 100) do |s|
#       job.row = job.row + 1
#       job.write_to_file if job.row % job.rows_per_write == 0
#       s.destroy
#     end

#   Speaker.
#     where(event_id: EVENT_ID).
#     find_each(batch_size: 100) do |s|
#       job.row = job.row + 1
#       job.write_to_file if job.row % job.rows_per_write == 0
#       s.destroy
#     end

#   # MemoryInfo.stats 'line 502 after sheets'

#   #   job.update!(status:'Adding meta data to tags')
#   #   job.write_to_file

#   # MemoryInfo.stats 'line 496 after tags'
# } # Job.start
