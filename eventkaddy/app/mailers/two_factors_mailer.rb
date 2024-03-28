class TwoFactorsMailer < Devise::Mailer
  layout false
  default from: "support@eventkaddy.net"

  def mail(headers = {}, &block)
    headers[:from] = "#{@event.mailer_name ? @event.mailer_name : @event.name ? @event.name : 'Support'} <support@eventkaddy.net>"
    super(headers, &block)
  end

  def reset_two_factor_mail user
    @user = user
    mail(:to => @user.email, :subject => "Reset Two Factor Authentication ")
  end

end
