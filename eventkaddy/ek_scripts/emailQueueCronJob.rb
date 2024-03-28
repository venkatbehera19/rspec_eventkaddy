###########################################
# Send emails until sending limit reached
###########################################

require_relative './settings.rb'
require_relative '../config/environment.rb'


ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)
# ActionMailer::Base.delivery_method = :smtp
# ActionMailer::Base.smtp_settings = { :address => "smtp.mandrillapp.com", :port => 587, :user_name => 'dave@soma-media.com', :password => '#{mandrill_password}' }

Eventkaddy::Application.configure do
  config.action_mailer.smtp_settings = {
    :address   => "smtp.mandrillapp.com",
    :port      => 587,
    :user_name => 'dave@soma-media.com',
    :password  => ENV['MAILER_PASS']
  }
end

# Do I want to make a new email type, or do I want to base things off the existence of the id?
def set_and_email_password email

  # alternatively to elsif, we could do a series of ifs so that multiple ids
  # all get emails... but I think that's a strange case to handle for now
  if email.attendee_id
    # where -> first is better than find, because find raises an exception for
    # id that doesn't exist
    attendee = Attendee.where(id:email.attendee_id).first
    if attendee
      puts "Sending attendee set password email to #{ email.email } for attendee #{attendee.id} #{attendee.first_name} #{attendee.last_name}"
      email.update!(sent:true, status: 'active')
      if email.event_id == 222
        AttendeeMailer.fiserv_set_and_email_password(email, attendee).deliver
      elsif email.event_id == 223
        AttendeeMailer.bcbs_set_and_email_password(email, attendee).deliver
      else
        AttendeeMailer.set_and_email_password(email, attendee).deliver
      end
    else
      email.update!(sent:false, status: 'attendee no longer exists')
      puts "Attendee with email #{email.email} no longer exists."
    end

  elsif email.speaker_id
    speaker = Speaker.where(id:email.speaker_id).first
    if speaker
      puts "Sending speaker set password email to #{ email.email } for speaker #{speaker.id} #{speaker.first_name} #{speaker.last_name}"
      email.update!(sent:true, status: 'active')
      # for now, always resets the password. Maybe in the future we might want
      # to let users keep their old password if they had one
      # I am surprised that this does not need a .new(), since the method is
      # not self.set_and_email_password rails must do some magic for you,
      # although it's unexpected behaviour
      begin
        if email.event_id == 223
          SpeakerMailer.set_and_email_password_bcbsa(email, speaker, "2019 FEP Finance and Audit Speaker Portal").deliver
        elsif email.event_id == 224
          SpeakerMailer.set_and_email_password_bcbsa(email, speaker, "2019 FEP Field Service Planning Conference Speaker Portal").deliver
        elsif email.event_id == 225
          SpeakerMailer.set_and_email_password_bcbsa(email, speaker, "2019 FEP Plan Operations Conference Speaker Portal").deliver
        else
          SpeakerMailer.set_and_email_password(email, speaker).deliver
        end
      rescue StandardError => e
        # rescue if something went wrong, like User creation raised an exception
        email.update!(sent:false, status: e.message)
      end
    else
      email.update!(sent:false, status: 'speaker no longer exists')
      puts "Speaker with email #{email.email} no longer exists."
    end
  elsif email.exhibitor_id
    exhibitor = Exhibitor.where(id:email.exhibitor_id).first
    if exhibitor
      puts "Sending exhibitor set password email to #{ email.email } for exhibitor #{exhibitor.id} #{exhibitor.company_name}"
      email.update!(sent:true, status: 'active')
      begin
        if email.event_id == 224
          ExhibitorMailer.set_and_email_password_bcbsa(email, exhibitor, "2019 FEP Field Service Planning Conference Exhibitor Portal").deliver
        else
          ExhibitorMailer.set_and_email_password(email, exhibitor).deliver
        end
      rescue StandardError => e
        # rescue if something went wrong, like User creation raised an exception
        email.update!(sent:false, status: e.message)
      end
    else
      email.update!(sent:false, status: 'exhibitor no longer exists')
      puts "Exhibitor with email #{email.email} no longer exists."
    end
  elsif email.exhibitor_staff_id
    exhibitor_staff = ExhibitorStaff.where(id:email.exhibitor_staff_id).first
    if exhibitor_staff
      puts "Sending exhibitor staff set password email to #{ email.email } for exhibitor staff #{exhibitor_staff.id}"
      email.update!(sent:true, status: 'active')
      begin
        ExhibitorMailer.send_credentials_to_staff(email, exhibitor_staff).deliver
      rescue StandardError => e
        # rescue if something went wrong, like User creation raised an exception
        email.update!(sent:false, status: e.message)
      end
    else
      email.update!(sent:false, status: 'exhibitor staff no longer exists')
      puts "Exhibitor Staff with email #{email.email} no longer exists."
    end
  end

end


def try_sending_generic_email email

  if email.attendee_id
    # find_by -> first is better than find, because find raises an exception for
    # id that doesn't exist
    attendee = Attendee.find_by id:email.attendee_id
    if attendee
      puts "Sending email to #{ email.email } for attendee #{attendee.id} #{attendee.first_name} #{attendee.last_name}"
      email.update!(sent:true, status: 'active')
      GenericMailer.new_email(email, attendee).deliver
    else
      email.update!(sent:false, status: 'attendee no longer exists')
      puts "Attendee with email #{email.email} no longer exists."
    end

  elsif email.speaker_id
    speaker = Speaker.where(id:email.speaker_id).first
    if speaker
      puts "Sending speaker set password email to #{ email.email } for speaker #{speaker.id} #{speaker.first_name} #{speaker.last_name}"
      email.update!(sent:true, status: 'active')
      GenericMailer.new_email(email, speaker).deliver
    else
      email.update!(sent:false, status: 'speaker no longer exists')
      puts "Speaker with email #{email.email} no longer exists."
    end
  elsif email.exhibitor_id
    exhibitor = Exhibitor.where(id:email.exhibitor_id).first
    if exhibitor
      puts "Sending exhibitor set password email to #{ email.email } for exhibitor #{exhibitor.id} #{exhibitor.company_name}"
      email.update!(sent:true, status: 'active')
      GenericMailer.new_email(email, exhibitor).deliver
    else
      email.update!(sent:false, status: 'exhibitor no longer exists')
      puts "Exhibitor with email #{email.email} no longer exists."
    end
  elsif email.exhibitor_staff_id
    exhibitor_staff = ExhibitorStaff.where(id:email.exhibitor_staff_id).first
    if exhibitor_staff
      puts "Sending exhibitor staff set password email to #{ email.email } for exhibitor staff #{exhibitor_staff.id}"
      email.update!(sent:true, status: 'active')
      GenericMailer.new_email(email, exhibitor_staff).deliver
    else
      email.update!(sent:false, status: 'exhibitor staff no longer exists')
      puts "Exhibitor Staff with email #{email.email} no longer exists."
    end
  end
end

def send_generic_email email
  current_time = Time.now.utc
  if email.deliver_later
    active_time = Time.parse("#{email.active_time.strftime('%Y-%m-%d %H:%M:%S')}Z")
    if active_time <= current_time
      try_sending_generic_email email
    end
  else
    try_sending_generic_email email
  end
end

def try_sending_organization_email email
  user = User.find_by(id: email.user_id)
  if user
    puts "Sending email to #{ email.email } for user #{user.id} #{user.first_name} #{user.last_name}"
    email.update!(sent:true, status: 'active')
    OrganizationMailer.new_email(email).deliver
  else
    email.update!(sent:false, status: 'user no longer exists')
    puts "User with email #{email.email} no longer exists."
  end
end

def send_organization_email email
  current_time = Time.now.utc
  if email.deliver_later
    active_time = Time.parse("#{email.active_time.strftime('%Y-%m-%d %H:%M:%S')}Z")
    if active_time <= current_time
      try_sending_organization_email email
    end
  else
    try_sending_organization_email email
  end
end

send_password_type_id = EmailType.find_by(name:'send_password').id
send_generic_email_id = EmailType.find_by(name:'send_generic_email').id
send_organization_email_id = EmailType.find_by(name: 'organization_email').id

# For testing:
# EmailsQueue.where(sent:false, status: 'pending').order(created_at: :desc).limit(2).each do |email|

EmailsQueue.where(sent:false, status: 'pending').limit(20).each do |email|

  case email.email_type_id
  when send_password_type_id
    set_and_email_password email
  when send_generic_email_id
    send_generic_email email
  else
    raise "EmailQueue Error: email_type_id not found"
  end
end


OrganizationEmailsQueue.where(sent:false, status: 'pending').limit(20).each do |email|
  send_organization_email(email) if email.email_type_id
end

