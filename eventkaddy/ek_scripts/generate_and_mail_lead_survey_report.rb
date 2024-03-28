require_relative './settings.rb'
require 'active_record'
require_relative '../config/environment.rb'
require_relative '../app/services/generate_lead_survey_report.rb'

Eventkaddy::Application.configure do
  config.action_mailer.smtp_settings = {
    :address   => "smtp.mandrillapp.com",
    :port      => 587,
    :user_name => 'dave@soma-media.com',
    :password  => ENV['MAILER_PASS']
  }
end


ActiveRecord::Base.establish_connection( adapter: "mysql2", host: @db_host, username: @db_user, password: @db_pass, database: @db_name )

attendee_id = ARGV[0]
attendee    = Attendee.find attendee_id
event       = Event.find attendee.event_id

subject_text = "Your Lead Surveys Report"
content      = "Hello #{attendee.full_name},<br><br>

Please find attached your lead surveys report for #{event.name}<br><br><br>"

path = './public' + GenerateLeadSurveyReport.new(
  attendee_id,
  attendee.event_id,
  "lead_survey_report_for_#{attendee.full_name.gsub(' ', '_')}.xlsx"
).call.to_s.split('public')[1]

puts path.inspect.red

filename = File.basename(path)

AttendeeMailer.email_lead_survey_report(
  attendee.notes_email,
  event,
  filename,
  subject_text,
  content,
  path: path
).deliver
