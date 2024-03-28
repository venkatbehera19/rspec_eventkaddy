class ModeratorPortalsController < ApplicationController
  layout 'moderatorportal'

  def landing
    authorized?
  	#@sessions = Session.where(event_id:session[:event_id], qa_enabled:true)
    @event = Event.find(session[:event_id])
    @dates = (@event.event_start_at.to_date..@event.event_end_at.to_date).to_a
  	@event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
  end

  def sessions

    @sessions = Session.where(%{ sessions.event_id = #{session[:event_id]} and #{params[:date] && params[:date].length > 0 ? "date = #{params[:date].gsub('-', '')}" : '1 = 1'} and
      #{params[:qa_enabled].eql?('true') ? 'qa_enabled = 1' : '(qa_enabled = 0 or qa_enabled is null)'}
      and #{params[:chat_enabled] && params[:chat_enabled].length > 0 ? (params[:chat_enabled].eql?('true') ? 'chat_enabled = 1' : 'chat_enabled = 0') : '1 = 1' } 
    })
    if params["poll_enabled"].present? && params["poll_enabled"].eql?('true')
        @sessions = @sessions.select { |session|  session.poll_sessions.present? } if @sessions.present?
        @sessions = Session.where(event_id: session[:event_id], date: params[:date]).select { |session|  session.poll_sessions.present? } unless @sessions.present?
    end

    if params["search"].present?
      @sessions = @sessions.where("title like ?","%#{params["search"]}%")
    end
    render partial: 'moderator_portals/sessions', locals: { sessions: @sessions}
  end

  def qa_feed
    authorized?
  	@session              = Session.find(params[:session_id])
    @event                = Event.find(@session.event_id)
    @whitelist_mode       = whitelist_mode? @session.event_id
    @single_question_mode = single_question_mode? @session.event_id
    @cordova_booleans = Setting.return_cordova_booleans(session[:event_id])
    if @single_question_mode
      AttendeeTextUpload.reduce_to_one_whitelisted_question params[:session_id]
    end
  end

  def whitelist_question
    authorized?
    t_u = AttendeeTextUpload.select( :id, :event_id, :attendee_id, :text, :answer, :attendee_text_upload_type_id, :whitelist, :answered).find(params[:id])
    attendee = Attendee.select(:first_name, :last_name).find_by_id(t_u.attendee_id)
    text_uploads = []
    text_uploads.push(t_u.as_json.merge(attendee.as_json))
    render :json => {
      status: t_u.add_to_whitelist( single_question_mode?( t_u.event_id ) ),
      text_uploads: text_uploads,
      blacklist_ids: []
    }
  end

  def revoke_whitelist_question
    authorized?
    blacklist_ids = []
    status = AttendeeTextUpload.find(params[:id]).revoke_from_whitelist
    if whitelist_mode?(session[:event_id]) || single_question_mode?(session[:event_id])
      blacklist_ids = AttendeeTextUpload.where(
        session_id: params[:session_id],
        whitelist:  [false,nil]
        ).pluck(:id)
    end
    render :json => {
      status: status,
      blacklist_ids: blacklist_ids,
      text_uploads: []
    }
  end

  def mark_question_answered
    authorized?
    render :json => {
      status: AttendeeTextUpload.find(params[:id]).update!(answered: true)
    }
  end

  def update_question_text
    authorized?
    t_u = AttendeeTextUpload.find(params[:id])
    render :json => {
      status: t_u.update!(text: params[:text]),
      new_text: t_u.text
    }
  end

  def update_answer_text
    authorized?
    t_u = AttendeeTextUpload.find(params[:id])
    render :json => {
      status: t_u.update!(answer: params[:text]),
      new_answer: t_u.answer
    }
  end

  def post_qa
    authorized?
    # @attendee_text_upload = AttendeeTextUpload.new
    type_id  = AttendeeTextUploadType.where(name:'q&a').first.id
    moderator_attendee   = Attendee.where(event_id:session[:event_id], first_name:"Moderator", last_name:"", is_demo:true).first_or_create
    @attendee_text_upload = AttendeeTextUpload.create(event_id:session[:event_id],
                                                    session_id: params[:session_id],
                                                    attendee_id: moderator_attendee.id,
                                                    rev_number: 1,
                                                    attendee_text_upload_type_id: type_id,
                                                    text: params[:text],
                                                    answer: params[:answer])
    render :json => {
      status: "success",
      new_question: @attendee_text_upload
    }
            
  end

  def delete_question
    authorized?
    t_u = AttendeeTextUpload.find(params[:id])
    if t_u.destroy
      render :json => { status: "success"}
    else
      render :json => { status: "error", message: "Deletion failed"}
    end
  end

  def qa_ajax_data
    authorized?
  	render :json => AttendeeTextUpload.qa_text_uploads_for_session(
      params[:session_id],
      params[:question_ids]
    ) and return
  end

  def chat_manangement
    authorized?
    @event = session[:event_id]
  end

  def session_video
    authorized?
    @event         = Event.find(session[:event_id]) 
    @session       = Session.find params[:id]
    @show_ondemand = !@session.video_iphone.blank? && !@session.video_file_location.blank?
    if @show_ondemand
       @video_url = @session.return_authenticated_url(session[:event_id],@session.video_file_location)
    end
    @ondemand = @session.video_file_location
    @livestream = @session.video_ipad
    unless @session.subtitle_file_location.blank?
      @subtitles = JSON.parse(@session.subtitle_file_location)
      @path = "/event_data/#{session[:event_id]}/subtitles/"
    end
  end

  private 

  # we have no model associated with this controller, so we roll our own
  # authorization
  def authorized?
    unless current_user && (current_user.role?(:super_admin) || current_user.role?(:moderator))
      render :text => "You must be logged in as a moderator to access this page."
    else
      true
    end
  end

  def cordova_bools event_id
    @cordova_bools ||= Setting.return_cordova_booleans( event_id )
  end

  def whitelist_mode? event_id
    !!cordova_bools( event_id ).guest_qa_page_use_whitelist_enabled
  end

  def single_question_mode? event_id
    !!cordova_bools( event_id ).guest_qa_page_single_question_mode_enabled
  end

end

