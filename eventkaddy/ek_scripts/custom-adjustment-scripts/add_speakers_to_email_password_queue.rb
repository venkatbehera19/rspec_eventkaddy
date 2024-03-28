require_relative '../settings.rb'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

event_id                             = ARGV[0]
email_type_id                        = EmailType.where(name:'send_password').first.id
emails_added                         = 0
speakers_without_emails              = 0
speakers_already_have_email_in_queue = 0

Speaker.where(event_id:event_id).each do |speaker|
	unless speaker.email.blank?
    unless EmailsQueue.where(event_id: event_id, email_type_id: email_type_id, email: speaker.email, speaker_id: speaker.id).first
      EmailsQueue.create(
        event_id:      event_id,
        email_type_id: email_type_id,
        email:         speaker.email,
        sent:          0,
        status:        'pending',
        speaker_id:   speaker.id
      )
			emails_added += 1

	 		puts "Speaker #{speaker.id} #{speaker.first_name} #{speaker.last_name} with email #{speaker.email} added to the queue"
    else
      speakers_already_have_email_in_queue += 1
    end
  else
    speakers_without_emails += 1
	end
end

puts "\n\n"
puts "#{emails_added} emails added to the queue."
puts "#{speakers_without_emails} speakers did not have an email to send to."
puts "#{speakers_already_have_email_in_queue} speakers already had an email in the queue for this event."

# EmailsQueue.destroy_all
# EmailsQueue.where(event_id:223).destroy_all
