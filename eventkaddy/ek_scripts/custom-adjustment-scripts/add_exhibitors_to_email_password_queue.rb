
require_relative '../settings.rb'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

event_id                             = ARGV[0]
email_type_id                        = EmailType.where(name:'send_password').first.id
emails_added                         = 0
exhibitors_without_emails              = 0
exhibitors_already_have_email_in_queue = 0

Exhibitor.where(event_id:event_id).each do |exhibitor|
	unless exhibitor.email.blank?
    unless EmailsQueue.where(event_id: event_id, email_type_id: email_type_id, email: exhibitor.email, exhibitor_id: exhibitor.id).first
      EmailsQueue.create(
        event_id:      event_id,
        email_type_id: email_type_id,
        email:         exhibitor.email,
        sent:          0,
        status:        'pending',
        exhibitor_id:   exhibitor.id
      )
			emails_added += 1

	 		puts "Exhibitor #{exhibitor.id} #{exhibitor.company_name} with email #{exhibitor.email} added to the queue"
    else
      exhibitors_already_have_email_in_queue += 1
    end
  else
    exhibitors_without_emails += 1
	end
end

puts "\n\n"
puts "#{emails_added} emails added to the queue."
puts "#{exhibitors_without_emails} exhibitors did not have an email to send to."
puts "#{exhibitors_already_have_email_in_queue} exhibitors already had an email in the queue for this event."

# EmailsQueue.destroy_all
# EmailsQueue.where(event_id:223).destroy_all
