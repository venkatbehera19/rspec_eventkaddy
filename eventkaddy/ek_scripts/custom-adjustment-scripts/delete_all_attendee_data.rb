require_relative '../settings.rb'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

event_id    = 241
attendee_ids = Attendee.select('id').where(event_id:event_id).pluck(:id)

attendee_ids.each_slice(1000).to_a.each_with_index do |ids, i|
  puts "deleting records #{i * 1000} - #{i * 1000 + ids.length}"
  [SessionsAttendee, ExhibitorAttendee, AttendeesScavengerHuntItem, AttendeesAppBadge, AttendeesAppBadgeTask, SurveyResponse, TagsAttendee].each do |m|
    m.where(attendee_id: ids).delete_all
  end
end

Attendee.where(event_id:event_id).delete_all
