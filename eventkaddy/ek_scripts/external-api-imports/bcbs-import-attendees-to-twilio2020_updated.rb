require 'net/http'
require 'open-uri'
require 'active_record'
require 'timeout'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'

# Download the helper library from https://github.com/twilio/authy-ruby
require 'authy'
Authy.api_key = TWILIO_KEY
Authy.api_uri = 'https://api.authy.com'

event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'Twilio', row:0, status:'In Progress')
end

if JOB_ID && event_id

  job.start {

    job.status  = 'Connecting to Twilio'
    job.write_to_file

    attendees = Attendee.where(event_id:event_id)
    job.update!(total_rows:attendees.length, status:'Processing Rows')
    job.write_to_file

    attendees.each do |attendee|
      if attendee.authy_id.blank?
        if !attendee.custom_fields_1.blank?
          job.row    = job.row + 1
          authy = Authy::API.register_user(:email => attendee.email, :cellphone => attendee.custom_fields_1, :country_code => attendee.custom_fields_3)
          if authy.ok?
            puts "id: #{authy.id}"
            attendee.update!(authy_id:authy.id)
          else
            puts "errors: #{authy.errors}"
            puts "#{attendee.first_name} #{attendee.last_name}"
          end
        end
      end
    end
  }
end
