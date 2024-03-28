class SessionFilesController < ApplicationController
  layout :set_layout

  #layout 'subevent_2013'
  load_and_authorize_resource

  before_action :set_layout_variables #before_action in rails 4

  def publish_select_sessions
    @event = Event.find session[:event_id]
    @session_files = SessionFile.
      select('session_files.id, session_files.title, sessions.session_code, session_files.unpublished').
      joins(:session).
      where(event_id:session[:event_id]).
      order(:session_code)
    render layout: 'subevent_2013'
  end

  # submit point for publish select sessions
  def publish_session_files
    if params[:job_id]
      # raise params.inspect.red
      render json: Job.find( params[:job_id] ).run_job_in_background(
        %@ek_scripts/job_scripts/publish_sessions.rb "#{session[:event_id]}" "#{params[:job_id]}" '#{params[:session_file_ids].to_json.gsub(/\\/, '\\\\\\')}'@
      )
    else
      # non job version... probably should just deprecate
      SessionFile.where(event_id:session[:event_id]).update_all(unpublished: true)
      sf = SessionFile.where(event_id:session[:event_id], id: params[:session_file_ids] )
      sf.update_all(unpublished: false)
      Session.where(event_id: session[:event_id]).each &:update_session_file_urls_json
      respond_to do |f|
        # f.html { redirect_to "/session_files/publish_select_sessions", :notice => "#{sf.map(&:title).join(', ')} Published" }
        f.html { redirect_to "/session_files/publish_select_sessions", :notice => "Sessions Published" }
      end
    end
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

  #GET
  #show session files
  def index
    # if (session[:event_id]) then

    @event_id      = session[:event_id]
    @session_id    = params[:session_id]
    @session_files = SessionFile.where(session_id:@session_id)
    @filetypes     = {"application/msword" => ".doc", "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => ".docx", "application/vnd.oasis.opendocument.spreadsheet" => ".ods", "application/pdf" => ".pdf", "text/plain" => ".txt", "application/rtf" => ".rtf", "application/vnd.ms-powerpoint" => ".ppt", "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "pptx", "application/vnd.ms-excel" => ".xls", "application/xlsx" => ".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => ".xlsx", "video/quicktime" => ".mov", "video/mp4" => ".mp4", "audio/mpeg" => ".mp3", "application/octet-stream" => ".pez"}

      # #disabled while using server-side fetch for datatables
      # #@sessions = Session.select("DISTINCT sessions.*,location_mappings.name, CONCAT_WS(' ', DATE_FORMAT(sessions.date, '%Y-%m-%d'),' | ',DATE_FORMAT(sessions.start_at, '%H:%i')) AS session_date").joins('LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id').where("sessions.event_id= ?",session[:event_id]).order('session_code ASC')

      #   respond_to do |format|
      #     format.html # index.html.erb
      #     format.xml  { render :xml => @sessionfiles }
      #     #format.json { render :json => @sessions.to_json, :callback => params[:callback] }
      #     format.json { render json: SessionsFilesDatatable.new(view_context,@event_id) }
      #   end

    respond_to do |format|
      format.html # index.html.erb
    end

  end

  def summary

    if session[:event_id]

      @current_user = current_user
      if params[:type]
        session[:file_type_id] = SessionFileType.where(name:params[:type]).first.id
      elsif !session[:file_type_id]
        session[:file_type_id] = 1
      end
      respond_to do |format|
        format.html
        format.xml { render :xml => @session_files }
        format.xml { render :xml => @speakers }
        format.json { 
          render(
            json: SessionFilesDatatable.new(
              view_context,
              session[:event_id],
              @current_user,
              session[:file_type_id]
            )
          )
        }
      end

    else
      redirect_to "/home/session_error"
    end
  end

  def select_sessions
    # hacky way of using form helper?
    @session_file = SessionFile.first
    @sessions = Session.where(event_id:session[:event_id])
  end

  def update_select_sessions
    sessions          = params[:session_ids]
    session_file_type = SessionFileType.where(name:"Conference Note").first

    sessions.each do |session_id|
      session = Session.where(id:session_id).first
      session_file = SessionFile.where(
        event_id:             session[:event_id],
        session_id:           session.id,
        session_file_type_id: session_file_type.id,
        title:                "Convention Note",
        description:          "Please upload a Word or PDF document"
      ).first_or_create( unpublished: true )
    end

    respond_to do |format|
      format.html { redirect_to "/session_files/summary?type=conference note", :notice => 'Session Files Successfully Created' }
    end

  end

  # This looks like a very old button that was used for prepopulating the
  # speaker portal with session files so that a speaker would only have to make
  # a version? Adding unpublished to it anyway, though it isn't likely used.
  def add_file_to_all

    sessions          = Session.where(event_id:session[:event_id])
    session_file_type = SessionFileType.where(name:params[:type]).first

    # annoyingly, this can overwrite an existing session file
    sessions.each do |session|
      session_file = SessionFile.where(
        event_id:             session[:event_id],
        session_id:           session.id,
        session_file_type_id: session_file_type.id,
        title:                "Conference Note",
        description:          "Please upload a Word or PDF document"
      ).first_or_create( unpublished: true )
    end

    respond_to do |format|
      format.html { redirect_to "/session_files/summary?type=conference note", :notice => 'Session Files Successfully Created' }
    end
  end

  # this should be deleted... clearly was for avma or wvc or something
  def add_file_to_poultry

	#sessions = Session.where(event_id:session[:event_id]).where("id > ?", 164128).where("id < ?", 164359)
	sessions = Session.where(event_id:session[:event_id]).where("id > ?", 164128).where("id < ?", 164130)
    #sessions = Session.where(event_id:session[:event_id])
    session_file_type = SessionFileType.where(name:params[:type]).first

    sessions.each do |session|
      puts "creating conference note for session #{session.title}"
      session_file = SessionFile.where({event_id:session[:event_id],session_id:session.id,session_file_type_id:session_file_type.id}).first_or_initialize
      session_file.update!(title:"Convention Note",description:"Please upload a Word or PDF document")
    end

    respond_to do |format|
      format.html { redirect_to "/session_files/summary?type=conference note", :notice => 'Session Files Successfully Created' }
    end
  end

  # this contains wvc specific code... should either be updated to use master url, or deleted Also the code is convoluted
  def finalize_versions

    session_file_type = SessionFileType.where(name:params[:type]).first
    sessions_files = SessionFile.where(event_id:session[:event_id],session_file_type_id:session_file_type.id)
    sessions = Session.where(event_id:session[:event_id])

    sessions_files.each do |session_file|
        versions = session_file.session_file_versions.order('created_at DESC')
        if (versions.length > 0) then
            versions.each do |version|
                version.update_columns(final_version:false)
            end
            versions.first.update_columns(final_version:true)
        end
    end

    sessions.each do |session|
      if session.session_files.length===0 then
        next
      end
      urls = ""
      session.session_files.each_with_index do |session_file, index|
        if session_file.session_file_versions.length < 1 || session_file.session_file_type_id!=1 then
          next
        end
        if index != (session.session_files.length-1) then
          urls+= "https://wvcspeakers.eventkaddy.net"+session_file.session_file_versions.order('created_at DESC').first.event_file.path+", "
        else
          urls+= "https://wvcspeakers.eventkaddy.net"+session_file.session_file_versions.order('created_at DESC').first.event_file.path
        end
      end
      session.session_file_urls=urls
      session.save()
    end


    respond_to do |format|
      format.html { redirect_to "/session_files/summary?type=conference note", :notice => 'Final Version Marked for all Conference Notes' }
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
    @sesion_file = SessionFile.new

    @session_id= params[:session_id]
    respond_to do |format|
      format.html # new.html.erb
    end

  end

  def create

    @session_file = SessionFile.new(session_file_params)

    if !(params[:event_files].nil?) && params[:event_files].length == 1
      if @session_file.save
        @session_file_version                 = SessionFileVersion.new()
        @session_file_version.document        = params[:event_files].first
        @session_file_version.session_file_id = @session_file.id
        @session_file_version.event_id        = session[:event_id]
        #set user
        @session_file_version.user_id         = current_user.id
        @session_file_version.updateFile(params)

        @session_file_version.set_to_final_version if params[:final_version]=="1"
        # @session_file_version.finalVersionCheck(params)
        @session_file_version.save
      end
    elsif !(params[:event_files].nil?)
      params[:event_files].each do |file|
        @session_file       = SessionFile.new(session_file_params)
        @session_file.title = file.original_filename
        if @session_file.save
          @session_file_version                 = SessionFileVersion.new()
          @session_file_version.document        = file
          @session_file_version.session_file_id = @session_file.id
          @session_file_version.event_id        = session[:event_id]
          #set user
          @session_file_version.user_id         = current_user.id
          @session_file_version.updateFile(params)
          @session_file_version.set_to_final_version if params[:final_version]=="1"
          @session_file_version.save
        end
      end
    end
      respond_to do |format|
        if @session_file_version && (!(@session_file_version.errors.empty?) || !(@session_file.errors.empty?))
          format.html { redirect_to("/session_files/#{params[:session_file][:session_id]}/new", :alert => "#{@session_file_version.errors.full_messages[0]} #{@session_file.errors.full_messages[0]}")}
          @session_file.destroy
        elsif @session_file.save
          format.html { redirect_to("/session_files/#{@session_file.session_id}/index", :notice => 'Session File successfully created.') }
        else
          format.html { redirect_to("/session_files/#{params[:session_file][:session_id]}/new", :alert => "#{@session_file.errors.full_messages[0]}")}
        end
      end

  end

  def edit
    @session_file = SessionFile.find(params[:id])
    @session_id= @session_file.session_id

  end

  def update
   @session_file   = SessionFile.find(params[:id])
   version_created = false

    if !(params[:event_files].nil?) && params[:event_files].length == 1
      if @session_file.save
        @session_file_version                 = SessionFileVersion.new()
        @session_file_version.document        = params[:event_files].first
        @session_file_version.session_file_id = @session_file.id
        @session_file_version.event_id        = session[:event_id]
        #set user
        @session_file_version.user_id         = current_user.id
        @session_file_version.updateFile(params)
        @session_file_version.set_to_final_version if params[:final_version]=="1"
        if @session_file_version.save
          version_created = true
        end
      end
    elsif !(params[:event_files].nil?)
      params[:event_files].each do |file|
        @session_file       = SessionFile.new(session_file_params)
        @session_file.title = file.original_filename
        if @session_file.save
          @session_file_version                 = SessionFileVersion.new()
          @session_file_version.document        = file
          @session_file_version.session_file_id = @session_file.id
          @session_file_version.event_id        = session[:event_id]
          #set user
          @session_file_version.user_id         = current_user.id
          @session_file_version.updateFile(params)
          @session_file_version.set_to_final_version if params[:final_version]=="1"
          if @session_file_version.save
            version_created = true
          end
        end
      end
    end

    updated = @session_file.update!(session_file_params)

    @session_file.session.update_session_file_urls_json # if not event_file in params, we need this here. ugly.

    respond_to do |format|
      if updated && @session_file_version && !@session_file_version.errors.empty?
        format.html { redirect_to("/session_files/#{@session_file.id}/edit", :alert => @session_file_version.errors.full_messages[0]) }
      # elsif updated && version_created && @session_file.updateJsonEntry(params)
      #   format.html { redirect_to("/session_files/#{@session_file.session_id}/index", :notice => 'Session File successfully updated.') }
      elsif updated # && !version_created
        format.html { redirect_to("/session_files/#{@session_file.session_id}/index", :notice => 'Session File successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end

  end

  def destroy
    @session_file = SessionFile.find(params[:id])
    session_id = @session_file.session_id
    @session_file.destroy

    respond_to do |format|
        format.html { redirect_back(:notice => 'Session File successfully deleted.', fallback_location: "/session_files/#{session_id}/index") }
    end
  end

  def download_all_zip

    @session_file = SessionFile.where(event_id: session[:event_id]).first

    # TODO: check this works how I like 
    # really it looks unrelated, since bundle files cares only about
    # files in the directories, not entries in the database
    unless @session_file
      raise ActionController::RoutingError,
            "No session files have been uploaded for this event." 
    end

    @event_name = Event
      .find( session[:event_id] )
      .name
      .downcase
      .gsub(/\s/,'_')

    @session_file.event_name = @event_name

    @session_file.bundleFiles

    filename = @event_name + '_session_files.zip'

    path = Rails.root.join( 
      'public',
      'event_data',
      session[:event_id].to_s,
      'session_files',
      filename 
    )

    def file_exists_and_user_privileged? path, user
      File.exists?(path) && user.role?(:superadmin) || user.role?(:client)
    end

    if file_exists_and_user_privileged? path, current_user
      send_file path, x_sendfile: true
    else
      raise ActionController::RoutingError, "File not available."
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

  def session_file_params
    params.require(:session_file).permit(:event_id, :session_id, :title, :description, :unpublished, :session_file_type_id)
  end

end