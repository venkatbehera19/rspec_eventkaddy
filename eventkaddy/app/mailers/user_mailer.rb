require 'digest/sha2'

class UserMailer < ActionMailer::Base
  default from: "support@eventkaddy.net"
  layout 'bootstrap-mailer', only: [:registration_confirmation]

  def mail(headers = {}, &block)
    headers[:from] = "#{@event.mailer_name ? @event.mailer_name : @event.name ? @event.name : 'Support'} <support@eventkaddy.net>"
    super(headers, &block)
  end
  
  # we rely on devise reset password for any user normal resetting password functionality.
  def manual_password_change(user,password,new_account) # used only in defunct User#grantSpeakerPortalAccess
    @user = user
    @speaker = Speaker.where(email:@user.email).first
    @password = password
    @new_account = new_account
    @url  = "https://wvcspeakers.eventkaddy.net"

    mail(:to => user.email, :subject => "EventKaddy Password Reset")
  end

  def message_id_in_header(sent_at = Time.now)
    headers["Message-ID"] = "#{Digest::SHA2.hexdigest(sent_at.to_i.to_s)}@eventkaddy.net"
  end

  def registration_confirmation(event,user)
    @event = event
    @user  = user
    make_bootstrap_mail(to:@user.email, subject: "Please verify your email")
  end

  # def invitation_confirmation(user)
  #   @user = user
  #   make_bootstrap_mail(to:@user.email, subject: "Please verify your email")
  # end

end
