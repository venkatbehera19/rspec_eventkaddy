
require_relative '../settings.rb'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

event_id                                    = ARGV[0]
email_type_id                               = EmailType.where(name:'send_password').first.id
emails_added                                = 0
exhibitor_staff_without_emails              = 0
exhibitor_staff_already_have_email_in_queue = 0

ExhibitorStaff.where(event_id:event_id).each do |exhibitor_staff|
	unless exhibitor_staff.email.blank?
    unless EmailsQueue.where(event_id: event_id, email_type_id: email_type_id, email: exhibitor_staff.email, exhibitor_staff_id: exhibitor_staff.id).first
      EmailsQueue.create(
        event_id:      event_id,
        email_type_id: email_type_id,
        email:         exhibitor_staff.email,
        sent:          0,
        status:        'pending',
        exhibitor_staff_id:   exhibitor_staff.id
      )
			emails_added += 1

	 		puts "Exhibitor Staff #{exhibitor_staff.id} with email #{exhibitor_staff.email} added to the queue"
    else
      exhibitor_staff_already_have_email_in_queue += 1
    end
  else
    exhibitor_staff_without_emails += 1
	end
end

puts "\n\n"
puts "#{emails_added} emails added to the queue."
puts "#{exhibitor_staff_without_emails} exhibitors staff did not have an email to send to."
puts "#{exhibitor_staff_already_have_email_in_queue} exhibitors staff already had an email in the queue for this event."

# EmailsQueue.destroy_all
# EmailsQueue.where(event_id:223).destroy_all
