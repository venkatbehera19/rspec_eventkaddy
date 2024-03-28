class HomeButtonsController < ApplicationController

  layout :set_layout
  load_and_authorize_resource
  helper_method :diyContentEnabled, :getDiyMobileWebSettings
  before_action :setDiyLayoutVariables, :except => [:mobile_data]

  before_action :set_cache_buster, :only => [:reset_buttons, :index]

  def set_cache_buster
    ## Prevent page from caching
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"]        = "no-cache"
    response.headers["Expires"]       = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def mobile_data

    @empty_data = "[]"

    if (params[:event_id]) then
      @home_buttons = HomeButton.select('home_buttons.id,home_buttons.name,external_link,position,home_button_types.name AS hb_type_name,event_files.path AS file_url').where(
        "home_buttons.event_id= ? AND home_buttons.id > ? AND home_buttons.enabled = ?",params[:event_id],params[:record_start_id],1).joins('
      LEFT OUTER JOIN event_files ON home_buttons.event_file_id=event_files.id
      JOIN home_button_types ON home_buttons.home_button_type_id=home_button_types.id').order('home_buttons.id ASC').limit(100)

      if (@home_buttons.length > 0) then
        render :json => @home_buttons.to_json, :callback => params[:callback]
      else
        render :json => @empty_data, :callback => params[:callback]
      end

    end

  end

  def disable_home_button
    home_button = HomeButton.find(params[:id])
    list_items  = HomeButton.where(event_id:session[:event_id])

    respond_to do |format|
      if home_button.updatePositionsAndDisable(list_items)
        if current_user.role? :diyclient then
          format.html { redirect_to("/diy_clients/#{event_id}/home_button_icons", :notice => 'Home Button was successfully disabled.') }
        else
          format.html { redirect_to("/home_buttons", :notice => 'Home button was successfully disabled.') }
        end
        format.xml  { head :ok }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @home_button.errors, :status => :unprocessable_entity }
      end
    end
  end

  def enable_home_button

    home_button   = HomeButton.find(params[:id])
    last_position = HomeButton.where(event_id:session[:event_id],enabled:true).order('position ASC').last.position + 1

    respond_to do |format|
      if home_button.update!(enabled:true,position:last_position)

        if current_user.role? :diyclient then
          format.html { redirect_to("/diy_clients/#{event_id}/home_button_icons", :notice => 'Home Button was successfully enabled.') }
        else
          format.html { redirect_to("/home_buttons", :notice => 'Home button was successfully enabled.') }
        end
        format.xml  { head :ok }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @home_button.errors, :status => :unprocessable_entity }
      end
    end
  end

  def reset_buttons

    # Rails.cache.clear Ask Dave what the purpose of this is in Events controller upload actions

    HomeButton.where(event_id:session[:event_id]).destroy_all
    CustomList.where(event_id:session[:event_id]).destroy_all
    CustomListItem.where(event_id:session[:event_id]).destroy_all

    # bootstrap_home_buttons_cmd = Rails.root.join('ek_scripts',"bootstrap-home-buttons.rb \"#{session[:event_id]}\"")

    # import_exhibitor_result = `ROO_TMP='/tmp' ruby #{bootstrap_home_buttons_cmd} 2>&1`
    # Rails::logger.debug "\n--------- import script output ---------\n\n #{import_exhibitor_result} \n------------------- \n"

    HomeButton.new.createHomeButtonsCustomListsAndEventFileRows(session[:event_id])

    respond_to do |format|
      format.html { redirect_to("/home_buttons", :notice => 'Home Buttons Successfully Reset') }
    end

  end

  def index

    @home_buttons          = HomeButton.where(event_id:session[:event_id],enabled:true).order('position ASC')
    @disabled_home_buttons = HomeButton.where(event_id:session[:event_id],enabled:false).order('position ASC')
    content_settings = Setting.return_cordova_ekm_settings(session[:event_id])
		@background_style = content_settings.json ? content_settings.json["background"] : "background-color: initial;"

    respond_to do |format|
      format.html
      format.xml  { render :xml => @home_buttons }
      format.json { render :json => @home_buttons.to_json, :callback => params[:callback] }
    end

  end

  def show

  end

  def new
    @home_button       = HomeButton.new
    @home_buttons      = HomeButton.where(event_id:session[:event_id], enabled: true).order('position ASC')
    @home_button_types = home_button_types
    @attendee_types = attendee_types
    global_poll_type_id   = SurveyType.where(name:'Global Poll')
    daily_poll_type_id    = SurveyType.where(name:'Daily Questions')
    @surveys              = Survey.where(event_id:session[:event_id], survey_type_id: global_poll_type_id) ##Necessary for page refresh
    @daily_surveys        = Survey.where(event_id:session[:event_id], survey_type_id: daily_poll_type_id)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @home_button }
    end
  end

  def create
    home_button_type = HomeButtonType.find_by(id: home_button_params[:home_button_type_id])
    if home_button_type.name == "Daily Health Check"
      params["home_button"]["survey_id"] = params["home_button"]["daily_survey_id"]
    end
    
    # our fake type, Custom List & CE Info
    if params[:home_button][:home_button_type_id] == '0'
      params[:home_button][:home_button_type_id] = HomeButtonType.where(name:'Custom List').first.id
      custom_list_name = 'CE Info'
    end

    params[:home_button][:attendee_type_id] = nil if params[:home_button][:attendee_type_id] == '0'

    @home_buttons         = HomeButton.where(event_id:session[:event_id])
    @home_button          = HomeButton.new(home_button_params)
    @home_button_types    = home_button_types #Necessary for page refresh
    @attendee_types = attendee_types
    global_poll_type_id   = SurveyType.where(name:'Global Poll')
    @surveys              = Survey.where(event_id:session[:event_id], survey_type_id: global_poll_type_id) ##Necessary for page refresh
    @home_button.enabled  = true
    @home_button.event_id = session[:event_id]
    event_id              = session[:event_id]


    @home_button.uploadIcon(params,event_id)
    @home_buttons.createAndUpdatePositions(params[:json],@home_button) unless params[:json].blank?
    @home_button.uploadPdf(params['pdf_file'], event_id)

    respond_to do |format|
      if @home_button.save
        if @home_button.home_button_type.name==="Custom List"
          @home_button.createAssociatedCustomListAndCustomListType custom_list_name
        end

        format.html { redirect_to("/home_buttons", :notice => 'Home button was successfully created.') }
        format.xml  { render :xml => @home_button, :status => :created, :location => @home_button }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @home_button.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @home_button       = HomeButton.find(params[:id])
    @home_buttons      = HomeButton.where(event_id:session[:event_id], enabled: @home_button.enabled).order('position ASC')
    @home_button_types = home_button_types
    @attendee_types = attendee_types
    type_id            = HomeButtonType.where(name:"External Link").first.id
    @external_link     = true if @home_button.home_button_type_id===type_id
    survey_type_id     = HomeButtonType.where(name:"Survey").first.id
    daily_survey_type_id = HomeButtonType.find_by(name:"Daily Health Check").id
    @survey            = true if @home_button.home_button_type_id === survey_type_id
    @daily_survey      = @home_button.home_button_type_id == daily_survey_type_id
    global_poll_type_id   = SurveyType.where(name:'Global Poll')
    daily_poll_type_id    = SurveyType.where(name:'Daily Questions')
    @surveys              = Survey.where(event_id:session[:event_id], survey_type_id: global_poll_type_id) ##Necessary for page refresh
    @daily_surveys        = Survey.where(event_id:session[:event_id], survey_type_id: daily_poll_type_id)

    # set to match the type of our fake home button type if a ce info custom list
    if @home_button.ce_info_custom_list?
      @home_button.home_button_type_id = 0
    end
  end

  def update
    home_button_type = HomeButtonType.find_by(id: home_button_params[:home_button_type_id])
    if home_button_type.name == "Daily Health Check"
      params["home_button"]["survey_id"] = params["home_button"]["daily_survey_id"]
    end

    # our fake type, Custom List & CE Info
    if params[:home_button][:home_button_type_id] == '0'
      params[:home_button][:home_button_type_id] = HomeButtonType.where(name:'Custom List').first.id
      custom_list_name = 'CE Info'
    end

    params[:home_button][:attendee_type_id] = nil if params[:home_button][:attendee_type_id] == '0'

    @home_buttons      = HomeButton.where(event_id:session[:event_id],enabled:true)
    @home_button       = HomeButton.find(params[:id])
    @home_button_types = home_button_types ##Necessary for page refresh
    @attendee_types = attendee_types
    global_poll_type_id   = SurveyType.where(name:'Global Poll')
    @surveys              = Survey.where(event_id:session[:event_id], survey_type_id: global_poll_type_id) ##Necessary for page refresh
    event_id           = session[:event_id]

    @home_buttons.updatePositions(params[:json]) unless params[:json].blank?

    @home_button.uploadIcon(params,event_id)
    @home_button.uploadPdf(params['pdf_file'], event_id)

    respond_to do |format|
      if @home_button.update!(home_button_params)

        if @home_button.home_button_type.name==="Custom List"
          # if there are no custom lists, we can make one, if there is a custom_list_name,
          # we can update the custom list
          if @home_button.custom_lists.first.nil?
            @home_button.createAssociatedCustomListAndCustomListType custom_list_name
          elsif custom_list_name
            custom_list_type = CustomListType.where(name: custom_list_name, user_made: true).first_or_create 
            @home_button.custom_lists.first.update! custom_list_type_id: custom_list_type.id
          else
            custom_list_type = CustomListType.where(name: @home_button.name, user_made: true).first_or_create 
            @home_button.custom_lists.first.update! custom_list_type_id: custom_list_type.id
          end
        end

        if current_user.role? :diyclient then
          format.html { redirect_to("/diy_clients/#{event_id}/home_button_icons", :notice => 'Home Button was successfully updated.') }
        else
          format.html { redirect_to("/home_buttons", :notice => 'Home button was successfully updated.') }
        end
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @home_button.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    home_button  = HomeButton.find(params[:id])
    # home_buttons = HomeButton.where(event_id:session[:event_id])
    # home_button.updatePositionsAndDestroy(home_buttons) ## use this only if deletion occurs before disabling.
    home_button.destroy

    respond_to do |format|
      format.html { redirect_to("/home_buttons", :notice => 'Home button was successfully removed.') }
      format.xml  { head :ok }
    end
  end

  def update_positions
    @home_buttons      = HomeButton.where(event_id:session[:event_id],enabled:true)
    @home_buttons.updatePositions(params[:json]) unless params[:json].blank?
    render json: { data: "Saved!" }
  end

  def mobile_preview
  end

  def mobile_home_page_content
    @event_file_type_id = EventFileType.find_by(name: 'mobile_css')&.id
    @mobile_app_css = EventFile.where(event_id: session[:event_id],
      event_file_type_id: @event_file_type_id).first
    @app_image_type_id = AppImageType.find_by(name: 'banner')&.id
    @banners = AppImage.where(event_id: session[:event_id], parent_id: 0,
      app_image_type_id: @app_image_type_id).order(:position)
    @app_image_type_id = AppImageType.find_by(name: 'background-app-image')&.id
    @bg_image_file = AppImage.where(event_id: session[:event_id], app_image_type_id: @app_image_type_id).order(:position).first&.event_file
    @app_image_type_id = AppImageType.find_by(name: 'minimalist-mode-footer')&.id
    @footer_banners = AppImage.where(event_id: session[:event_id], app_image_type_id: @app_image_type_id).order(:position)
    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_create
    @home_buttons = HomeButton.where(event_id: session[:event_id], enabled: true).includes(:event_file).order(:position)
    render 'mobile_home_page_content', layout: false
  end

  private

  def set_layout
    if current_user.role? :diyclient then
      'diy_features'
    else
      'subevent_2013'
    end
  end

  def home_button_types
    # a fake type to be handled in a special way by create and update methods
    HomeButtonType.all + [OpenStruct.new({id: 0, name:'Custom List & CE Info'})]
  end

  def attendee_types
    # a fake type to be handled in a special way by create and update methods
    [ OpenStruct.new({id: 0, name:'All'}) ].concat AttendeeType.all
  end

  private

  def home_button_params
    params.require(:home_button).permit(:event_id, :home_button_type_id, :event_file_id, :name, :icon_button_name, :position, :survey_id, :attendee_type_id, :enabled, :hide_on_mobile_site, :login_required, :web, :external_link, :show_on_home_feed, :daily_survey_id)
  end

end