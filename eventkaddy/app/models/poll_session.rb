class PollSession < ApplicationRecord
  # belongs_to :poll
  belongs_to :session
  belongs_to :event
  has_many :session_poll_options, dependent: :destroy
  has_many :attendee_session_poll_responses
  # validates :poll, uniqueness: { scope: :session }

  # poll_session_id  
  # def self.find_and_update_poll_status poll_id, session_id
  #   poll_session = find_poll_session poll_id, session_id
  #   poll_session ? poll_session.update(poll_status: !poll_session.poll_status) : nil
  # end

  def restore_poll_session
    self.update(activate_history: 0)
    self.session_poll_options.update_all(option_result: 0)
    self.attendee_session_poll_responses.destroy_all
  end


  def self.find_poll_session poll_id, session_id
    where(id: poll_id, session_id: session_id).first
  end

  def self.create_session_poll(session, event, poll_id)
    poll = Poll.find_by(id: poll_id)
    options = poll.options
    poll_session = PollSession.where(session_id: session.id, poll_id: poll.id, event_id: event.id, title: poll.title, response_limit: poll.response_limit, options_select_limit: poll.options_select_limit, allow_answer_change: poll.allow_answer_change, timeout_time: poll.timeout_time).first_or_create
    options.each do |option|
      SessionPollOption.find_or_create_by(poll_session: poll_session, option_text: option.text)
    end
    poll_session
  end

end
