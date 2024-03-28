class SessionsTrackownersController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  def multiple_new
		@trackowner          = Trackowner.find(params[:trackowner_id])
		@sessions_trackowner = SessionsTrackowner.new
		@sessions            = Session.where(event_id:session[:event_id])
  end

  def update_multiple_new
		sessions    = params[:session_ids]
		@trackowner = Trackowner.find(params[:trackowner_id])

    sessions.each do |session_id|
			session             = Session.where(id:session_id).first
			sessions_trackowner = SessionsTrackowner.where({session_id:session.id,trackowner_id:@trackowner.id}).first_or_initialize
      sessions_trackowner.update!(trackowner_id:@trackowner.id,session_id:session.id)
    end

    respond_to do |format|
      format.html { redirect_to "/trackowners/#{@trackowner.id}", :notice => 'Sessions successfully associated with trackowner.' }
    end

  end

  # def show
  #   @sessions_trackowner = SessionsTrackowner.find(params[:id])

  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.xml  { render :xml => @sessions_trackowner }
  #   end
  # end

  # def new
  #   @sessions_trackowner = SessionsTrackowner.new

  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.xml  { render :xml => @sessions_trackowner }
  #   end
  # end

  # def create
  #   @sessions_trackowner = SessionsTrackowner.new(sessions_trackowner_params)
  #   @sessions_trackowner.session_id = Session.where(session_code:@sessions_trackowner.session_code).first.id

  #   respond_to do |format|
  #     if @sessions_trackowner.save
  #       format.html { redirect_to("/trackowners/#{@sessions_trackowner.trackowner_id}", :notice => 'Sessions trackowner successfully added') }
  #     else
  #       format.html { redirect_to("/trackowner/#{@sessions_trackowner.trackowner_id}/new", :notice => @sessions_trackowner.errors.full_messages[0]) }
  #     end
  #   end
  # end

  def destroy
    @sessions_trackowner = SessionsTrackowner.find(params[:id])
    @sessions_trackowner.destroy

    respond_to do |format|
      format.html { redirect_to("/trackowners/#{@sessions_trackowner.trackowner_id}", :notice => 'Sessions trackowner successfully removed') }
      format.xml  { head :ok }
    end
  end

  private
  def sessions_trackowner_params
    params.require(:sessions_trackowner).permit(:session_id, :trackowner_id)
  end
end
