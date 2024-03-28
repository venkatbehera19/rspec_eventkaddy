require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

def test_email event_id, email, first, last
  speaker = Speaker.where( event_id:event_id, email: email ).first_or_create
  speaker.update! first_name: first, last_name: last
  EmailsQueue.create( event_id: event_id, email_type_id: 1, email: email, sent: 0, status: 'pending', speaker_id: speaker.id)
end

def test_attendee_email event_id, email, first, last
  attendee = Attendee.where( event_id:event_id, email: email ).first_or_create
  attendee.update! first_name: first, last_name: last, username: email
  EmailsQueue.create( event_id: event_id, email_type_id: 1, email: email, sent: 0, status: 'pending', attendee_id: attendee.id)
end

def test_exhibitor_email event_id, email, company_name=nil
  exhibitor = Exhibitor.where( event_id:event_id, email: email ).first_or_create
  # exhibitor.update! company_name: company_name
  EmailsQueue.create( event_id: event_id, email_type_id: 1, email: email, sent: 0, status: 'pending', exhibitor_id: exhibitor.id)
end

def test_exhibitor_staff_email event_id, email, company_name=nil
  exhibitor = ExhibitorStaff.where( event_id:event_id, email: email ).first_or_create
  # exhibitor.update! company_name: company_name
  EmailsQueue.create( event_id: event_id, email_type_id: 1, email: email, sent: 0, status: 'pending', exhibitor_staff_id: exhibitor.id)
end


# test_email 225, "kyra.simon@bcbsa.com", "Kyra", "Simon"
# test_email 225, "ed.gallant@eventkaddy.com", "Ed", "Gallant"
# test_attendee_email 224, "ed.gallant@eventkaddy.com", "Ed", "Gallant"

# test_exhibitor_email 224, "ed.gallant@eventkaddy.com", "Eventkaddy"

# regexp for quote all words in string
# '<,'>s/\v([^ ]+)/"\1"/gc

# test_exhibitor_email 224, "cikens@livongo.com"
# test_exhibitor_email 224, "nmarotta@livongo.com"

# for emails sent through other means, a special way to exclude them
def mark_attendee_password_email_sent event_id, email
	attendee = Attendee.where( event_id:event_id, email: email ).first
	if attendee
		EmailsQueue.create( event_id: event_id, email_type_id: 1, email: email, sent: 1, status: 'active', attendee_id: attendee.id)
	end
end


#[ "Kevin.Risdal@bcbsa.com", "Grayling.Lucas@bcbsa.com", "pamela.vavra@bcbsa.com" ].each do |email|
	#mark_attendee_password_email_sent 224, email
#end
