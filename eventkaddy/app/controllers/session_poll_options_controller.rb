class SessionPollOptionsController < ApplicationController

  def destroy
    @session_poll_option = SessionPollOption.find params[:session_poll_option_id]
    @session_poll_option.destroy
    redirect_to edit_session_poll_path(params[:id])
  end
  


end
