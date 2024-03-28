class SessionPollOption < ApplicationRecord
  belongs_to :poll_session
  has_many :attendee_session_poll_responses
end
