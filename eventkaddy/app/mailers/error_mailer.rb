class ErrorMailer < ApplicationMailer
  default from: "support@eventkaddy.net"

  def mail(headers = {}, &block)
    headers[:from] = "#{@event.mailer_name ? @event.mailer_name : @event.name ? @event.name : 'Support'} <support@eventkaddy.net>"
    super(headers, &block)
  end
  
  def external_api_import_mailer error_message, error_backtrace
    @error_message   = error_message
    @error_backtrace = error_backtrace
    mail(to: "dbergevin@eventkaddy.com", subject: 'Your Script Encountered An Error')  
  end
end