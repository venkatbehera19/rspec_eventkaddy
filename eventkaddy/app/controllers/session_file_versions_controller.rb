class SessionFileVersionsController < ApplicationController
  layout :set_layout
  load_and_authorize_resource

    before_action :set_layout_variables #before_action in rails 4

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

  #GET
  #show session files
  def index
    @session_file_id = params[:session_file_id]
    @session_file_versions = SessionFileVersion.where(session_file_id:@session_file_id,event_id:session[:event_id]).order('created_at DESC')
    @session_file = SessionFile.find(@session_file_id)

    respond_to do |format|
      format.html # index.html.erb
    end

  end

=begin
  def show
    @session_file_id = params[:id]
    @session_file_versions = SessionFileVersion.where(session_file_id:@session_file_id)

    respond_to do |format|
      format.html # show.html.erb
    end

  end
=end

  def new
    @sesion_file_version = SessionFileVersion.new
    @session_file_id= params[:session_file_id]

    respond_to do |format|
      format.html # new.html.erb
    end

  end

  def create

    @session_file_version          = SessionFileVersion.new(session_file_version_params)
    @session_file_version.document = params[:event_file]
    @session_file_version.user_id  = current_user.id
    @session_file_version.updateFile(params)
    @session_file_version.set_to_final_version if params[:session_file_version][:final_version]=="1"


    respond_to do |format|
      if @session_file_version.save
        format.html { redirect_to("/session_file_versions/#{@session_file_version.session_file_id}/index", :notice => 'File Version successfully created.') }
      else
        format.html { redirect_to("/session_file_versions/#{@session_file_version.session_file_id}/new", :alert => @session_file_version.errors.full_messages[0]) }
      end
    end

  end

  def edit
    @session_file_version = SessionFileVersion.find(params[:id])
    @session_file_id      = @session_file_version.session_file_id

  end

  def update
    @session_file_version          = SessionFileVersion.find(params[:id])
    @session_file_version.document = params[:event_file]

    #set user
    @session_file_version.user_id  = current_user.id
    @session_file_version.updating = true

    @session_file_version.updateFile(params)

    @session_file_version.set_to_final_version if params[:session_file_version][:final_version]=="1"

    respond_to do |format|
      if @session_file_version.update!(session_file_version_params)
        @session_file_version.session_file.session.update_session_file_urls_json
        format.html { redirect_to("/session_file_versions/#{@session_file_version.session_file_id}/index", :notice => 'File Version successfully updated.') }
      else
        format.html { redirect_to("/session_file_versions/#{@session_file_version.id}/edit", :notice => @session_file_version.errors.full_messages[0]) }
      end
    end

  end

  def destroy
    @session_file_version = SessionFileVersion.find(params[:id])
    session_file_id = @session_file_version.session_file_id
    @session_file_version.destroy

    respond_to do |format|
        format.html { redirect_to("/session_file_versions/#{session_file_id}/index", :notice => 'File Version successfully deleted.') }
    end
  end

  private

    def get_speaker
      user = User.find(current_user.id)
      return Speaker.where(email:user.email,event_id:session[:event_id]).first

    end

  def set_layout
    if current_user.role? :trackowner then
      session[:layout]
    elsif current_user.role? :speaker then
      'speakerportal_2013'
    else
      'subevent_2013'
    end
  end

  private

  def session_file_version_params
    params.require(:session_file_version).permit(:event_file_id, :event_file_type_id, :event_id, :final_version, :session_file_id, :user_id)
  end

end