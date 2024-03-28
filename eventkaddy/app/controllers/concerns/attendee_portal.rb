module AttendeePortal 
  extend ActiveSupport::Concern

  def signout_attendee(message = nil)
    event_id = session[:event_id]
    cookies.clear
    session = nil
    current_user = nil
    reset_session
    if message.nil?
      redirect_to "/#{event_id}/registrations/login_to_profile"
    else
      redirect_to "/#{event_id}/registrations/login_to_profile", :alert => message
    end
  end

end