require_relative '../settings.rb'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

event_id                              = ARGV[0]
email_type_id                         = EmailType.where(name:'send_password').first.id
emails_added                          = 0
attendees_without_emails              = 0
attendees_already_have_email_in_queue = 0

Attendee.where(event_id:event_id).each do |attendee|
# Attendee.where(event_id:event_id, last_name:'Kaddy').each do |attendee|
	unless attendee.email.blank?
    unless EmailsQueue.where(event_id: event_id, email_type_id: email_type_id, email: attendee.email, attendee_id: attendee.id).first
      EmailsQueue.create(
        event_id:      event_id,
        email_type_id: email_type_id,
        email:         attendee.email,
        sent:          0,
        status:        'pending',
        attendee_id:   attendee.id
      )
			emails_added += 1

	 		puts "Attendee #{attendee.id} #{attendee.first_name} #{attendee.last_name} with email #{attendee.email} added to the queue"
    else
      attendees_already_have_email_in_queue += 1
    end
  else
    attendees_without_emails += 1
	end
end

puts "\n\n"
puts "#{emails_added} emails added to the queue."
puts "#{attendees_without_emails} attendees did not have an email to send to."
puts "#{attendees_already_have_email_in_queue} attendees already had an email in the queue for this event."

# EmailsQueue.destroy_all
