require 'net/http'
require 'open-uri'
require 'active_record'
require 'timeout'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'

# Download the helper library from https://github.com/twilio/authy-ruby
require 'authy'

# Your API key from twilio.com/console/authy/applications
# DANGER! This is insecure. See http://twil.io/secure
Authy.api_key = 'your_api_key'
Authy.api_uri = 'https://api.authy.com'

attendees = Attendee.where(event_id:240)

attendees.each do |a|
  #only for new numbers
  if attendee.authy_id.blank?
    #only for attendees with numbers
    unless attendee.custom_field_1.blank?
      #only if the number is 9 digits
      if attendee.custom_field_1.length == 9
        authy = Authy::API.register_user(:email => attendee.email, :cellphone => attendee.custom_fields_1, :country_code => attendee.custom_fields_3)
        if authy.ok?
          puts authy.id
          attendee.update!(authy_id:authy.id)
        else
          puts authy.errors
          attendee.update!(custom_fields_3:authy.errors)
        end
      else
        attendee.update!(custom_fields_3:"error")
      end
    end
  end
end