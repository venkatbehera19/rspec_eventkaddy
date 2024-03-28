class EventSettingsController < ApplicationController
  layout 'settings'
  load_and_authorize_resource


  before_action :set_cache_buster

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def edit_requirements
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
    if @event_setting.nil?
      @event_setting=EventSetting.new()
    end

    @event_id=session[:event_id]
    @event=Event.where(id:@event_id).first

    @requirements= Requirement.where(event_id:@event_id).joins(:requirement_type)

    if @requirements.length<1 then
      @requirements=Requirement.new()
      @requirements.createDefaults(@event_id)
      @requirements=Requirement.where(event_id:@event_id).joins(:requirement_type)
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @events }
    end
  end

  def update_requirements
    @event_id=session[:event_id]
    @event=Event.where(id:@event_id).first
    @requirements=Requirement.where(event_id:@event_id).joins(:requirement_type).readonly(false)

    @event=Event.find(@event_id)


    respond_to do |format|
      if (@event.updateRequirements(params,@requirements))

        format.html { redirect_to("/settings/speaker_portal", :notice => "Settings successfully updated.") }
      else
        format.html { redirect_to("/settings/speaker_portal", :alert => "Settings could not be updated.") }
      end
    end
  end

  def edit_mobile_settings
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
    if @event_setting.nil?
      @event_setting=EventSetting.new()
    end

    @event_id=session[:event_id]
    @event=Event.where(id:@event_id).first

    @mobile_web_settings= MobileWebSetting.where(event_id:@event_id).joins(:mobile_web_setting_type).order(:type_id)

    # @mobile_web_settings=MobileWebSetting.select('mobile_web_settings.*,mobile_web_setting_types.name AS type_name').where("mobile_web_settings.event_id= ?",@event_id).joins('
    #   LEFT OUTER JOIN mobile_web_setting_types ON mobile_web_settings.type_id=mobile_web_setting_types.id'
    #   )

    if @mobile_web_settings.length<1 then
      @mobile_web_setting=MobileWebSetting.new()
      @mobile_web_setting.createDefaults(@event_id)
      @mobile_web_settings=MobileWebSetting.where(event_id:@event_id).joins(:mobile_web_setting_type).order(:type_id)
    end

    respond_to do |format|
      format.html {render :layout => 'mobilesettings_2014'}
      format.xml  { render :xml => @events }
    end

  end

  def update_mobile_settings
    @event_id=session[:event_id]
    @event=Event.find @event_id
    @mobile_web_settings=MobileWebSetting.where(event_id:@event_id).joins(:mobile_web_setting_type).readonly(false)

    @event=Event.find(@event_id)

    @event.addLogo(params)

    respond_to do |format|
      if (@event.updateMobileWebSettings(params,@mobile_web_settings))

        format.html { redirect_to("/event_settings/edit_mobile_settings", :notice => "Settings successfully updated.") }
      else
        format.html { redirect_to("/event_settings/edit_mobile_settings", :alert => "Settings could not be updated.") }
      end
    end

  end

  def edit_banners
    @tablet_banner_ad=EventFileType.where(name:"tablet_banner_ad").first.id
    @phone_banner_ad=EventFileType.where(name:"phone_banner_ad").first.id

    @banners = EventFile.where(event_id:session[:event_id],event_file_type_id:[@tablet_banner_ad,@phone_banner_ad]).order(:event_file_type_id)

    respond_to do |format|
      format.html {render :layout => 'mobilesettings_2014'}
    end
  end

  def edit_event_settings
    if session[:event_id]
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

      if @event_setting.nil?
        @event_setting=EventSetting.new()
      end
    end
  end

  def update_event_settings

    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

    #create record if none exists
    if @event_setting.nil?
      @event_setting=EventSetting.new()
      @event_setting.event_id = session[:event_id]
    end

    respond_to do |format|
      if @event_setting.update!(event_setting_params)
        # @event_setting.updateLogo(params)
        format.html { redirect_to('/settings/speaker_portal', :notice => 'Settings successfully updated.') }
        format.xml { head :ok }
      else
        format.html { redirect_to('/settings/speaker_portal', :notice => 'Update error.') }
        format.xml { render :xml => @event_settings.errors, :status => :unprocessable_entity }
      end
    end

  end

  def edit_general_portal_settings
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
    puts @event_setting.to_json
    if @event_setting.nil?
      @event_setting=EventSetting.new()
    end
  end

  def update_general_portal_settings

    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
    current_user.update!(twelve_hour_format: params[:twelve_hour_format]=="1") if !params[:twelve_hour_format].blank?
    #create record if none exists
    if @event_setting.nil?
      @event_setting=EventSetting.new()
      @event_setting.event_id = session[:event_id]
    end

    respond_to do |format|
      if @event_setting.update!(event_setting_params)
        @event_setting.updateLogo(params)

        format.html { redirect_to("/event_settings/edit_general_portal_settings", :notice => 'Settings successfully updated.') }
        format.xml { head :ok }
      else
        format.html { redirect_to("/event_settings/edit_general_portal_settings", :notice => 'Update error.') }
        format.xml { render :xml => @event_settings.errors, :status => :unprocessable_entity }
      end
    end

  end

  def edit_restricted_event_settings
    @event_setting = Event.find session[:event_id]
    @event_file    = (@event_setting.logo_event_file_id.blank?)?  EventFile.new : EventFile.find(@event_setting.logo_event_file_id)
    event_file_type_id 			= EventFileType.where(name:'mobile_css').first.id
    @mobile_css_file				= EventFile.where(event_id: session[:event_id], event_file_type_id: event_file_type_id).first

  end

  def save_css
    @css_text = params[:css_text]
    @event = Event.find(session[:event_id])
    @target_path = Rails.root.join('public','event_data', session[:event_id].to_s,'mobile_css')
    @file_name = "event_styles.css"
    cloud_storage_type_id = @event.cloud_storage_type_id
    cloud_storage_type = nil
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    event_file_type_id 			= EventFileType.where(name:'mobile_css').first.id
    event_file							= EventFile.where(event_id: session[:event_id], event_file_type_id: event_file_type_id).first_or_initialize
    write_temp_file

    UploadEventFile.new({
      event_file: event_file,
      file: @file,
      target_path: @target_path,
      new_filename: @file_name,
      cloud_storage_type: cloud_storage_type,
      content_type: MIME::Types.type_for(@file.path).first.content_type,
      public_ack: true
    }).call

    delete_temp_file

    render json: {css_filename: event_file.name, css_url: event_file.return_public_url()['url']}, status: 200
  end

  def update_restricted_event_settings
    @event_setting = Event.find session[:event_id]
    @event_params  = event_params
    @event_params[:event_start_at] = DateTime.strptime("#{event_params[:event_start_at]} #{event_params[:utc_offset]}","%m/%d/%Y %I:%M %p %:z")
    # .change(:offset => event_params[:utc_offset])
    @event_params[:event_end_at]   = DateTime.strptime("#{event_params[:event_end_at]} #{event_params[:utc_offset]}","%m/%d/%Y %I:%M %p %:z")
    @event_params[:calendar_json]  = JSON.generate(event_params[:calendar_json].to_h)

    @event_setting.assign_attributes(@event_params)
    respond_to do |format|
      @event_setting.addLogo(params)

      if @event_setting.save
        format.html { redirect_to("/event_settings/edit_restricted_event_settings", :notice => 'Settings successfully updated.') }
        format.xml { head :ok }
      else
        format.html { redirect_to("/event_settings/edit_restricted_event_settings", :notice => 'Update error.') }
        format.xml { render :xml => @event_settings.errors, :status => :unprocessable_entity }
      end
    end
  end

  # get event_tabs
  def edit_event_tabs
    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_initialize
    @tab_type_ids  = TabType.where(portal:"speaker").pluck(:id)
    @tabs          = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids).order(:order)

    if @tabs.length != TabType.where(portal:"speaker").length
      Tab.createDefaults(session[:event_id], "speaker")
      @tabs = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids).order(:order)
    end
  end

  # get event_tabs
  def edit_exhibitor_event_tabs
    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_initialize
    @tab_type_ids  = TabType.where(portal:"exhibitor").pluck(:id)
    @tabs          = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids)

    if @tabs.length != TabType.where(portal:"exhibitor").length
      Tab.createDefaults(session[:event_id], "exhibitor")
      @tabs = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids)
    end
  end

  def update_tab

    JSON.parse(params[:Tab]).each do |x|
      puts x
      tabtype = x["id"].to_i
      input = x["input"]
      order = x['order']

      if x["column"] == "disabled" then
        status = 0
      else
        status = 1
      end
      @tab = Tab.where("event_id = ? AND tab_type_id = ?", session[:event_id], tabtype).first

      @tab.enabled = status
      @tab.name = input
      @tab.order = order
      @tab.save()

      #@tab.update!(enabled.to_sym => status, name.to_sym => input)
    end
    render plain: "OK"

  end

  def edit_av_requirements
    @tab_type_id=TabType.where(default_name:"Sessions").first.id
    @tab= Tab.where(event_id:session[:event_id],tab_type_id:@tab_type_id).first

    if (session[:event_id]) then
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

      if @event_setting.nil?
        @event_setting=EventSetting.new()
      end
      render(:layout => set_layout)
    end
  end

  def update_av_requirements
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

    #create record if none exists
    if @event_setting.nil?
      @event_setting=EventSetting.new()
      @event_setting.event_id = session[:event_id]
    end



    respond_to do |format|
      if @event_setting.update!(event_setting_params)

        format.html { redirect_to("/event_settings/edit_av_requirements", :notice => 'Settings successfully updated.') }
        format.xml { head :ok }
      else
        format.html { redirect_to("/event_settings/edit_av_requirements", :notice => 'Update error.') }
        format.xml { render :xml => @event_settings.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit_session_notes_content
    @tab_type_id=TabType.where(default_name:"Sessions").first.id
    @tab= Tab.where(event_id:session[:event_id],tab_type_id:@tab_type_id).first
    if (session[:event_id]) then
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

      if @event_setting.nil?
        @event_setting=EventSetting.new()
      end
      render(:layout => set_layout)
    end
  end

  def update_session_notes_content
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

    #create record if none exists
    if @event_setting.nil?
      @event_setting=EventSetting.new()
      @event_setting.event_id = session[:event_id]
    end



    respond_to do |format|
      if @event_setting.update!(event_setting_params)

        format.html { redirect_to("/event_settings/edit_session_notes_content", :notice => 'Settings successfully updated.') }
        format.xml { head :ok }
      else
        format.html { redirect_to("/event_settings/edit_session_notes_content", :notice => 'Update error.') }
        format.xml { render :xml => @event_settings.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit_exhibitor_welcome
    if (session[:event_id]) then
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

      if @event_setting.nil?
        @event_setting=EventSetting.new()
      end
    end
  end

  def update_exhibitor_welcome
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

    #create record if none exists
    if @event_setting.nil?
      @event_setting=EventSetting.new()
      @event_setting.event_id = session[:event_id]
    end



    respond_to do |format|
      if @event_setting.update!(event_setting_params)

        format.html { redirect_to("/event_settings/edit_exhibitor_welcome", :notice => 'Settings successfully updated.') }
        format.xml { head :ok }
      else
        format.html { redirect_to("/event_settings/edit_exhibitor_welcome", :notice => 'Update error.') }
        format.xml { render :xml => @event_settings.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit_headers_and_footers
    @tabs = Tab.where(event_id:session[:event_id])

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def update_headers_and_footers

  end

  def show_messages
    @messages = Message.select('messages.id, title, content, message_types.name AS type_name')
                       .joins('JOIN message_types ON message_types.id = messages.message_type')
                       .where(event_id:session[:event_id])
    @event    = Event.find(session[:event_id])

    respond_to do |format|
      format.html {render :layout => 'subevent_2013'}
    end
  end

  def edit_mobile_web_settings
    @mobile_web_setting = MobileWebSetting.where(event_id: session[:event_id]).joins(:mobile_web_setting_type).find(params[:setting_id])
    if @mobile_web_setting.update(content: params[:setting_content], device_type_id: params[:device_type_id], position: params[:position], enabled: params[:enabled])
      render json: {status: 400}
      flash[:notice] = "Web settings successfully updated"
    else
      render json: {errors: @mobile_web_setting.errors.full_messages}
    end
  end

  private

  def set_layout
    if current_user.role? :speaker then
      'speakerportal_2013'
    else
      'subevent_2013'
    end
  end

  def event_setting_params
    params.require(:event_setting).permit(:event_id, :registration_portal, :portal_logo_event_file_id, :portal_banner_event_file_id, :travel_and_lodging_form, :hide_cv, :hide_bio, :sessions_editable, :av_requirements_content, :welcome_screen_content, :support_email_address, :speaker_details_editable, :session_notes_content, :exhibitor_welcome, :speaker_files, :exhibitor_files, :av_requests, :session_files, :twelve_hour_format)
  end

  def event_params
    params.require(:event).permit(:name, :event_start_at, :event_end_at,:timezone, calendar_json:[:filename, :organizer,:event_description]).merge(utc_offset: ActiveSupport::TimeZone[params[:event][:timezone]].now.formatted_offset)
  end

  def write_temp_file
    FileUtils.mkdir_p(@target_path) unless File.directory?(@target_path)
    File.open("#{@target_path}/#{@file_name}", 'wb', 0777) { |f| f.write(@css_text) }
    @file = File.open("#{@target_path}/#{@file_name}")
  end

  def delete_temp_file
    File.delete(@file.path) if File.exists? @file.path
  end
end
