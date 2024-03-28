class AttendeeSessionPollResponse < ApplicationRecord
  belongs_to :attendee
  belongs_to :poll_session
  belongs_to :session_poll_option
end
