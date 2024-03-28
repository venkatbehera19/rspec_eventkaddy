class MediaFilesController < ApplicationController
  layout :set_layout
  before_action :set_layout_variables
  include ExhibitorPortalsHelper
  # load_and_authorize_resource

  def index
    session[:exhibitor_id_portal] = params[:exhibitor_id]
    session[:session_id_portal] = params[:session_id]

    @exhibitor       = get_exhibitor
    @session         = get_session
    @exhibitor && check_for_payment
    where_clause     = get_where_clause(@exhibitor, @session)
    @media_files     = MediaFile.where(where_clause).order('position ASC')
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @media_files }
    end
  end

  # GET /media_files/1
  # GET /media_files/1.xml
  def show
    @media_file = MediaFile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @media_file }
    end
  end

  # GET /media_files/new
  # GET /media_files/new.xml
  def new
    @media_file = MediaFile.new
    @exhibitor       = get_exhibitor
    @session         = get_session
    where_clause = get_where_clause(@exhibitor, @session)
    @media_files     = MediaFile.where(where_clause).order('position ASC')

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @media_file }
    end
  end

  # GET /media_files/1/edit
  def edit
    @media_file     = MediaFile.find(params[:id])
    @exhibitor       = get_exhibitor
    @session         = get_session
    where_clause = get_where_clause(@exhibitor, @session)
    @media_files    = MediaFile.where(where_clause).order('position ASC')
  end

  # POST /media_files
  # POST /media_files.xml
  def create
    begin
      ActiveRecord::Base.transaction do
        @media_file  = MediaFile.new(media_file_params)
        @exhibitor       = get_exhibitor
        @session         = get_session
        where_clause = get_where_clause(@exhibitor, @session)
        @media_files = MediaFile.where(where_clause)
        active_object_name, active_object_id = check_active_object(@exhibitor, @session)
        @media_file.update_thumbnail(params[:thumbnail_file], params[:media_file][:name], params[:media_file][:session_id]) if params[:thumbnail_file]
        @media_file.update_video(params[:video_file], params[:media_file][:name], active_object_name[0...-1], @media_file) if params[:video_file]
        @media_file.update!(cloud_storage_type_id: Event.find(params[:media_file][:event_id]).cloud_storage_type_id)
        @media_files.createAndUpdatePositions(params[:json], @media_file) unless params[:json].blank?
        @url = "/media_files/#{active_object_name}/#{active_object_id}/index"
        render 'create.js.erb'
      end
    rescue StandardError => e
      render json: {message: e.message}, :status => :unprocessable_entity
    end


    # if request.xhr?
    #   render 'create.js.erb'
    # end
    # respond_to do |format|
    #   if @media_file.save
    #     format.html { redirect_to("/media_files/#{active_object_name}/#{active_object_id}/index", :notice => 'Media File successfully created.') }
    #   else
    #     format.html { render :action => "new" }
    #   end
    # end
  end

  # PUT /media_files/1
  # PUT /media_files/1.xml
  def update
    @media_file = MediaFile.find(params[:id])
    @exhibitor       = get_exhibitor
    @session         = get_session
    where_clause = get_where_clause(@exhibitor, @session)
    @media_files = MediaFile.where(where_clause)
    active_object_name, active_object_id = check_active_object(@exhibitor, @session)
    @media_files.updatePositions(params[:json]) unless params[:json].blank?
    @media_file.update_thumbnail(params[:thumbnail_file], params[:media_file][:name]) if params[:thumbnail_file]
    @media_file.update_video(params[:video_file], params[:media_file][:name],active_object_name[0...-1], @media_file) if params[:video_file]

    respond_to do |format|
      if @media_file.update!(media_file_params)
        format.html { redirect_to("/media_files/#{active_object_name}/#{active_object_id}/index", :notice => 'Media file was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @media_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /media_files/1
  # DELETE /media_files/1.xml
  def destroy
    @media_file = MediaFile.find(params[:id])
    @media_file.destroy

    respond_to do |format|
      format.html { redirect_back fallback_location: root_url }
      format.xml  { head :ok }
    end
  end

  def change_view
    @exhibitor       = get_exhibitor
    @session         = get_session
    where_clause     = get_where_clause(@exhibitor, @session)
    @media_files     = MediaFile.where(where_clause).order('position ASC')
    render partial: params[:view_type], locals: {media_files: @media_files, exhibitor: @exhibitor, session: session}
  end

  # All media files for belonging to sessions
  def sessions_media_files
    @media_files = MediaFile.joins(:session).where(event_id: session[:event_id])
    #render partial: params[:view_type], locals: {media_files: @media_files} if params[:view_type]
  end

  private

  def get_exhibitor
    if current_user.role? :exhibitor then
      if current_user.is_a_staff?
        es = ExhibitorStaff.find_by_user_id current_user.id
        return Exhibitor.find es.exhibitor_id
      else
        current_user.first_or_create_exhibitor( session[:event_id] )
      end
    elsif !session[:exhibitor_id_portal].blank?
      Exhibitor.find(session[:exhibitor_id_portal])
    else
      #no exhibitor
    end
  end

  def check_active_object(exhibitor, session)
    if exhibitor
      return "exhibitors", exhibitor.id
    else
      return "sessions", session.id
    end
  end

  def get_session
    if !session[:session_id_portal].blank?
      Session.find(session[:session_id_portal])
    else
      #no session
    end
  end

  def get_where_clause(exhibitor, session)
    if !@exhibitor.blank?
      where_clause = "media_files.exhibitor_id = #{@exhibitor.id}"
    elsif !@session.blank?
      where_clause = "media_files.session_id = #{@session.id}"
    else
      where_clause = ""
    end
    where_clause
  end

  def set_layout
    if current_user.role? :trackowner
      session[:layout]
    elsif current_user.role? :speaker
      'speakerportal_2013'
    elsif current_user.role? :exhibitor
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  def get_speaker
    user = User.find(current_user.id)
    return Speaker.where(email:user.email,event_id:session[:event_id]).first
  end

  def set_layout_variables
    if set_layout === 'speakerportal_2013'
      @speaker = get_speaker

      #determine number of remaining requirements yet to be filled
      @requirements = Requirement.joins(:requirement_type).where(event_id:session[:event_id],required:true).where(requirement_types: { requirement_for: 'speaker' })
      @requirements.each do |requirement|
        attribute=@speaker.read_attribute(requirement.requirement_type.name)
        if !(attribute.nil? || attribute=="")
          @requirements = @requirements.reject {|n| n==requirement}
        end
      end

      #retrieve existing pdfs
      @event_file_type = EventFileType.where(name:'speaker_pdf_upload').first
      @pdf_files = EventFile.where(event_id:@speaker.event_id,event_file_type_id:@event_file_type.id)

      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
      @tab_type_ids = Array.new
      TabType.where(portal:"speaker").each do |t|
        @tab_type_ids.push(t.id)
      end

      @tabs = Tab.where(event_id:session[:event_id],tab_type_id:@tab_type_ids)
    end
  end

  private

  def media_file_params
    params.require(:media_file).permit(:event_id, :name, :path, :published, :event_file_id, :cloud_storage_type_id, :exhibitor_id, :session_id, :website, :position)
  end

end
