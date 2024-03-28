class SessionPollsController < ApplicationController
  before_action :set_session_poll, only: [:show, :edit, :update, :restore, :remove, :destroy]
  layout 'moderatorportal'

  def index
    @event          = Event.find(session[:event_id])
    @session        = Session.includes(poll_sessions: :session_poll_options).find(params[:session_id])
    @active_poll    = @session.poll_sessions.where(poll_status: true).first
    @session_title  = @session.title.gsub!(/[^0-9A-Za-z]/, '')
    @session_title  = @session.session_code + '_' + @session_title.underscore
    @polls          = @event.polls.where.not(id: @session.poll_sessions.map(&:poll_id))
    @cordova_booleans = Setting.return_cordova_booleans(@event)
  end

  def update_session_poll_status
    authorized?
    @poll_session = PollSession.find_poll_session params[:poll_id], params[:session_id]
    # return render json: {status: 404, message: "Session Poll not found "} unless @poll_session
    return unless @poll_session
    activate_history = @poll_session.poll_status? ? @poll_session.activate_history : @poll_session.activate_history+1
    @poll_session.update(poll_status: !@poll_session.poll_status,activate_history: activate_history)
    @session      = Session.includes(poll_sessions: :session_poll_options).find(params[:session_id])
    @active_poll  = @session.poll_sessions.where(poll_status: true).first
    render partial: 'polls_list', locals: {session: @session, active_poll: @active_poll}
  end

  def restore
    @session_poll.restore_poll_session
    respond_to do |format|
      format.js
    end
  end
  
  def show
    @session_poll_options = @session_poll.session_poll_options
    @poll_result          = @session_poll_options.max_by {|option| option.option_result }
    @max = @session_poll_options.inject(0) {|sum,option| sum+option.option_result}

    if request.xhr?
      render 'show.js.erb' and return
    else
      render :show and return
    end

  end

  def show_modal
  end

  def edit
  end
  
  def update
    if @session_poll.update(session_poll_params)
      if params[:session_polls].present?
        session_poll_options = params[:session_polls][:option_texts]
        session_poll_options.each do |key, val|
          @session_poll.session_poll_options.create(option_text: val)
        end
      end
      redirect_to "/moderator_portals/sessions/#{@session_poll.session.id}/session_polls", notice: 'Session Poll is successfully updated.'
    else
      render :edit
    end
  end

  def add_polls
    event = Event.find_by(id: params[:event])
    session = Session.find_by(id: params[:session])
    active_poll = session.poll_sessions.where(poll_status: true).first
    @polls = Poll.where(event_id: session.event_id).where.not(id: session.poll_sessions.map(&:poll_id))
    @event_setting = EventSetting.where("event_id= ?", event.id).first
    if session
      PollSession.create_session_poll(session, event, params[:poll]) if params[:poll].present?
      if params[:location] == "speaker"
        render :partial => 'speaker_portals/polls_list', locals: {session: session, active_poll: active_poll}
      else
        render :partial => 'polls_list', locals: {session: session, active_poll: active_poll}
      end
    end
  end

  def remove
    session = @session_poll.session
    session_poll = @session_poll.destroy
    session.reload
    @event_setting = EventSetting.where("event_id= ?", session.event_id).first
    @polls = Poll.where(event_id: session.event_id).where.not(id: session.poll_sessions.map(&:poll_id))
    render :partial => 'speaker_portals/polls_list', locals: {session: session}
  end

  def destroy
    @session_poll.session_poll_options.find(params[:session_poll_options]).destroy
    redirect_to "/moderator_portals/session_polls/#{@session_poll.id}/edit", notice: 'Session Poll Option was successfully destroyed.'
  end 

  private
  # we have no model associated with this controller, so we roll our own
  # authorization
  def set_session_poll
    @session_poll = PollSession.find(params[:id])
  end

  def authorized?
    unless current_user && (current_user.role?(:super_admin) || current_user.role?(:moderator))
      render :text => "You must be logged in as a moderator to access this page."
    else
      true
    end
  end

  def session_poll_params
    params.require(:poll_session).permit(:id, :event_id, :title, :response_limit, :options_select_limit, :allow_answer_change, :timeout_time, :option_texts => {}).merge({event_id: session[:event_id]})
  end

  # def find_and_update_session_poll_status
  #   PollSession.find_and_update_poll_status params[:poll_id], params[:session_id]
  # end

end
