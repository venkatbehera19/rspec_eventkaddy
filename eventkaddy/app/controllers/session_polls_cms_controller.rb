class SessionPollsCmsController < ApplicationController
  before_action :set_session_poll, only: [:show, :edit, :update, :destroy, :restore]
  layout :set_layout
  before_action :check_if_session_poll_editable, only: [:edit]

  # GET /session_polls
  def index
    @sessions_with_polls = Session.includes(poll_sessions: :session_poll_options).where(event_id: session[:event_id]).where.not(poll_sessions: {id: nil}).order(created_at: :desc)
  end

    # GET /session_polls/1
  def show
    @session_poll_options = @session_poll.session_poll_options
    @poll_result          = @session_poll_options.max_by {|option| option.option_result }
  end

  def restore
    @session_poll.restore_poll_session
    respond_to do |format|
      format.js
    end
  end  

  # GET /session_polls/1/edit
  def edit
  end

  # PATCH/PUT/session_polls/1
  def update
    if @session_poll.update(session_poll_params)
      if params[:session_polls].present?
        session_poll_options = params[:session_polls][:option_texts]
        session_poll_options.each do |key, val|
          @session_poll.session_poll_options.create(option_text: val)
        end
      end
      redirect_to session_polls_path, notice: 'Session Poll is successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /session_polls/1
  def destroy
    @session_poll.destroy
    redirect_to session_polls_path, notice: 'Session Poll was successfully destroyed.'
  end


  private

  def set_session_poll
    @session_poll = PollSession.find(params[:id])
  end

  def set_layout
      if current_user.role? :moderator then
        'moderatorportal'
      else
        'subevent_2013'
      end
  end

  def check_if_session_poll_editable
    redirect_to session_polls_path, alert: "Cannot edit this Session Poll." if @session_poll.activate_history > 0
  end  

   # Only allow a list of trusted parameters through.
  def session_poll_params
    params.require(:poll_session).permit(:id, :event_id, :title, :response_limit, :options_select_limit, :allow_answer_change, :timeout_time, :option_texts => {}).merge({event_id: session[:event_id]})
  end

end
