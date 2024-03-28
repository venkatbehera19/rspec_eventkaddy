module SessionPollsHelper

  def session_poll_activated? poll_id, session_id
    poll_session = PollSession.find_poll_session poll_id, session_id
    poll_session.poll_status
  end

end
