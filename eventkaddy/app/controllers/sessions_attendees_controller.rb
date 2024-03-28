class SessionsAttendeesController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  def multiple_new
    @attendee          = Attendee.find(params[:attendee_id])
    @sessions_attendee = SessionsAttendee.new
    @sessions          = Session.where(event_id:session[:event_id])
  end

  def update_multiple_new
    sessions  = params[:session_ids]
    @attendee = Attendee.find(params[:attendee_id])

    sessions.each do |session_id|
      session           = Session.where(id:session_id).first
      sessions_attendee = SessionsAttendee
        .where(session_id:session.id, attendee_id:@attendee.id)
        .first_or_initialize

      sessions_attendee
        .update!(attendee_id:  @attendee.id,
                           session_id:   session.id,
                           flag:         'web',
                           session_code: session.session_code)
    end    

    respond_to do |format|
      format.html { redirect_to "/attendees/#{@attendee.id}", :notice => 'Sessions successfully associated with attendee.' }
    end   

  end

  def multiple_new_for_all
    @sessions_attendee = SessionsAttendee.new
    @sessions          = Session.where event_id: session[:event_id] 
  end

  def update_multiple_new_for_all
    sessions = Session.where(
       id:       params[:session_ids],
       event_id: session[:event_id]
    )
    attendees = Attendee.where event_id: session[:event_id]

    sessions.each do |session|
      attendees.each do |attendee|
        sessions_attendee = SessionsAttendee
          .where(session_id:session.id, attendee_id:attendee.id)
          .first_or_initialize

        sessions_attendee.update!(
          attendee_id:  attendee.id,
          session_id:   session.id,
          flag:         'web',
          session_code: session.session_code
        )
      end
    end    

    respond_to do |format|
      format.html { redirect_to "/sessions_attendees/multiple_new_for_all", :notice => "#{sessions.length} sessions successfully associated with #{attendees.length} attendees." }
    end   

  end

  def show
    @sessions_attendee = SessionsAttendee.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @sessions_attendee }
    end
  end

  def new
    @sessions_attendee = SessionsAttendee.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @sessions_attendee }
    end
  end

  def create
    @sessions_attendee      = SessionsAttendee.new(sessions_attendee_params)
    @sessions_attendee.flag = 'web'
    @sessions_attendee.session_id = Session.where(session_code:@sessions_attendee.session_code).first.id

    respond_to do |format|
      if @sessions_attendee.save
        format.html { redirect_to("/attendees/#{@sessions_attendee.attendee_id}", :notice => 'Sessions attendee successfully added') }
      else
        format.html { redirect_to("/attendee/#{@sessions_attendee.attendee_id}/new", :notice => @sessions_attendee.errors.full_messages[0]) }
      end
    end
  end

  def destroy
    @sessions_attendee = SessionsAttendee.find(params[:id])
    @sessions_attendee.destroy

    respond_to do |format|
      format.html { redirect_to("/attendees/#{@sessions_attendee.attendee_id}", :notice => 'Sessions attendee successfully removed') }
      format.xml  { head :ok }
    end
  end

  private

  def sessions_attendee_params
    params.require(:sessions_attendee).permit(:attendee_id, :session_id, :session_id_int, :flag, :session_code)
  end

end