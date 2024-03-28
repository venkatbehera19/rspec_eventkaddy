class PollsController < ApplicationController
  before_action :set_poll, only: [:show, :edit, :update, :destroy]
  before_action :check_moderator_speaker_allowed, only: [:create]
  layout :set_layout

  # GET /polls
  def index
    @polls = Poll.where(event_id: session[:event_id])
  end

  # GET /polls/1
  def show
    @options = @poll.options
  end

  # GET /polls/new
  def new
    @poll = Poll.new
  end

  def new_poll_by_moderator
    @poll = Poll.new
  end

  # GET /polls/1/edit
  def edit
  end

  # POST /polls
  def create
    options = params[:poll][:option_texts]
    @poll = Poll.new(poll_params)
    if @poll.save
      options.each do |key, val|
        @poll.options.create(text: val)
      end
      if params[:session_id].present?
        @poll.update_associations([params[:session_id]], @poll.options)
        if current_user.role? 'speaker'
          redirect_to "/speaker_portals/session_polls_list/#{params[:session_id]}"
        elsif current_user.role? 'moderator'
          redirect_to "/moderator_portals/sessions/#{params[:session_id]}/session_polls"
        end  
      else
        redirect_to @poll, notice: 'Poll was successfully created.'
      end
    else
      render :new
    end
  end

  # PATCH/PUT /polls/1
  def update
    options = params[:poll][:option_texts] || []
    if @poll.update(poll_params)
      options.each do |key, val|
        @poll.options.create(text: val)
      end
      redirect_to @poll, notice: 'Poll was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /polls/1
  def destroy
    @poll.destroy
    redirect_to polls_url, notice: 'Poll was successfully destroyed.'
  end

  def associations
    @poll     = Poll.find params[:id]
    @selected = PollSession.where(poll_id:params[:id]).pluck(:session_id)
    @sessions = Session.select('id, event_id, title, session_code').where(event_id:session[:event_id])
  end

  def update_associations
    poll_params, session_params = params.require([:poll, :session_ids])
    @poll   = Poll.find(params[:poll][:id])
    options = @poll.options
    @poll.update_associations(session_params,options)

    respond_to do |format|
      format.html { redirect_to "/polls/associations/#{@poll.id}", :notice => 'Sessions successfully associated with survey.' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_poll
      @poll = Poll.find(params[:id])
    end

    def set_layout
      if current_user.role? :moderator then
        'moderatorportal'
      else
        'subevent_2013'
      end
    end

    def check_moderator_speaker_allowed
      if current_user.role?('moderator') && !Setting.return_cordova_booleans(session[:event_id]).add_polls
        redirect_to "/moderator_portals/sessions/#{params[:session_id]}/session_polls"
      elsif current_user.role?('speaker') && !EventSetting.find_by(event_id: session[:event_id])&.sessions_editable
        redirect_to "/speaker_portals/session_polls_list/#{params[:session_id]}"
      end
    end

    # Only allow a list of trusted parameters through.
    def poll_params
      params.require(:poll).permit(:id, :event_id, :title, :response_limit, :options_select_limit, :allow_answer_change, :timeout_time, :result_display_type, :option_texts => {}).merge({event_id: session[:event_id]})
    end
end
