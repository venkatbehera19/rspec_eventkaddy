class AttendeeTicket < ApplicationRecord
  belongs_to :event_ticket
  belongs_to :attendee
end
