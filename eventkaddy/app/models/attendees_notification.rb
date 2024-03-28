class AttendeesNotification < ApplicationRecord
  
  serialize :attendee_codes, JSON

  def has_attendee_codes?
    attendee_codes.is_a?(Array) && attendee_codes.length > 0
  end

end
