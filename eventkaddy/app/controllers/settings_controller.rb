class SettingsController < ApplicationController

  include StyleDictionaries
  include StylesheetPaths
  include JpickerHelper
  include Banners
  include SettingsHelper

  layout 'settings'
  load_and_authorize_resource except: :update_slots_config

  def copy_settings_form
    @longest_setting_name = SettingType.order("CHAR_LENGTH(name) desc").first.name
    @settings = Setting.
      select('settings.*, events.name AS event_name, setting_types.name AS setting_type_name').
      joins(:event).
      joins(:setting_type).
      order('settings.event_id DESC').
      all.
      reject {|s| s.event_id == event_id }
  end

  def post_copy_settings_form
    settings = Setting.where( id: params[:setting_ids] )
    Setting.where(event_id: event_id, setting_type_id: settings.map(&:setting_type_id)).destroy_all
    s = settings.map {|s| s.copy_to_event event_id }
    redirect_to('/settings/copy_settings_form', :notice => "Successfully copied settings.")
  end

  def index

  end

  def cms
    @cms_settings = Setting.return_cms_settings session[:event_id]
    render layout: 'subevent_2013'
  end

  def update_cms_settings
    @cms_settings    = Setting.return_cms_settings session[:event_id]
    params[:setting] = set_check_box_strings_to_booleans(params[:setting])

    msg = @cms_settings.update!(cms_params) ? 'Successfully updated CMS Settings' : 'An error occured'

    if params[:use_these_settings_as_defaults]
      Setting.return_cms_settings( 0 ).update! cms_params
    end

    redirect_to('/settings/cms', notice: msg)
  end

  def admin_cordova
    def update_missing_settings_to_defaults settings
      # puts settings.inspect.red
      missing_settings = Setting.cordova_all_props.map {|r| r[:name].to_sym } - (settings.json && settings.json.keys.map(&:to_sym) || [])
      # puts missing_settings.inspect.red

      default_settings = Setting.cordova_all_props.each_with_object({}) {|r, memo| memo[r[:name].to_sym] = r[:original_ofa_value] }

      # puts default_settings.inspect.yellow

      missing_settings.each do |setting_name|

        # puts setting_name.inspect.red

        if Setting.cordova_all_props.any? {|r| r[:name].to_sym == setting_name }
          # puts default_settings[ setting_name ].inspect
          value = case default_settings[ setting_name ]
                  when 'true'
                    true
                  when 'false'
                    false
                  else
                    default_settings[ setting_name ]
                  end
          settings.send setting_name.to_s + '=', value
        end

      end

      settings
    end

    @cordova_ekm_settings    = Setting.return_cordova_ekm_settings(session[:event_id])
    @cordova_window_settings = Setting.return_cordova_window_settings(session[:event_id])

    update_missing_settings_to_defaults @cordova_ekm_settings
    update_missing_settings_to_defaults @cordova_window_settings

    render layout: 'subevent_2013'
  end

  def update_admin_cordova_settings
    @cordova_ekm_settings    = Setting.return_cordova_ekm_settings(session[:event_id])
    @cordova_window_settings = Setting.return_cordova_window_settings(session[:event_id])

    # we don't have any of these yet
    settings_params = admin_cordova_settings_params
    # settings_params[:window_numbers] = settings_params[:window_numbers] ? settings_params[:window_numbers] : {}
    # settings_params[:window_floats] = settings_params[:window_floats] ? settings_params[:window_floats] : {}

    [settings_params[:EKM_booleans], settings_params[:window_booleans]].each do |settings|
      settings.each do |k, v|
        settings[k] = true if v == '1'
        settings[k] = false if v == '0'
      end
    end

    [settings_params[:EKM_numbers], settings_params[:window_numbers]].each do |settings|
      # Hash[settings.map {|k,v| [k, v.to_i]}] # doesn't work because of the way mutation works with map / each
      settings && (settings.each {|k, v| settings[k] = v.to_i})
    end

    [settings_params[:EKM_floats], settings_params[:window_floats]].each do |settings|
      settings && (settings.each {|k, v| settings[k] = v.to_f})
    end

    ekm_settings    = settings_params[:EKM_booleans].merge(settings_params[:EKM_strings] || {} ).merge(settings_params[:EKM_numbers] || {} ).merge(settings_params[:EKM_floats] || {})
    window_settings = settings_params[:window_booleans].merge(settings_params[:window_strings] || {}).merge(settings_params[:window_numbers] || {}).merge(settings_params[:window_floats] || {})

    msg = if @cordova_ekm_settings.update!(ekm_settings) && @cordova_window_settings.update!(window_settings)
            'Successfully updated admin cordova settings.'
          else
            'An error occured.'
          end
    redirect_to('/settings/admin_cordova', notice: msg)
  end

  def cordova
    @cordova_booleans = Setting.return_cordova_booleans(session[:event_id])
  end

  def qna
    @cordova_booleans = Setting.return_cordova_booleans(session[:event_id])
    @cordova_strings = Setting.return_cordova_strings(session[:event_id])
    @first_qa_session = Session.
      where(event_id: session[:event_id], qa_enabled: true).
      first
  end

  # mobile app settings
  def update_cordova_settings
    @cordova_booleans = Setting.return_cordova_booleans(session[:event_id])

    boolean_settings = set_check_box_strings_to_booleans cordova_setting_boolean_params

    msg = if @cordova_booleans.update!(boolean_settings)
            'Successfully updated mobile app settings.'
          else
            'An error occured.'
          end
    redirect_to('/settings/cordova', notice: msg)
  end

  def update_qna_settings
    @cordova_booleans = Setting.return_cordova_booleans(session[:event_id])
    @cordova_strings = Setting.return_cordova_strings(session[:event_id])

    # originally it was only boolean settings; this could be made
    # more explicit by using name: "boolean_setting[settingname]" as I
    # have done for string_setting
    boolean_settings = set_check_box_strings_to_booleans qna_setting_boolean_params

    # manage radiobutton values; fragile but unfortunately seems to be
    # the simplest way of doing it, as rails radio_tag doesn't seem to
    # account for this sort of usage
    [ :guest_qa_page_use_whitelist_enabled,
      :guest_qa_page_single_question_mode_enabled,
      :guest_qa_page_show_all_questions_mode_enabled ].each {|s|
        boolean_settings[ s ] = false
      }
    if params[:guest_qa_page_type]
      boolean_settings[ params[:guest_qa_page_type].to_sym ] = true
    end

    if params[:guest_qa_page_banner_path]
      params[:string_setting][:guest_qa_page_banner_path] = write_qa_page_banner(
        params[:guest_qa_page_banner_path]
      )
    end

    msg = if @cordova_booleans.update!(boolean_settings) &&
               @cordova_strings.update!(cordova_setting_string_params)
            'Successfully updated Q&A settings.'
          else
            'An error occured.'
          end
    redirect_to('/settings/qna', notice: msg)
  end

  def guest_view
    @guest_view_settings = Setting.return_guest_view_settings(session[:event_id])
    @event_name          = Event.find( session[:event_id] ).name
  end

  def update_guest_view_settings
    @guest_view_settings = Setting.return_guest_view_settings(session[:event_id])

    # originally it was only boolean settings; this could be made
    # more explicit by using name: "boolean_setting[settingname]" as I
    # have done for string_setting
    boolean_settings = set_check_box_strings_to_booleans params[:boolean_setting]

    if params[:leaderboard_logo_path]
      params[:string_setting][:leaderboard_logo_path] =
        write_guest_view_leaderboard_logo( params[:leaderboard_logo_path] )
    end

    msg = if @guest_view_settings.update!(guest_view_boolean_params) &&
            @guest_view_settings.update!(guest_view_string_params)
            'Successfully updated mobile app settings.'
          else
            'An error occured.'
          end
    redirect_to('/settings/guest_view', notice: msg)
  end

  def attendee_portal
    @attendee_portal_settings = Setting.return_attendee_portal_settings(session[:event_id])
    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_initialize
    @tab_type_ids  = TabType.where(portal:"attendee_portal").pluck(:id)
    @tabs          = Tab.where(
                      event_id:session[:event_id],                   tab_type_id:@tab_type_ids
                    ).order(:order)
    if @tabs.length != TabType.where(portal:"attendee_portal").length
      Tab.createDefaults(session[:event_id], "attendee_portal")
      @tabs = Tab.where(
                event_id:session[:event_id],
                tab_type_id:@tab_type_ids
              ).order(:order)
    end
  end

  def update_attendee_portal
    @attendee_portal_settings = Setting.return_attendee_portal_settings(session[:event_id])
    params[:setting]       = set_check_box_strings_to_booleans(params[:setting])
    msg = @attendee_portal_settings.update!(attendee_portal_params) ? 'Successfully updated Attendee Portal Settings' : 'An error occured'
    redirect_to('/settings/attendee_portal', notice: msg)
  end

  def exhibitor_portal
    @exhibitor_portal_settings = Setting.return_exhibitor_portal_settings(session[:event_id])
    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_initialize
    @tab_type_ids  = TabType.where(portal:"exhibitor").pluck(:id)
    @tabs          = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids).order(:order)

    if @tabs.length != TabType.where(portal:"exhibitor").length
      Tab.createDefaults(session[:event_id], "exhibitor")
      @tabs = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids).order(:order)
    end
  end

  def update_exhibitor_portal_settings
    @exhibitor_portal_settings = Setting.return_exhibitor_portal_settings(session[:event_id])
    params[:setting]       = set_check_box_strings_to_booleans_for_exhibitor(params[:setting])

    msg = @exhibitor_portal_settings.update!(exhibitor_portal_settings_params) ? 'Successfully updated Exhibitor Portal Settings' : 'An error occured'
    redirect_to('/settings/exhibitor_portal', notice: msg)
  end

  def update_exhibitor_portal_banner
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
    @event_setting.blank? &&  @event_setting = EventSetting.new
    upload_banner(@event_setting, params, session[:event_id], 'exhibitor', 'exhibitor_banner', @event_setting, :exhibitor_banner_event_file_id)
    msg = (!@event_setting.exhibitor_banner_event_file_id.blank?) ? 'Successfully updated Exhibitor Portal Settings' : 'An error occured'
    redirect_to('/settings/exhibitor_portal', notice: msg)
  end

  def speaker_portal
    @speaker_portal_settings = Setting.return_speaker_portal_settings(session[:event_id])
    @event_setting           = EventSetting.where(event_id:session[:event_id]).first_or_initialize

    # AV Requests
    @av_list_item            = AvListItem.new
    @av_list_items           = AvListItem.all.order(:name).select(:id, :name).to_a.uniq { |item| item[:name] } # order(:name) for some reason is finnicky
    @events_av_list_item_ids = EventsAvListItem.where(event_id: session[:event_id]).pluck(:av_list_item_id)

    # Tabs
    @tab_type_ids  = TabType.where(portal:"speaker").pluck(:id)
    @tabs          = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids).order(:order)

    if @tabs.length != TabType.where(portal:"speaker").length
      Tab.createDefaults(session[:event_id], "speaker")
      @tabs = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids).order(:order)
    end

    # Required Data
    @event_id=session[:event_id]
    @event=Event.where(id:@event_id).first

    @requirements= Requirement.where(event_id:@event_id).joins(:requirement_type)

    if @requirements.length<1 then
      @requirements=Requirement.new()
      @requirements.createDefaults(@event_id)
      @requirements=Requirement.where(event_id:@event_id).joins(:requirement_type)
    end

  end

  def session_form
    @speaker_portal_settings = Setting.return_speaker_portal_settings(session[:event_id])
    if @speaker_portal_settings.fields.nil?
      @speaker_portal_settings.fields = []
      @speaker_portal_settings.save
    end
  end

  def update_speaker_portal_session_form
    @speaker_portal_settings = Setting.return_speaker_portal_settings(session[:event_id])
    is_error = false

    begin
      @forms_data = JSON.parse(params[:formData])
      @forms_data.each do |form_data|
        parsed_data = Nokogiri::HTML.parse(form_data["label"])
        label = parsed_data.children.text
        form_data["name"] = label.strip().split(" ").join("-")
      end
    rescue => exception
      is_error = true
      puts exception
    end

    if can_be_fields? (@forms_data)
      @speaker_portal_settings.fields = @forms_data
      @speaker_portal_settings.save

    else
      @speaker_portal_settings.fields = []
      @speaker_portal_settings.save
    end
    if !is_error
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def other_tags
    @tags = Tag.joins(tags_session: :session).where(tags_sessions:{other_tag: true}).where(session:{event_id: session[:event_id]})
    @event = Event.where(id: session[:event_id]).first
    @tag_type = TagType.where(name: 'session').first
  end

  def other_session_keywords
    @keywords = SessionKeyword.where(event_id: session[:event_id], other_keyword: true).includes(:session, :speaker)
    @event = Event.where(id: session[:event_id]).first
    @tag_type = TagType.where(name: 'session-keywords').first
  end

  def update_speaker_portal_settings
    @speaker_portal_settings = Setting.return_speaker_portal_settings(session[:event_id])
    params[:setting]       = set_check_box_strings_to_booleans(params[:setting])
    msg = @speaker_portal_settings.update!(speaker_portal_settings_params) ? 'Successfully updated Speaker Portal Settings' : 'An error occured'
    redirect_to('/settings/speaker_portal', notice: msg)
  end

  def update_speaker_portal_banner
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
    @event_setting.blank? &&  @event_setting = EventSetting.new
    upload_banner(@event_setting, params, session[:event_id], 'speaker', 'speaker_banner', @event_setting, :speaker_banner_event_file_id)
    msg = (!@event_setting.speaker_banner_event_file_id.blank?) ? 'Successfully updated Speaker Portal Settings' : 'An error occured'
    redirect_to('/settings/speaker_portal', notice: msg)
  end

  def video_portal
    @video_portal_booleans = Setting.return_video_portal_booleans(session[:event_id])
  end


  def update
    @video_portal_booleans = Setting.return_video_portal_booleans(session[:event_id])
    params[:setting]       = set_check_box_strings_to_booleans(params[:setting])

    msg = @video_portal_booleans.update!(update_params) ? 'Successfully updated Video Portal Settings' : 'An error occured'
    redirect_to('/settings/video_portal', notice: msg)
  end

  def program_feed_booleans
    @program_feed_booleans = Setting.return_program_feed_booleans(session[:event_id])
    @event_setting = EventSetting.find_by(event_id: session[:event_id])
  end

  def update_program_feed_booleans
    @program_feed_booleans = Setting.return_program_feed_booleans(session[:event_id])
    params[:setting]       = set_check_box_strings_to_booleans(params[:setting])
    msg = @program_feed_booleans.update!(update_params) ? 'Successfully updated Program Feed Settings' : 'An error occured'

    if  !params[:portal_banner_file].blank?
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first_or_initialize
      upload_banner(@event_setting, params, session[:event_id], 'program_feed', 'program_feed_banner', @event_setting, :program_feed_banner_event_file_id)
    end
    redirect_to('/settings/program_feed_booleans', notice: msg)
  end

  def program_feed_headings
    @event = Event.find_by(id: session[:event_id])
    @program_feed_headings = Setting.return_program_feed_booleans(session[:event_id])
  end

  def update_program_feed_headings
    @program_feed_headings = Setting.return_program_feed_booleans(session[:event_id])
    msg = @program_feed_headings.update!(update_params) ? 'Successfully updated Program Feed Settings' : 'An error occured'
    redirect_to('/settings/program_feed_headings', notice: msg)
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
    render nothing: true

  end

  # def video_portal_strings
  #   @video_portal_strings = Setting.return_video_portal_strings(session[:event_id])
  # end

  def video_portal_headings
    @video_portal_headings = Setting.return_video_portal_headings(session[:event_id])
  end

  def video_portal_contents
    @video_portal_contents = Setting.return_video_portal_contents(session[:event_id])
  end

  def registration_portal_settings
    @registration_portal_settings = Setting.return_registration_portal_settings(session[:event_id])

    # binding.pry

    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_initialize
    @event = Event.find session[:event_id]
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(event_file_type_id:type_id,event_id:session[:event_id], deleted:[nil,false])
    @tab_type_ids  = TabType.where(portal:"attendee").pluck(:id)
    @tabs          = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids).order(:order)
    if @tabs.length != TabType.where(portal:"attendee").length
      Tab.createDefaults(session[:event_id], "attendee")
      @tabs = Tab.where(event_id:session[:event_id], tab_type_id:@tab_type_ids).order(:order)
    end
  end

  def update_registration_portal_settings
    @registration_portal_settings = Setting.return_registration_portal_settings(session[:event_id])
    params[:setting] = set_check_box_strings_to_booleans(params[:setting])
    if  !params[:portal_banner_file].blank?
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first_or_initialize
      upload_banner(@event_setting, params, session[:event_id], 'registration', 'registration_banner', @event_setting, :registration_banner_event_file_id)
    end
    !params[:reg_header_bg_img].blank? && upload_background_image(params[:reg_header_bg_img], 'registration_header_bg_img', 'reg_header_bg_img', @registration_portal_settings, 'reg_header_bg_img')

    !params[:reg_header_content].blank? && upload_background_image(params[:reg_header_content], 'registration_header_content', 'reg_header_content', @registration_portal_settings, 'reg_header_content')

    !params[:body_background_image].blank? && upload_background_image(params[:body_background_image], 'registration_portal_image', 'registration_portal_bg_img', @registration_portal_settings, 'body_background_image')

    msg = @registration_portal_settings.update!(registration_portal_settings_params) ? 'Successfully updated Registration Portal Settings' : 'An error occured'
    redirect_to('/settings/registration_portal_settings', notice: msg)
  end

  def exhibitor_registration_portal_settings
    @registration_portal_settings = Setting.return_exhibitor_registration_portal_settings(session[:event_id])
    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_initialize
    @event = Event.find session[:event_id]
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(event_file_type_id:type_id,event_id:session[:event_id], deleted:[nil,false])
  end

  def update_exhibitor_registration_portal_settings
    @registration_portal_settings = Setting.return_exhibitor_registration_portal_settings(session[:event_id])
    params[:setting] = set_check_box_strings_to_booleans(params[:setting])
    if  !params[:portal_banner_file].blank?
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first_or_initialize
      upload_banner(@event_setting, params, session[:event_id], 'exhibitor_registration', 'exhibitor_registration_banner', @event_setting, :exhibitor_registration_banner_event_file_id)
    end

    !params[:reg_header_bg_img].blank? && upload_background_image(params[:reg_header_bg_img], 'exhibitor_registration_header_bg_img', 'reg_header_bg_img', @registration_portal_settings, 'reg_header_bg_img')

    !params[:reg_header_content].blank? && upload_background_image(params[:reg_header_content], 'exhibitor_registration_header_content', 'reg_header_content', @registration_portal_settings, 'reg_header_content')

    !params[:body_background_image].blank? && upload_background_image(params[:body_background_image], 'exhibitor_registration_portal_image', 'registration_portal_bg_img', @registration_portal_settings, 'body_background_image')

    msg = @registration_portal_settings.update!(registration_portal_settings_params) ? 'Successfully updated Registration Portal Settings' : 'An error occured'
    redirect_to('/settings/exhibitor_registration_portal_settings', notice: msg)
  end

  def speaker_registration_settings
    @speaker_registration_settings = Setting.return_speaker_registration_settings(session[:event_id])
    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_initialize
    @event = Event.find session[:event_id]
  end

  def update_speaker_registration_settings
    @speaker_registration_settings = Setting.return_speaker_registration_settings(session[:event_id])
    params[:setting] = set_check_box_strings_to_booleans(params[:setting])
    if !params[:portal_banner_file].blank?
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first_or_initialize
      upload_banner(
        @event_setting,
        params,
        session[:event_id],
        'speaker_registration',
        'speaker_banner',
        @event_setting,
        :registration_banner_event_file_id
      )
    end

    !params[:body_background_image].blank? && upload_background_image(params[:body_background_image], 'registration_portal_bg_img','speaker_registration_portal_image',  @speaker_registration_settings, 'body_background_image')
    msg = @speaker_registration_settings.update!(speaker_registration_settings_params) ? 'Successfully updated Speaker Registration Settings' : 'An error occured'
    redirect_to('/settings/speaker_registration_settings', notice: msg)
  end

  def simple_registration_settings
    @simple_registration_settings = Setting.return_simple_registration_settings(session[:event_id])
    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_initialize
    @event = Event.find session[:event_id]
  end

  def update_simple_registration_settings
    @simple_registration_settings = Setting.return_simple_registration_settings(session[:event_id])
    params[:setting] = set_check_box_strings_to_booleans(params[:setting])
    if !params[:portal_banner_file].blank?
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first_or_initialize
      upload_banner(@event_setting, params, session[:event_id], 'registration', 'registration_banner', @event_setting, :registration_banner_event_file_id)
    end

    !params[:body_background_image].blank? && upload_background_image(params[:body_background_image], 'simple_registration_portal_image', 'registration_portal_bg_img', @simple_registration_settings, 'body_background_image')

    msg = @simple_registration_settings.update!(simple_registration_settings_params) ? 'Successfully updated Simple Registration Settings' : 'An error occured'
    redirect_to('/settings/simple_registration_settings', notice: msg)
  end

  #deprecated
  # def update_video_portal_strings
  #   @video_portal_strings = Setting.return_video_portal_strings(session[:event_id])

  #   msg = @video_portal_strings.update!(params[:setting]) ? 'Successfully updated Video Portal Settings' : 'An error occured'
  #   redirect_to('/settings/video_portal_strings', notice: msg)
  # end

  def update_video_portal_headings
    type_id = SettingType.where(name:'video_portal_headings').first.id
    if params[:save_as_default] == "1"
      @video_portal_headings = Setting.where(event_id:0, setting_type_id:type_id).first_or_create
      @video_portal_headings.update!(video_portal_headings_params)
    end
    @video_portal_headings = Setting.where(event_id:session[:event_id], setting_type_id:type_id).first_or_create
    msg = @video_portal_headings.update!(video_portal_headings_params) ? 'Successfully updated Video Portal Settings' : 'An error occured'
    redirect_to('/settings/video_portal_headings', notice: msg)
  end

  def update_video_portal_contents
    @video_portal_contents = Setting.return_video_portal_contents(session[:event_id])
    msg = @video_portal_contents.update!(video_portal_contents_params) ? 'Successfully updated Video Portal Settings' : 'An error occured'
    redirect_to('/settings/video_portal_contents', notice: msg)
  end


  def video_portal_styles
    @google_font_families = []
    @styles_by_category = prepare_styles_for_jpicker(
                            Styles.new(file_paths:          [video_portal_stylesheet(session[:event_id]), default_video_portal_stylesheet],
                                       style_dictionary:    video_portal_style_dictionary,
                                       category_dictionary: video_portal_category_dictionary)
                                  .styles_by_category)
  end

  def update_video_portal_styles
    copied_event = params[:event_id]
    puts copied_event
    GenerateStylesheet.new(styles:clean_styles_from_jpicker(params[:styles]), path_to_save:video_portal_stylesheet(session[:event_id])).call

    if params[:copy_settings_to_event] == "1"
      GenerateStylesheet.new(styles:clean_styles_from_jpicker(params[:styles]), path_to_save:video_portal_stylesheet(copied_event)).call
    end

    redirect_to('/settings/video_portal_styles', notice: 'Successfully updated styles.')
  end

  def video_portal_images
    @video_portal_image_types = VideoPortalImageType.all
    @video_portal_images      = VideoPortalImage.select('video_portal_images.*,event_files.cloud_storage_type_id, event_files.path AS path')
                                                .joins('JOIN event_files ON event_files.id = video_portal_images.event_file_id')
                                                .where(event_id:session[:event_id])
  end

  def upload_video_portal_image
    VideoPortalImage.where(event_id:session[:event_id],video_portal_image_type_id:params[:video_portal_image_type_id])
                    .first_or_create
                    .update_image(params[:image_file], params[:link])
    redirect_to('/settings/video_portal_images', notice: 'Successfully updated image.')
  end

  def destroy_video_portal_image
    if VideoPortalImage.find(params[:video_portal_image_id]).destroy
      redirect_to('/settings/video_portal_images', notice: 'Successfully destroyed image.')
    else
      redirect_to('/settings/video_portal_images', notice: 'Failed to remove image.')
    end
  end

  def video_portal_reporting
    @status = EventStatusOnReportingDb.new(Event.find(session[:event_id])).call
  end

  def update_video_portal_reporting
    event = Event.find session[:event_id]
    resp  = JSON.parse(CreateEventOnReportingDb.new(event).call)
    if resp['status'] == 'true'
      redirect_to('/settings/video_portal_reporting', notice: 'Successfully added event to reporting.')
    else
      redirect_to('/settings/video_portal_reporting', notice: 'Update failed.')
    end
  end

  def send_test_email
    case params[:type]
    when "attendee_email_password_template"
      attendee = Example.attendee
      email = EmailsQueue.new( email: params[:email], event_id: event_id)
      AttendeeMailer.set_and_email_password(email, attendee).deliver
      attendee.destroy # when setting the password, it will be committed to the db... so just delete it
    when "attendee_email_confirmation_template"
      attendee = Example.attendee
      attendee.email = params[:email]
      email = EmailsQueue.new( email: params[:email], event_id: event_id)
      AttendeeMailer.registration_confirmation(event_id, attendee).deliver
      attendee.destroy # when setting the password, it will be committed to the db... so just delete it
    when "speaker_email_confirmation_template"
      speaker = Example.speaker
      speaker.email = params[:email]
      email = EmailsQueue.new( email: params[:email], event_id: event_id)
      SpeakerMailer.registration_confirmation(event_id, speaker).deliver
      speaker.destroy
    when "speaker_email_password_template"
      speaker = Example.speaker
      speaker.email = params[:email]
      speaker.save! # needed for user
      SpeakerMailer.speaker_email_password(event_id, speaker).deliver
      speaker.destroy # when setting the password, it will be committed to the db... so just delete it
    when "speaker_numeric_password_template"
      speaker = Example.speaker
      speaker.email = params[:email]
      speaker.save! # needed for user
      email = EmailsQueue.new( email: params[:email], event_id: event_id )
      SpeakerMailer.speaker_numeric_password(event_id, speaker).deliver
      speaker.destroy
    when "exhibitor_email_password_template"
      exhibitor = Example.exhibitor
      exhibitor.save! # needed for user
      email = EmailsQueue.new( email: params[:email], event_id: event_id )
      ExhibitorMailer.set_and_email_password(email, exhibitor).deliver
      exhibitor.user.destroy # user will be created automatically, so just clean it up
      exhibitor.destroy # when setting the password, it will be committed to the db... so just delete it
    when "calendar_invitation_email_template"
      attendee = Example.attendee
      attendee.email = params[:email]
      email = EmailsQueue.new( email: params[:email], event_id: event_id)
      CalendarInviteMailer.invite(event_id, attendee).deliver
    when "registration_attendee_email_password_template"
      attendee = Example.attendee
      attendee.email = params[:email]
      attendee.save!
      AttendeeMailer.registration_attendee_email_password(event_id, attendee).deliver
      attendee.destroy
    when "registration_attendee_receipt_template"
      attendee = Example.attendee
      attendee.email = params[:email]
      attendee.save!
      order = OrderItem.last.order
      AttendeeMailer.registration_attendee_receipt(event_id, attendee, order).deliver
      attendee.destroy
    when "exhibitor_receipt_template"
      exhibitor = Example.exhibitor
      exhibitor.email = params[:email]
      exhibitor.save!
      order = OrderItem.last.order
      ExhibitorMailer.send_recipt(event_id, exhibitor, order).deliver
      exhibitor.destroy
    end

    redirect_to("/settings/#{params[:type]}", notice:  "Test Email Sent to #{params[:email]}")
  end

  def attendee_email_password_template
    @event = Event.find session[:event_id]
    @template = EmailTemplate.email_password_template_for( session[:event_id], "attendee_email_password_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(
      event_file_type_id: type_id,
      event_id: session[:event_id],
      deleted: [nil,false]
    )
  end

  def update_attendee_email_password_template
    send_numeric_password = ( params[:send_numeric_password] == 'on' || params[:send_numeric_password] == 'true' )
    send_qr_code = ( params[:send_qr_code] == 'on' || params[:send_qr_code] == 'true' )
    @event = Event.find session[:event_id]
    @event.update!(send_attendees_numeric_password: send_numeric_password) unless @event.send_attendees_numeric_password?.eql? send_numeric_password
    @event.update!(send_qr_code: send_qr_code) unless @event.send_qr_code?.eql? send_qr_code
    update_email_password_template 'attendee_email_password_template'
  end

  def attendee_email_confirmation_template
    @template          = EmailTemplate.email_password_template_for( session[:event_id], "attendee_email_confirmation_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(event_file_type_id:type_id,event_id:session[:event_id], deleted:[nil,false])
  end

  def registration_attendee_email_password_template
    @template = EmailTemplate.email_password_template_for( session[:event_id], "registration_attendee_email_password_template" )
    @event = Event.find session[:event_id]
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(
                          event_file_type_id: type_id,
                          event_id: session[:event_id],
                          deleted: [nil,false]
                        )
  end

  def update_registration_attendee_email_password_template
    update_email_password_template 'registration_attendee_email_password_template'
  end

  def registration_attendee_email_confirmation_template
    @template = EmailTemplate.email_password_template_for( session[:event_id], "registration_attendee_confirmation_email_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(
                          event_file_type_id: type_id,
                          event_id: session[:event_id],
                          deleted: [nil,false]
                        )
  end

  def registration_attendee_receipt_template
    @template = EmailTemplate.email_password_template_for( session[:event_id], "registration_attendee_receipt_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(
                          event_file_type_id: type_id,
                          event_id: session[:event_id],
                          deleted: [nil,false]
                        )
  end

  def update_registration_attendee_receipt_template
    update_email_password_template 'registration_attendee_receipt_template'
  end

  def exhibitor_receipt_template
    @template = EmailTemplate.email_password_template_for( session[:event_id], "exhibitor_receipt_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(
                          event_file_type_id: type_id,
                          event_id: session[:event_id],
                          deleted: [nil,false]
                        )
  end

  def update_registration_attendee_receipt_template
    update_email_password_template 'exhibitor_receipt_template'
  end

  def speaker_email_confirmation_template
    @template          = EmailTemplate.email_password_template_for( session[:event_id], "speaker_email_confirmation_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(
                          event_file_type_id: type_id,
                          event_id: session[:event_id],
                          deleted: [nil,false]
                        )
  end

  def calendar_invitation_email_template
    @template          = EmailTemplate.email_password_template_for( session[:event_id], "calendar_invitation_email_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(event_file_type_id:type_id,event_id:session[:event_id], deleted:[nil,false])
  end

  def update_calendar_invitation_email_template
    update_email_password_template 'calendar_invitation_email_template'
  end

  def upload_email_template_image
    if (params[:event_file]!='' && params[:event_file]!=nil) then
      @event_file          = EventFile.new
      @event_file.event_id = session[:event_id]
      @event_file.entryImage(params, "email_template_image")
      respond_to do |format|
        if @event_file.save
          format.html { redirect_to( request.referer , :notice => 'Entry was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { redirect_to( request.referer , :alert => 'Something went wrong.') }
          format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def get_email_template_image
    type_id = EventFileType.find_by_name("email_template_image").id

    if EventFile.where(event_file_type_id:type_id).length > 0
      event_file = EventFile.where(event_file_type_id:type_id).last
      render :json => { "path": event_file.path, "id": event_file.id }
    else
      render :json => ""
    end
  end

  def update_attendee_email_confirmation_template
    update_email_password_template 'attendee_email_confirmation_template'
  end

  def update_speaker_email_confirmation_template
    update_email_password_template 'speaker_email_confirmation_template'
  end

  def speaker_email_password_template
    @template = EmailTemplate.email_password_template_for( session[:event_id], "speaker_email_password_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(
                          event_file_type_id: type_id,
                          event_id: session[:event_id],
                          deleted: [nil,false]
                        )
  end

  def update_speaker_email_password_template
    update_email_password_template 'speaker_email_password_template'
  end

  def speaker_numeric_password_template
    @template = EmailTemplate.email_password_template_for( session[:event_id], "speaker_numeric_password_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(
                          event_file_type_id: type_id,
                          event_id: session[:event_id],
                          deleted: [nil,false]
                        )
  end

  def update_speaker_numeric_password_template
    update_email_password_template 'speaker_numeric_password_template'
  end

  def exhibitor_email_password_template
    @template = EmailTemplate.email_password_template_for( session[:event_id], "exhibitor_email_password_template" )
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event_files       = EventFile.where(
      event_file_type_id: type_id,
      event_id: session[:event_id],
      deleted: [nil,false]
    )
  end

  def update_exhibitor_email_password_template
    update_email_password_template 'exhibitor_email_password_template'
  end

  def ce_certificate_email_template
    @template = EmailTemplate.email_password_template_for( session[:event_id], "ce_certificate_email_template" )
  end

  def update_ce_certificate_email_template
    update_email_password_template 'ce_certificate_email_template'
  end

  def member_subscribe_email_template
    @template = OrganizationEmailTemplate.email_password_template_for( session[:event_id], "member_subscribe_email_template")
    org_id = Event.find(session[:event_id]).org_id
    @members = User.joins(:roles, :organizations).where(roles: {name: "Member"}).where(organizations: {id: org_id}).select{|user| user.is_subscribed == true}
    type_id            = EventFileType.find_by_name("email_template_image").id
    @org_files         = OrganizationFile.where(event_file_type_id:type_id , organization_id: org_id, deleted: [nil, false])
  end

  def member_unsubscribe_email_template
    @template = OrganizationEmailTemplate.email_password_template_for( session[:event_id], "member_unsubscribe_email_template")
    org_id = Event.find(session[:event_id]).org_id
    @members = User.joins(:roles, :organizations).where(roles: {name: "Member"}).where(organizations: {id: org_id}).select{|user| user.is_subscribed == false}
    type_id            = EventFileType.find_by_name("email_template_image").id
    @org_files         = OrganizationFile.where(event_file_type_id:type_id , organization_id: org_id, deleted: [nil, false])
  end

  def upload_email_template_image_organization
    if (params[:event_file]!='' && params[:event_file]!=nil)
      event = Event.find_by_id(session[:event_id])
      organization = event.organization
      file_upload = OrganizationFile.upload_email_image(params, organization, session[:event_id])

      respond_to do |format|
        if file_upload
          format.html { redirect_to( request.referer , :notice => 'Entry was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { redirect_to( request.referer , :alert => 'Something went wrong.') }
          format.xml  { render :xml => @organization_file.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def get_email_template_image_organization
    type_id = EventFileType.find_by_name("email_template_image").id
    org_file = OrganizationFile.where(event_file_type_id: type_id).last
    if org_file
      url = org_file.file_path(session[:event_id])["url"]
      render :plain => url
    else
      render :plain => ""
    end
  end


  def update_slots_config
    time_duration         = slots_param[:end_time].to_time - slots_param[:start_time].to_time
    (redirect_to("/exhibitor_portals/timeslot_bookings", alert: 'Invalid time range') and return) if time_duration < 0
    type_id               = SettingType.where(name:'exhibitor_timeslots').first.id
    @setting              = Setting.where(event_id:session[:event_id], setting_type_id:type_id).first_or_initialize
    @setting.assign_attributes(slots_param)
    if @setting.save
      redirect_to("/exhibitor_portals/timeslot_bookings", notice: 'Settings updates successfully!')
    else
      redirect_to("/exhibitor_portals/timeslot_bookings", alert: @setting.errors.to_sentence)
    end
  end

  def attendee_badge
    @attendee_badge_settings = Setting.return_attendee_badge_settings(session[:event_id])
    @event_setting = EventSetting.where(event_id:session[:event_id]).first_or_initialize
    @event = Event.find session[:event_id]
  end

  def update_attendee_badge_settings
    @attendee_badge_settings = Setting.return_attendee_badge_settings(session[:event_id])
    params[:setting] = set_check_box_strings_to_booleans(params[:setting])
    if !params[:portal_banner_file].blank?
      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first_or_initialize
      upload_banner(@event_setting, params, session[:event_id], 'attendee_badge', 'attendee_badge_portal_banner', @event_setting, :attendee_badge_portal_banner_event_file_id)
    end

    !params[:body_background_image].blank? && upload_background_image(params[:body_background_image], 'attendee_badge_portal_bg_banner', 'attendee_badge_portal_bg_img', @attendee_badge_settings, 'body_background_image')

    msg = @attendee_badge_settings.update!(attendee_badge_portal_settings_params) ? 'Successfully updated Attendee Badge Portal Settings' : 'An error occured'

    redirect_to('/settings/attendee_badge', notice: msg)
  end

  private

  def upload_background_image(image_file, event_file_type_name, filename, event_file_owner, event_file_assoc_column)
    event_file_type_id      = EventFileType.where(name: event_file_type_name).first.id
    file_extension          = File.extname image_file.original_filename
    # filename                = filename + file_extension
    event_file              = EventFile.where(event_id:session[:event_id],event_file_type_id:event_file_type_id).first_or_initialize
    cloud_storage_type_id   = Event.find(session[:event_id]).cloud_storage_type_id
    cloud_storage_type      = nil
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s).to_path,
      new_filename:            "#{filename}_#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}",
      event_file_owner: event_file_owner,
      event_file_assoc_column: event_file_assoc_column,
      cloud_storage_type:      cloud_storage_type
    ).call
    return event_file.id
  end

  def update_email_password_template type
    template = EmailTemplate.email_password_template_for( session[:event_id], type )
    if template.update!( email_subject: params[:email_template][:email_subject] ,content: params[:email_template][:content]  )
      redirect_to("/settings/#{type}", notice: 'Template update successfully!')
    else
      redirect_to("/settings/#{type}", alert: template.errors.messages )
    end
  end

  def set_check_box_strings_to_booleans(hash)
    hash.each do |k, v|
      hash[k] = true if v == '1' || v == 'true'
      hash[k] = false if v == '0' || v == 'false'
    end
    hash
  end

  def set_check_box_strings_to_booleans_for_exhibitor(hash)
    hash.each do |k, v|
      if k != 'limit_no_of_staffs'
        hash[k] = true if v == '1' || v == 'true'
        hash[k] = false if v == '0' || v == 'false'
      end
    end
    hash
  end

  def write_guest_view_leaderboard_logo image
    write_image image, "/event_data/#{session[:event_id]}/guest_view_images"
  end

  def write_qa_page_banner image
    write_image image, "/event_data/#{session[:event_id]}/qa_page_images"
  end

  def write_image image, rel_path
    rel_path = "/event_data/#{session[:event_id]}/qa_page_images"
    target_path = Rails.root.join(
      "public#{rel_path}"
    ).to_path

    FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
    full_path = "#{target_path}/#{image.original_filename}"
    File.open( full_path, 'wb', 0777) {|f| f.write(image.read) }
    "#{ rel_path }/#{image.original_filename}"
  end

  private

  # def program_feed_booleans_params
  #   params.require(:setting).permit(:program_feed,:load_banner_image,:enable_search_bar,:sessions_by_tag,:sessions_by_speaker,:sessions_by_audience_tag)
  # end

  def video_portal_headings_params
    params.require(:setting).permit(:html_title, :ga_key, :video_portal_bgcolor, :photo_gallery_url, :game_url, :landing, :dashboard_heading, :dashboard_menu_name, :session_menu_name, :on_demand_menu_name,
       :exhibitor_menu_name, :networking_menu_name, :blog_menu_name, :notifications_menu_name, :survey_menu_name, :help_menu_name, :photo_gallery_menu_name, :booked_slots_menu_name,
       :game_menu_name, :messaging_menu_name, :session_heading_days, :session_heading_speakers, :session_heading_favorites, :session_heading_ce, :timeslots_booking_label, :exhibitor_chat_label,
       :session_heading_search, :exhibitor_heading_gallery, :exhibitor_heading_letter, :exhibitor_heading_alphabet, :exhibitor_heading_sponsers, :exhibitor_heading_categories, :screen_label,
       :exhibitor_heading_search, :session_menu_days, :on_demand, :session_menu_session_tag, :session_menu_audience_tag, :session_menu_speakers, :session_menu_favorites, :session_menu_ce, :session_menu_search,
       :exhibitor_menu_sponser, :exhibitor_menu_alphabetically, :exhibitor_menu_category, :exhibitor_menu_search, :attendee_menu_alphabetically, :attendee_menu_category, :attendee_menu_search,
       :session_info_label, :session_speaker_info_label, :session_files_label, :session_feedback_label, :session_qa_label, :session_notes_label, :session_polling_label, :session_claim_ce_label,
       :exhibitor_info_label, :exhibitor_misc_label,  :exhibitor_files_label, :exhibitor_notes_label, :exhibitor_contact_label, :exhibitor_products_label, :exhibitor_links_label, :exhibitor_messages_label, :exhibitor_staffs_label)
  end

  def video_portal_contents_params
    params.require(:setting).permit(:dashboard_title, :dashboard_slider, :login_text, :external_ce_text, :internal_ce_text, :help_text, :standby_screen_text)
  end

  def cms_params
    params.require(:setting).permit(:show_config_page_edit_preset_tags_button, :hide_config_page_import_export_row_sessions, :hide_config_page_import_export_row_sessions_full, :hide_config_page_import_export_row_delete_session_tags,
       :hide_config_page_import_export_row_speakers, :hide_config_page_import_export_row_exhibitors, :hide_config_page_import_export_row_maps, :hide_config_page_import_export_row_attendees, :hide_config_page_import_export_row_notifications,
       :hide_config_page_import_export_row_home_buttons, :tag_date_loc_meta_data, :hide_statistics_page_game, :hide_menu_registrations_header, :hide_menu_sessions, :hide_menu_speakers, :hide_menu_rooms, :hide_menu_conference_notes,
       :hide_menu_attendees, :hide_menu_settings_header, :hide_menu_education_managers, :hide_menu_feedback_summary, :hide_menu_maps_rooms_header, :hide_menu_game_header, :hide_menu_exhibitors, :hide_menu_booths, :hide_menu_reports_header, :hide_menu_settings, :hide_menu_portal_settings,
       :hide_menu_mobile_and_app_settings, :hide_menu_app_game, :hide_menu_surveys, :hide_menu_scavenger_hunts, :hide_menu_import_export, :hide_menu_home_screen_icons_app, :hide_menu_home_screen_icons_mobile, :hide_menu_banners,
       :hide_menu_event_maps, :hide_menu_notifications, :hide_menu_portal_messages, :hide_menu_speaker_portal_header, :hide_menu_speaker_pdfs, :hide_menu_room_layouts, :show_menu_app_message_threads,
       :hide_menu_flare_photos_link, :hide_menu_video_views, :hide_menu_ce_certificates, :hide_menu_custom_emails, :hide_menu_exhibitor_portal_global_configs, :hide_session_file_index_select_sessions_to_add_session_files_to, :hide_session_file_index_add_session_file_to_all_sessions,
       :hide_session_file_index_finalize_all_sessions_files, :hide_session_file_index_select_session_files_to_publish, :hide_attendee_index_multiple_new_for_all, :hide_attendee_index_bulk_add_attendee_photos,
       :hide_attendee_index_bulk_set_attendees_photos_to_online, :hide_attendee_index_app_message, :hide_exhibitor_index_add_exhibitor_files_to_placeholders, :hide_exhibitor_index_booth_owners_multiple_new,
       :hide_exhibitor_show_page_media_files, :hide_exhibitor_show_page_edit_custom_content, :hide_exhibitor_show_page_exhibitor_products, :hide_speaker_index_bulk_add_speaker_photos, :hide_speaker_index_bulk_set_speakers_photos_to_online,
       :hide_session_index_add_files_to_placeholders, :hide_session_index_bulk_add_session_thumbnails, :hide_session_index_select_pdf_date, :hide_session_show_page_speakers_button, :hide_session_show_page_sponsors_button,
       :hide_session_show_page_session_tags_button, :hide_session_show_page_session_files_button, :hide_session_show_page_media_files_button, :show_session_show_page_audience_tags_button, :show_session_show_page_av_requests_button,
       :show_session_show_page_room_layouts_button, :hide_session_form_next_previous_buttons, :hide_session_form_session_code, :hide_session_form_title, :hide_session_form_description, :hide_session_form_session_cancelled,
       :hide_session_form_qa_enabled, :hide_session_form_is_poster, :hide_session_form_sold_out, :hide_session_form_wvctv, :hide_session_form_embedded_video_url, :hide_session_form_thumbnail_event_file, :hide_session_form_learning_objective,
       :hide_session_form_credit_hours, :hide_session_form_program_type, :hide_session_form_date, :hide_session_form_start_at, :hide_session_form_end_at, :hide_session_form_sessions_speakers, :hide_session_form_location_mapping_id,
       :hide_session_form_published, :hide_session_form_unpublished, :hide_session_form_video_thumbnail, :hide_session_form_video_android, :hide_session_form_video_ipad, :hide_session_form_price, :hide_session_form_capacity,
       :hide_session_form_ticketed, :hide_session_form_race_approved, :hide_session_form_poster_number, :hide_session_form_tag_twitter, :hide_session_form_timezone_offset, :hide_session_form_record_type, :hide_session_form_video_iphone,
       :hide_session_form_video_duration, :hide_session_form_track_subtrack, :hide_session_form_session_file_urls, :hide_session_form_survey_url, :hide_session_form_poll_url, :hide_session_form_custom_fields, :hide_session_form_tags_safeguard,
       :hide_session_form_custom_filter_1, :hide_session_form_custom_filter_2, :hide_session_form_custom_filter_3, :hide_session_form_feedback_enabled, :hide_session_form_promotion, :hide_session_form_keyword, :hide_session_form_premium_access,
       :hide_session_form_video_file_location, :hide_attendee_form_photo_file, :hide_attendee_form_online_url, :hide_attendee_form_account_code, :hide_attendee_form_first_name, :hide_attendee_form_last_name, :hide_attendee_form_honor_prefix,
       :hide_attendee_form_honor_suffix, :hide_attendee_form_business_unit, :hide_attendee_form_title, :hide_attendee_form_business_phone, :hide_attendee_form_mobile_phone, :hide_attendee_form_email, :hide_attendee_form_company,
       :hide_attendee_form_assignment, :hide_attendee_form_custom_filter_1, :hide_attendee_form_username, :hide_attendee_form_password, :hide_attendee_form_authy_id, :hide_attendee_form_biography, :hide_attendee_form_messaging_opt_out,
       :hide_attendee_form_app_listing_opt_out, :hide_attendee_form_game_opt_out, :hide_attendee_form_is_demo, :hide_attendee_form_country, :hide_attendee_form_state, :hide_attendee_form_city, :hide_attendee_form_notes_email,
       :hide_attendee_form_notes_email_pending, :hide_attendee_form_temp_photo_filename, :hide_attendee_form_photo_filename, :hide_attendee_form_iattend_sessions, :hide_attendee_form_validar_url, :hide_attendee_form_publish,
       :hide_attendee_form_twitter_url, :hide_attendee_form_facebook_url, :hide_attendee_form_linked_in, :hide_attendee_form_attendee_type_id, :hide_attendee_form_first_run_toggle, :hide_attendee_form_video_portal_first_run_toggle,
       :hide_attendee_form_custom_filter_2, :hide_attendee_form_custom_filter_3, :hide_attendee_form_token, :hide_attendee_form_tags_safeguard, :hide_attendee_form_speaker_biography, :hide_attendee_form_travel_info, :hide_attendee_form_table_assignment,
       :hide_attendee_form_custom_fields_1, :hide_attendee_form_custom_fields_2, :hide_attendee_form_custom_fields_3, :hide_attendee_form_premium_member, :hide_attendee_profile_form_first_name, :hide_attendee_profile_form_last_name,
       :hide_attendee_profile_form_business_unit, :hide_attendee_profile_form_title, :hide_attendee_profile_form_business_phone, :hide_attendee_profile_form_mobile_phone, :hide_attendee_profile_form_email, :hide_attendee_profile_form_company,
       :hide_attendee_profile_form_twitter_url, :hide_attendee_profile_form_facebook_url, :hide_attendee_profile_form_linked_in, :hide_attendee_profile_form_honor_prefix, :hide_attendee_profile_form_honor_suffix, :hide_attendee_profile_form_biography,
       :hide_attendee_profile_form_country, :hide_attendee_profile_form_state, :hide_attendee_profile_form_city, :hide_attendee_profile_form_custom_filter_3, :hide_attendee_profile_form_custom_fields_1, :hide_attendee_profile_form_custom_fields_2,
       :hide_attendee_profile_form_custom_fields_3, :hide_speaker_form_event_file_photo, :hide_speaker_form_event_file_cv, :hide_speaker_form_online_url, :hide_speaker_form_first_name, :hide_speaker_form_last_name, :hide_speaker_form_email,
       :hide_speaker_form_honor_prefix, :hide_speaker_form_honor_suffix, :hide_speaker_form_title, :hide_speaker_form_city, :hide_speaker_form_state, :hide_speaker_form_country, :hide_speaker_form_zip, :hide_speaker_form_work_phone,
       :hide_speaker_form_mobile_phone, :hide_speaker_form_home_phone, :hide_speaker_form_fax, :hide_speaker_form_middle_initial, :hide_speaker_form_company, :hide_speaker_form_address1, :hide_speaker_form_address2, :hide_speaker_form_address3,
       :hide_speaker_form_financial_disclosure_section, :hide_speaker_form_fd_tax_id, :hide_speaker_form_fd_pay_to, :hide_speaker_form_fd_street_address, :hide_speaker_form_fd_city, :hide_speaker_form_fd_state, :hide_speaker_form_fd_zip,
       :hide_speaker_form_biography, :hide_speaker_form_notes, :hide_speaker_form_availability_notes, :hide_speaker_form_financial_disclosure, :hide_speaker_form_unpublished, :hide_speaker_form_photo_filename, :hide_speaker_form_speaker_code,
       :hide_speaker_form_twitter_url, :hide_speaker_form_facebook_url, :hide_speaker_form_linked_in, :hide_speaker_form_custom_filter_1, :hide_speaker_form_custom_filter_2, :hide_speaker_form_custom_filter_3, :hide_speaker_form_event_file_fd,
       :hide_speaker_form_speaker_type_id, :hide_speaker_form_unsubscribed, :hide_speaker_form_token, :hide_exhibitor_form_online_url, :hide_exhibitor_form_logo, :hide_exhibitor_form_portal_logo_file, :hide_exhibitor_form_company_name,
       :hide_exhibitor_form_description, :hide_exhibitor_form_message, :hide_exhibitor_form_address_line1, :hide_exhibitor_form_address_line2, :hide_exhibitor_form_city, :hide_exhibitor_form_state, :hide_exhibitor_form_zip, :hide_exhibitor_form_country,
       :hide_exhibitor_form_phone, :hide_exhibitor_form_url_web, :hide_exhibitor_form_url_twitter, :hide_exhibitor_form_url_facebook, :hide_exhibitor_form_url_linkedin, :hide_exhibitor_form_url_rss, :hide_exhibitor_form_url_instagram,
       :hide_exhibitor_form_url_youtube, :hide_exhibitor_form_contact_name, :hide_exhibitor_form_email, :hide_exhibitor_form_is_sponsor, :hide_exhibitor_form_sponsor_type, :hide_exhibitor_form_location_mapping_id, :hide_exhibitor_form_unpublished,
       :hide_exhibitor_form_fax, :hide_exhibitor_form_contact_title, :hide_exhibitor_form_contact_title_two, :hide_exhibitor_form_contact_name_two, :hide_exhibitor_form_contact_email_two, :hide_exhibitor_form_contact_mobile_two, :hide_exhibitor_form_url_tiktok,
       :hide_exhibitor_form_toll_free, :hide_exhibitor_form_unsubscribed, :hide_exhibitor_form_token, :hide_exhibitor_form_custom_fields, :hide_exhibitor_form_tags_safeguard, :hide_exhibitor_form_exhibitor_code, :hide_notification_form_iattend_session_codes_filter,
       :hide_notification_form_pn_filters, :hide_menu_general_portal_settings, :hide_menu_speaker_portal_settings, :hide_menu_statistics, :hide_menu_game_statistics, :hide_menu_report_downloads, :hide_config_page_export_mobile_css, :hide_notification_form_unpublish_option,
       :hide_menu_exhibitor_portal_settings, :hide_menu_mobile_app_booleans, :hide_menu_qna_page_settings, :hide_menu_guest_view_settings, :hide_menu_video_portal_booleans, :hide_menu_templates_header, :show_session_show_page_get_video_url, :show_session_show_page_encode_video,
       :hide_menu_video_portal_strings, :hide_menu_video_portal_headings, :hide_menu_video_portal_contents, :hide_menu_video_portal_styles, :hide_menu_video_portal_images, :hide_menu_registration_portal_settings, :show_session_show_page_search_for_encoded_video,
       :hide_menu_simple_registration_settings,:hide_menu_speaker_registration_settings, :hide_menu_speaker_email_password_template, :hide_menu_speaker_email_confirmation_template, :hide_menu_app_virtual_config_header, :hide_menu_video_portal_header, :hide_menu_event_settings, :show_session_show_page_video_thumbnail, :hide_session_form_encoded_videos,
       :hide_menu_attendee_email_password_template, :hide_menu_attendee_email_confirmation_template, :hide_menu_calendar_invitation_email_template, :hide_menu_exhibitor_email_password_template, :hide_reports_view_attendee_email, :hide_reports_view_attendee_mobile_phone, :hide_reports_view_attendee_business_phone, :hide_exhibitor_portal_attendee_email,
       :hide_exhibitor_portal_attendee_mobile_phone, :hide_exhibitor_portal_attendee_business_phone, :hide_settings_tab_event_settings, :hide_attendee_table_attendee_photo, :hide_session_form_on_demand, :hide_exhibitor_form_contact_email,
       :hide_menu_event_settings, :hide_menu_video_portal_header, :hide_menu_templates_header, :show_session_show_page_get_video_url, :show_session_show_page_encode_video, :show_session_show_page_search_for_encoded_video, :show_session_show_page_video_thumbnail, :hide_session_form_encoded_videos,
       #:hide_attendee_table_attendee_first_name,
       #:hide_attendee_table_attendee_last_name,
       :hide_attendee_table_attendee_business_unit,
       :hide_attendee_table_attendee_title,
       #:hide_attendee_table_attendee_company,
       :hide_attendee_table_attendee_email,
       :hide_attendee_table_attendee_registration_id,
       :hide_exhibitor_index_bulk_set_exhibitors_photos_to_online,
       :hide_menu_polls,:hide_menu_session_polls,:hide_menu_app_forms,:hide_menu_event_tickets,
       :hide_menu_program_feed_header,:hide_menu_program_feed_booleans,:hide_menu_program_feed_headings,:hide_menu_program_feed_styles, :hide_menu_products_header, :hide_menu_product_categories, :hide_menu_products,
       :hide_menu_mode_of_payment, :hide_menu_exhibitor_registration_portal_settings, :hide_menu_purchases, :hide_menu_exhibitor_purchases, :hide_menu_attendee_badges, :hide_menu_registration_attendee_email_password_template,
       :hide_menu_registration_attendee_email_confirmation_template,:hide_menu_speaker_numeric_password_template, :hide_menu_custom_form, :hide_menu_registration_attendee_receipt, :hide_menu_attendee_portal_settings, :hide_menu_attendee_purchases, :hide_menu_transactions, :hide_menu_product_coupons, :hide_menu_webhook_transactions, :hide_menu_item_purchases, :hide_menu_exhibitor_receipt_template, :hide_menu_exhibitor_pdfs, :hide_menu_attendee_badge_settings, :hide_menu_download_request, :hide_attendee_form_badge_name, :hide_menu_transactions_header
      )
  end

  def speaker_portal_settings_params
    params.require(:setting).permit(:locked_photo_file, :locked_speaker_form_online_url, :locked_cv_file, :locked_fd_file, :locked_first_name, :locked_middle_initial, :locked_last_name, :locked_email, :locked_honor_prefix, :locked_honor_suffix, :locked_company,
       :locked_address1, :locked_address2, :locked_address3, :locked_city, :locked_state, :locked_country, :locked_zip, :locked_work_phone, :locked_mobile_phone, :locked_home_phone, :locked_fax, :locked_biography, :locked_notes, :locked_availability_notes,
       :locked_financial_disclosure, :locked_fd_tax_id, :locked_fd_pay_to, :locked_fd_street_address, :locked_fd_city, :locked_fd_state, :locked_fd_zip, :hide_photo_file, :hide_speaker_form_online_url, :hide_cv_file, :hide_fd_file, :hide_first_name, :hide_middle_initial,
       :hide_last_name, :hide_email, :hide_honor_prefix, :hide_honor_suffix, :hide_company, :hide_address1, :hide_address2, :hide_address3, :hide_city, :hide_state, :hide_country, :hide_zip, :hide_work_phone, :hide_mobile_phone, :hide_home_phone, :hide_fax, :hide_biography,
       :hide_notes, :hide_availability_notes, :hide_financial_disclosure, :hide_fd_tax_id, :hide_fd_pay_to, :hide_fd_street_address, :hide_fd_city, :hide_fd_state, :hide_fd_zip, :fields,:hide_abstract,:hide_learning_objectives, :hide_tags, :hide_other_tags,:hide_keywords, :hide_other_keywords, :create_session, :speaker_sessions, :printable_schedule, :total_session, :required_abstract, :required_learning_objectives, :required_tags, :required_other_tags, :required_keywords, :required_other_keywords, :hide_custom_filter_1 , :hide_custom_filter_2, :hide_custom_filter_3, :locked_custom_filter_1, :locked_custom_filter_2, :locked_custom_filter_3, :locked_facebook_url, :locked_linked_in, :locked_twitter_url, :hide_facebook_url,:hide_linked_in, :hide_twitter_url, "program_types" => [],)
  end

  def exhibitor_portal_settings_params
    params.require(:setting).permit(:lock_enhanced_exhibitor_portal, :default_portal_config, :locked_company_name, :locked_description, :locked_email, :locked_address_line1, :locked_address_line2, :locked_country, :locked_city, :locked_state, :locked_zip, :locked_phone, :locked_fax, :locked_url_web, :locked_url_twitter,
      :locked_url_facebook, :locked_url_linkedin, :locked_url_rss, :locked_contact_name, :locked_contact_title, :locked_contact_name_two, :locked_contact_title_two, :locked_contact_email_two, :locked_contact_mobile_two, :locked_message, :locked_logo, :hide_toll_free, :hide_url_tiktok,
      :hide_company_name, :hide_description, :hide_email, :hide_address_line1, :hide_address_line2, :hide_country, :hide_city, :hide_state, :hide_zip, :hide_phone, :hide_fax, :hide_url_web, :hide_url_twitter, :hide_url_facebook, :hide_url_linkedin, :hide_url_rss,
      :hide_url_instagram, :hide_url_youtube, :contact_name, :contact_title, :hide_contact_name_two, :hide_contact_title_two, :hide_contact_email_two, :hide_contact_mobile_two, :hide_message, :hide_logo, :hide_change_password, :hide_message_image_upload, :limit_no_of_staffs,
      :locked_toll_free, :locked_url_instagram, :locked_url_youtube, :locked_url_tiktok, :locked_contact_email, :hide_contact_email, :hide_staff_title, :hide_staff_email, :hide_staff_business_phone, :hide_staff_mobile_phone, :hide_staff_url_twitter, :hide_staff_url_facebook, :hide_staff_url_linkedin, :hide_staff_url_youtube, :hide_staff_url_instagram, :hide_staff_url_tiktok, :hide_staff_biography, :hide_staff_interests, :hide_staff_get_featured, :hide_staff_first_name, :hide_staff_last_name, :check_email_domain)
  end

  def attendee_portal_params
    params.require(:setting).permit(:hide_change_password, :locked_email, :hide_email, :first_name)
  end

  def cordova_setting_string_params
    params.require(:string_setting).permit(:guest_qa_page_google_apis_font, :guest_qa_page_no_questions_header, :guest_qa_page_no_questions_content, :guest_qa_page_background_colour, :guest_qa_page_title_background_colour, :guest_qa_page_title_text_colour,
      :guest_qa_page_question_background_colour, :guest_qa_page_question_text_colour)
  end

  def cordova_setting_boolean_params
    params.require(:setting).permit(:exhibitors_enabled, :ce_credits_enabled, :iattend_enabled)
  end

  def qna_setting_boolean_params
    params.require(:setting).permit(:guest_qa_page_enabled, :guest_qa_page_webpage_enabled, :guest_qa_page_hide_session_title, :guest_qa_page_hide_attendee_name, :chat_management, :session_video_display,:poll_management, :add_polls)
  end

  def guest_view_string_params
    params.require(:string_setting).permit(:leaderboard_google_apis_font, :leaderboard_header_text, :leaderboard_footnote_text, :leaderboard_background_colour, :leaderboard_header_text_colour, :leaderboard_table_background_colour_one, :leaderboard_table_background_colour_two, :leaderboard_table_text_colour)
  end

  def guest_view_boolean_params
    params.require(:boolean_setting).permit(:leaderboard_disabled, :leaderboard_show_attendee_code, :leaderboard_hide_tiebreaker_column)
  end

  def slots_param
    params.require(:setting).permit(:date_range,:duration, :enable_slotbookings, :start_time, :end_time)
  end

  def update_params
    params.require(:setting).permit(:program_feed,:load_banner_image,:enable_search_bar,:sessions_by_tag,:sessions_by_speaker,:sessions_by_audience_tag,:video_portal, :single_page_app, :login_with_devise, :auto_sign_in, :forgot_password, :option_to_skip_survey, :ask_attendee_details, :prefer_last_name, :nav_icons_show, :premium_access, :two_factor, :featured_sessions, :live_sessions,
       :ce_with_survey, :banner_enabled, :shuffle_banner, :redirect_to_survey, :standby_screen, :favourites, :on_demand, :full_schedule, :sessions_by_date, :sessions_by_tag, :sessions_by_audience_tag, :sessions_by_speaker, :sessions_search,
       :sessions_by_my_ce, :show_session_codes, :show_speaker_names, :exhibitors_by_sponsors, :exhibitors_by_alphabet, :exhibitors_by_categories, :exhibitors_by_search, :attendees_by_alphabet, :attendees_by_categories, :send_ce_after_survey,
       :attendees_by_search, :session_info, :speaker_info, :session_files, :polling, :polling_live, :q_a, :q_a_answers, :notes, :attendee_chat, :exhibitor_info, :exhibitor_products, :exhibitor_files, :exhibitor_survey, :default_ce_id,
       :exhibitor_notes, :exhibitor_links, :exhibitor_chat, :exhibitor_messages, :exhibitor_misc, :exhibitor_checkin, :exhibitor_staffs, :nav_dashboard, :nav_sessions, :nav_exhibitors, :nav_exhibitors_simple, :nav_exhibitors_alphabet,
       :nav_networking, :nav_messages, :nav_help, :nav_photo_gallery, :nav_notifications, :nav_event_survey, :nav_blog, :nav_game, :nav_booked_slots, :reverse_day_order, :timeslots_booking, :show_speaker_email, :attendees_messaging_option, :hide_ondemands_time, :keep_accordion_sections_closed, :enable_switching_timezone, :exhibitors_by_alphabetic_card_view, :attendee_email, :attendee_phone, :attendees_by_alphabetic_card_view, :enable_exhibitor_booth_banner, :enable_livestream_banner, :attendee_poll, :program_title, :program_heading, :program_feed_twelve_hour_format, :default_card_view, :speakers_order_by_first_name, :sessions_by_exhibitor, :session_video_from_media_files, :nav_on_demand, :show_sponsored_exhibitor, :show_featured_speaker, :percentage_video_viewed_for_iattend)
  end

  def registration_portal_settings_params
    [:email_label,:username_label,:first_name_label,:last_name_label,:honor_prefix_label,:honor_suffix_label,:title_label,:company_label,:biography_label,:business_unit_label,:business_phone_label,:mobile_phone_label,:country_label,:state_label,:city_label,:twitter_url_label,:facebook_url_label,:linked_in_label].each do |key|
        params[:setting][key] = nil unless params[:setting][key].present?
    end

    params.require(:setting).permit(:registration_open, :ga_key, :html_title, :select_tag_title, :landing, :closing_date, :closing_time, :launch_virtual_portal, :event_details_1, :event_details_2, :agenda, :speakers, :exhibitors, :sponsors, :hotel_information, :locked_email, :locked_username, :locked_password, :first_name,
    :last_name, :honor_prefix, :honor_suffix, :title, :company, :biography, :business_unit, :business_phone, :mobile_phone, :country, :state, :city, :twitter_url, :facebook_url, :linked_in, :agenda_info, :speakers_info, :exhibitors_info, :sponsors_info, :hotels_info, :email,
    :enable_profile_message_display, :message_to_display, :username, :gradient_top, :gradient_bottom, :body_background_color,  :body_background_image, :body_background_position, :reg_button_class, :nav_links_color, :already_reg_link_color,
    :body_background_size,:body_background_repeat, :h1_color, :h2_color, :h3_color, :h4_color, :twitter_link, :facebook_link, :instagram_link, :skype_link, :linkedin_link, :dark_bg_theme, :bold_text, :text_shadow, :text_shadow_h1, :text_shadow_h2, :navbar_text_shadow,
    :standby_screen_text, :reg_banner, :reg_main, :reg_header_content, :reg_header_bg_img, :no_of_content_sections, :column_list, :reg_section_container1, :reg_section_container2, :reg_section_container3,
    :reg_section_container4, :reg_section_container5, :reg_section_container6, :reg_section_container7, :reg_section_container8, :reg_section_container9, :reg_section_container10,
    :reg_section_container1_col1, :reg_section_container1_col2, :reg_section_container1_col3, :reg_section_container1_col4, :reg_section_container1_col5, :reg_section_container2_col1,
    :reg_section_container2_col2, :reg_section_container2_col3, :reg_section_container2_col4, :reg_section_container2_col5, :reg_section_container3_col1, :reg_section_container3_col2,
    :reg_section_container3_col3, :reg_section_container3_col4, :reg_section_container3_col5, :reg_section_container4_col1, :reg_section_container4_col2, :reg_section_container4_col3,
    :reg_section_container4_col4, :reg_section_container4_col5, :reg_section_container5_col1, :reg_section_container5_col2, :reg_section_container5_col3, :reg_section_container5_col4,
    :reg_section_container5_col5, :reg_section_container6_col1, :reg_section_container6_col2, :reg_section_container6_col3, :reg_section_container6_col4, :reg_section_container6_col5,
    :reg_section_container7_col1, :reg_section_container7_col2, :reg_section_container7_col3, :reg_section_container7_col4, :reg_section_container7_col5, :reg_section_container8_col1,
    :reg_section_container8_col2, :reg_section_container8_col3, :reg_section_container8_col4, :reg_section_container8_col5, :reg_section_container9_col1, :reg_section_container9_col2,
    :reg_section_container9_col3, :reg_section_container9_col4, :reg_section_container9_col5, :reg_section_container9_col3_style, :reg_section_container9_col4_style, :reg_section_container9_col5_style,
    :reg_section_container1_style, :reg_section_container2_style, :reg_section_container3_style, :reg_section_container4_style, :reg_section_container5_style, :reg_section_container6_style,
    :reg_section_container7_style, :reg_section_container8_style, :reg_section_container9_style, :reg_section_container10_style, :reg_section_container1_col1_style, :reg_section_container1_col2_style,
    :reg_section_container1_col3_style, :reg_section_container1_col4_style, :reg_section_container1_col5_style, :reg_section_container2_col1_style, :reg_section_container2_col2_style,
    :reg_section_container2_col3_style, :reg_section_container2_col4_style, :reg_section_container2_col5_style, :reg_section_container3_col1_style, :reg_section_container3_col2_style,
    :reg_section_container3_col3_style, :reg_section_container3_col4_style, :reg_section_container3_col5_style, :reg_section_container4_col1_style, :reg_section_container4_col2_style,
    :reg_section_container4_col3_style, :reg_section_container4_col4_style, :reg_section_container4_col5_style, :reg_section_container5_col1_style, :reg_section_container5_col2_style,
    :reg_section_container5_col3_style, :reg_section_container5_col4_style, :reg_section_container5_col5_style, :reg_section_container6_col1_style, :reg_section_container6_col2_style,
    :reg_section_container6_col3_style, :reg_section_container6_col4_style, :reg_section_container6_col5_style, :reg_section_container7_col1_style, :reg_section_container7_col2_style,
    :reg_section_container7_col3_style, :reg_section_container7_col4_style, :reg_section_container7_col5_style, :reg_section_container8_col1_style, :reg_section_container8_col2_style,
    :reg_section_container8_col3_style, :reg_section_container8_col4_style, :reg_section_container8_col5_style, :reg_section_container9_col1_style, :reg_section_container9_col2_style,
    :post_reg_section_container1, :post_reg_section_container2, :post_reg_section_container3, :show_footer, :show_header_index_page, :show_header_edit_page, :show_header_registered_page,
    :post_reg_section_container4, :post_reg_section_container5, :post_reg_section_container6, :post_reg_section_container7, :post_reg_section_container8, :post_reg_section_container9, :post_reg_section_container10,
    :post_reg_section_container1_col1, :post_reg_section_container1_col2, :post_reg_section_container1_col3, :post_reg_section_container1_col4, :post_reg_section_container1_col5, :post_reg_section_container2_col1,
    :post_reg_section_container2_col2, :post_reg_section_container2_col3, :post_reg_section_container2_col4, :post_reg_section_container2_col5, :post_reg_section_container3_col1, :post_reg_section_container3_col2,
    :post_reg_section_container3_col3, :post_reg_section_container3_col4, :post_reg_section_container3_col5, :post_reg_section_container4_col1, :post_reg_section_container4_col2, :post_reg_section_container4_col3,
    :post_reg_section_container4_col4, :post_reg_section_container4_col5, :post_reg_section_container5_col1, :post_reg_section_container5_col2, :post_reg_section_container5_col3, :post_reg_section_container5_col4,
    :post_reg_section_container5_col5, :post_reg_section_container6_col1, :post_reg_section_container6_col2, :post_reg_section_container6_col3, :post_reg_section_container6_col4, :post_reg_section_container6_col5,
    :post_reg_section_container7_col1, :post_reg_section_container7_col2, :post_reg_section_container7_col3, :post_reg_section_container7_col4, :post_reg_section_container7_col5, :post_reg_section_container8_col1,
    :post_reg_section_container8_col2, :post_reg_section_container8_col3, :post_reg_section_container8_col4, :post_reg_section_container8_col5, :post_reg_section_container9_col1, :post_reg_section_container9_col2,
    :post_reg_section_container9_col3, :post_reg_section_container9_col4, :post_reg_section_container9_col5, :post_reg_section_container9_col3_style, :post_reg_section_container9_col4_style, :post_reg_section_container9_col5_style,
    :post_reg_section_container1_style, :post_reg_section_container2_style, :post_reg_section_container3_style, :post_reg_section_container4_style, :post_reg_section_container5_style, :post_reg_section_container6_style,
    :post_reg_section_container7_style, :post_reg_section_container8_style, :post_reg_section_container9_style, :post_reg_section_container10_style, :post_reg_section_container1_col1_style, :post_reg_section_container1_col2_style,
    :post_reg_section_container1_col3_style, :post_reg_section_container1_col4_style, :post_reg_section_container1_col5_style, :post_reg_section_container2_col1_style, :post_reg_section_container2_col2_style,
    :post_reg_section_container2_col3_style, :post_reg_section_container2_col4_style, :post_reg_section_container2_col5_style, :post_reg_section_container3_col1_style, :post_reg_section_container3_col2_style,
    :post_reg_section_container3_col3_style, :post_reg_section_container3_col4_style, :post_reg_section_container3_col5_style, :post_reg_section_container4_col1_style, :post_reg_section_container4_col2_style,
    :post_reg_section_container4_col3_style, :post_reg_section_container4_col4_style, :post_reg_section_container4_col5_style, :post_reg_section_container5_col1_style, :post_reg_section_container5_col2_style,
    :post_reg_section_container5_col3_style, :post_reg_section_container5_col4_style, :post_reg_section_container5_col5_style, :post_reg_section_container6_col1_style, :post_reg_section_container6_col2_style,
    :post_reg_section_container6_col3_style, :post_reg_section_container6_col4_style, :post_reg_section_container6_col5_style, :post_reg_section_container7_col1_style, :post_reg_section_container7_col2_style,
    :post_reg_section_container7_col3_style, :post_reg_section_container7_col4_style, :post_reg_section_container7_col5_style, :post_reg_section_container8_col1_style, :post_reg_section_container8_col2_style,
    :post_reg_section_container8_col3_style, :post_reg_section_container8_col4_style, :post_reg_section_container8_col5_style, :post_reg_section_container9_col1_style, :post_reg_section_container9_col2_style,
    :no_of_content_sections_post_reg, :column_list_post_reg, :reg_form_header, :send_calendar_invite, :attach_calendar_invite,:required_email, :required_username, :required_first_name, :required_last_name,
    :required_honor_prefix, :required_honor_suffix, :required_title, :required_company, :required_biography, :required_business_unit, :required_business_phone, :required_mobile_phone, :required_country,
    :required_state, :required_city, :required_twitter_url, :required_facebook_url, :required_linked_in, :show_header_agenda_page,:show_header_speaker_page, :show_header_exhibitor_page, :have_payment_page,
    :required_password, :password, :payment_gateway, :email_label, :username_label, :first_name_label, :last_name_label, :honor_prefix_label, :honor_suffix_label, :title_label, :company_label, :biography_label,
    :business_unit_label, :business_phone_label, :mobile_phone_label, :country_label, :state_label, :city_label, :twitter_url_label, :facebook_url_label, :linked_in_label, :product_categories, :registration_button_color,
    :hide_banner_bar, :text_color, :link_color, :registration_button_text_color, :show_header_sponsor_page, :show_header_hotel_info_page, :content_link_color, :is_list_view, :member_information_page_header, :badge_name, :required_badge_name, :badge_name_label, :successful_modal_page_header, :payment_successful_modal_msg, :payment_successful_modal_email_msg, :receipt_attachment, :payment_info_page_header, :payment_term_info, :transaction_tax_value, :transaction_tax_name, :receipt_email, :exhibitor_product_cart_page_header, product_categories_ids:[], registration_category_ids: [])
  end

  def simple_registration_settings_params
    [:first_name_label, :last_name_label, :email_label, :company_label, :title_label].each do |key|
        params[:setting][key] = nil unless params[:setting][key].present?
    end

    params.require(:setting).permit(:simple_registration_heading, :ga_key, :html_title, :simple_registration_subheading, :simple_registration_duration, :simple_registration_content, :simple_registration_heading1, :simple_registration_subheading1, :simple_registration_duration1,
      :simple_registration_content1, :registration_open, :attendees_count, :seats_full_message, :registration_with_email_confirmation, :send_calendar_invite, :body_background_color,  :body_background_image, :body_background_position,
      :body_background_size,:body_background_repeat, :h1_color, :h2_color, :h3_color, :h4_color, :dark_bg_theme, :bold_text, :text_shadow, :text_shadow_h1, :text_shadow_h2, :reg_button_class, :first_name_label, :last_name_label, :email_label, :company_label, :title_label, :send_attendee_password)
  end

  def speaker_registration_settings_params
    [:first_name_label, :last_name_label, :email_label, :company_label, :title_label].each do |key|
      params[:setting][key] = nil unless params[:setting][key].present?
    end

    params.require(:setting).permit(:speaker_registration_heading,:html_title, :speaker_registration_subheading, :speaker_registration_duration, :speaker_registration_content, :speaker_registration_heading1, :speaker_registration_subheading1, :speaker_registration_duration1,
      :speaker_registration_content1, :registration_open,  :registration_with_email_confirmation, :body_background_color,  :body_background_image, :body_background_position,
      :body_background_size,:body_background_repeat, :h1_color, :h2_color, :h3_color, :h4_color,  :bold_text, :text_shadow, :text_shadow_h1, :text_shadow_h2, :reg_button_class, :first_name_label, :last_name_label, :email_label, :company_label, :title_label, :numeric_password, :speaker_post_registration_heading, :speaker_post_registration_subheading, )

  end

  def exhibitor_portal_styles_params
    params.require(:setting).permit(background_color:[:'exhibitor-logo', :'exhibitor-videocontainer', :'exhibitor-info', :'exhibitor-files', :'exhibitor-notes', :'exhibitor-survey', :'exhibitor-products', :'exhibitor-messages', :'exhibitor-chat', :'exhibitor-misc'], bottom_nav:[:bottom_nav_bg_color, :bottom_nav_color, :bottom_nav_button_active],
      window_header:[:window_header_bg_color, :window_header_color], border_radius:[:'exhibitor-logo', :'exhibitor-videocontainer', :'exhibitor-info', :'exhibitor-files', :'exhibitor-notes', :'exhibitor-survey', :'exhibitor-products', :'exhibitor-messages', :'exhibitor-chat', :'exhibitor-misc'])
  end

  def admin_cordova_settings_params
    params.permit(
      EKM_booleans:[:remove_posters_from_session_day_view_filter_default, :networkHeartbeatEnabled, :primaryServerHeartbeatEnabled, :settingTogglesEnabled, :backgroundRemoteUpdatesEnabled, :fastBootupEnabled, :gameEnabled,
       :feedbackGameMode, :flareEnabled, :notesEnabled, :messagingEnabled, :homePaginationEnabled, :syncedNotificationsEnabled, :sqliteGeneralPurposeEnabled, :sqliteGameEnabled, :sqliteNotesEnabled, :sqliteMessagesEnabled, :sqliteMapsEnabled,
       :sqliteAppImagesEnabled, :profileTogglesEnabled, :iattend_available_for_event, :iattend_activated, :sessionFiles, :exhibitorDetailTopTags, :exhibitorFavouritesEnabled, :exhibitorInteractiveMap, :enableTwitFeed, :calendarServiceEnabled,
       :Feedback, :SurveysEnabled, :DaysTagsSpeakers, :SessionSimple, :ExhibitorSimple, :searchAll, :searchSessionsAttendees, :searchSessionsExhibitors, :SimpleSchedule, :attendeeMenuAlphaListing, :attendeeMenuTagsListing, :AttendeesAlphaTags,
       :favouritesVisible, :search_session_enabled, :search_exhibitor_enabled, :search_attendee_enabled, :sessionFavouritesSync, :exhibitorFavouritesSync, :SingleRecommendationsPage, :kiosk, :kioskMode, :iBeaconsEnabled, :exhibitorMessagingEnabled,
       :profileTogglesPromptEnabled, :iattend_code_check_active, :metaTagsActive, :noDoubleBooking, :twolinesessionDetailButtons, :sessiondetailbuttons, :DaysTags, :DaysSpeakers, :DaysOnly, :ExhibitorAlphaTags, :ExhibitorAlpha, :ExhibitorWithCustomFields,
       :SessionCode, :attendeesSimple, :attendeeMenuBUListing, :FLARE_NICKNAME, :gpsDataIntervalsEnabled, :DONT_SHOW_OLDER_RECOMMENDATIONS, :showAttendeeContactInfo, :enableAutoLogin, :promptUserToGoToProfileEnabled, :reporting_on],
      window_booleans:[:SIMPLE_SESSION_VIEW, :SIMPLE_ATTENDEE_ALPHA_VIEW, :EmailVisible, :loginMode, :attendeeSessions, :SIMPLE_EXHIBITOR_VIEW, :SIMPLE_EXHIBITOR_ALPHA_VIEW],
      window_strings:[:searchChoice, :IOS_GA_ACCOUNT_ID, :LOGIN_TYPE, :SIMPLE_USERNAME, :SIMPLE_PASSWORD, :IATTEND_ERROR_MSG, :IATTEND_ADD_SUCCESS_MSG, :IATTEND_REMOVE_SUCCESS_MSG, :FAVOURITES_ERROR_MSG, :FAVOURITES_ADD_SUCCESS_MSG,
         :FAVOURITES_REMOVE_SUCCESS_MSG, :IATTEND_URL, :EK_SESSION_FILE_ROOT_URL],
      EKM_strings:[:gameIndexViewMode, :codePushService, :twitterQueryCLIName, :twitterQuery, :twitterUserCLIName, :twitterUserName, :cal_timezone, :NOTES_CONNECTION_ERROR, :NOTES_SYNC_ERROR_MSG, :NOTES_DELETE_ERROR_MSG, :NOTES_REMOTE_SYNC_SUCCESS,
        :MESSAGES_CONNECTION_ERROR, :MESSAGES_SYNC_ERROR_MSG, :MESSAGES_DELETE_ERROR_MSG, :MESSAGES_REMOTE_SYNC_SUCCESS, :FLARE_USER_MODE, :FLARE_CONNECTION_ERROR, :FLARE_ANON_USER_HANDLE, :guest_username, :guest_password, :guest_account_code, :FLARE_URL_ROOT,
        :PHOTO_GALLERY_LINK_URL, :EXHIBITOR_GAME_URL, :INTERACTIVE_MAP_URL, :ATTENDEE_PROFILE_CMS_URL, :EDIT_ATTENDEE_PROFILE, :default_network_error_message, :default_network_connection_error_message, :default_iattend_incorrect_code_message, :default_prompt_accept,
        :default_prompt_deny, :confirm_yes, :confirm_no, :confirm_ok_text, :confirm_cancel_text, :data_reload_message, :alert_no_internet_connection_for_guide, :alert_no_internet_connection_for_quiz, :alert_no_internet_connection_for_game,
        :alert_no_internet_connection_for_recommendations, :alert_no_internet_connection_for_recommendations_using_local_data, :alert_app_ready_for_first_use, :alert_new_data_incoming, :alert_reset_on_update_screen, :alert_force_logout,
        :first_run_prompt_user_go_to_profile_text, :first_run_prompt_user_go_to_profile_confirm_text, :first_run_prompt_user_go_to_profile_deny_text, :game_name, :game_help_title, :game_help_link, :game_subtitle, :game_badge_complete,
        :game_task_complete, :guest_user_message, :guest_user_message_profile, :game_how_to_play, :messaging_opt_out_notice, :first_run_messaging_opt_in_confirm_text, :attende_list_notice, :game_notice, :game_not_ready_notice,
        :scavenger_hunt_not_ready_notice, :favourite_notice, :ce_sessions_notice, :notes_notice, :gallery_notice, :attendee_scanner_notice, :recommendation_skip_sign_on_notice, :profile_notice, :scanner_alert_must_be_online_to_scan_barcode,
        :scanner_scan_failure_msg, :generic_scanner_upload_success_msg, :scanner_upload_failure_msg, :scanner_edit_note_text, :scanner_close_dialog_text, :scanner_cannot_edit_attendee_note_text, :maps_not_ready_notice, :sessions_not_ready_notice,
        :alert_photo_uploaded, :alert_photo_failed_to_upload, :photo_confirm_send_photo, :photo_alert_must_be_online_to_submit_photo, :choose_photo_upload_source_text, :confirm_camera_button_text, :confirm_local_gallery_button_text,
        :alert_media_uploaded, :flare_online_to_submit_media, :flare_online_to_update_user_profile, :flare_online_to_delete_user_profile, :flare_online_to_view_photo_feed, :flare_note_text, :login_select_your_event_text, :reload_app_text,
        :reload_offline_app_text, :no_internet_connection_text, :no_internet_connection_offine_allowed_text, :alert_invalid_login_credentials, :alert_password_reset_success, :alert_password_reset_failed, :alert_no_internet_connection_to_download_event_list,
        :alert_help_text, :alert_help_link, :alert_login_help, :multi_event_login_email_input_placeholder, :multi_event_login_password_input_placeholder, :multi_event_login_submit_button_text, :multi_event_choose_another_event_text, :back_to_submit_email_button_text,
        :email_not_found_error_text, :single_event_login_form_error_text, :single_event_login_input_placeholder, :single_event_password_input_placeholder, :single_event_login_submit_button_text, :session_menu_option_days, :session_menu_option_tags,
        :session_menu_option_speakers, :session_header_text, :qa_header_text, :sesssion_room, :session_feedback_heading, :session_feedback_submit_text, :feedback_error_msg, :session_detail_speakers_heading, :session_detail_description_heading,
        :session_detail_learning_objectives_heading, :session_detail_files_heading, :session_detail_sponsors_heading, :session_detail_custom_heading, :speaker_feedback_heading, :speaker_feedback_submit_text, :speaker_feedback_error_mesg,
        :speaker_biography_heading, :speaker_contact_heading, :speaker_alert_feedback_successfully_submitted, :speaker_alert_feedback_failed_to_submit, :exhibitor_header_text, :exhibitor_menu_option_alphabetical, :exhibitor_menu_option_tags,
        :exhibitor_detail_booth_prefix, :message_exhibitor_button_text, :exhibitor_detail_description_heading, :exhibitor_detail_top_level_tags_prefix, :exhibitor_detail_contact_heading, :attendee_header_text, :attendee_menu_option_alphabetical,
        :attendee_menu_option_bu, :attendee_menu_option_tags, :attendee_message_all_button_text, :message_attendee_button_text, :attendee_detail_contact_heading, :updating_favorites_message, :favourites_menu_option_sessions, :favourites_menu_option_exhibitors,
        :favourites_menu_option_attended, :favourites_sessions_heading, :favourites_exhibitors_heading, :favourites_attended_heading, :ce_sessions_bulk_add_credits, :favourites_no_session_favs_msg, :favourites_no_ce_credit_sessions_msg,
        :favourites_no_exhibitor_favs_msg, :favourites_alert_fav_locked, :favourites_alert_cannot_add_ticketed_session, :favourites_alert_not_eligible_to_book_sessions, :favourites_alert_feedback_submission_error, :favourites_alert_feedback_successfully_submitted,
        :feedback_game_mode_notice, :favourites_alert_calendar_not_supported_on_android, :favourites_alert_event_cannot_be_added_to_calendar, :favourites_alert_event_successfully_added_to_calendar, :confirm_replace_favourite, :exhibitor_recommendations_nav_btn_text,
        :exhibitor_recommendations_header_text, :no_recommendations_text, :attendee_profile_header_text, :attendee_profile_alert_media_uploaded, :ce_credits, :ce_level, :credit_approved, :video_recorded, :price, :capacity, :custom_filter_2, :custom_filter_3,
        :settings_header_text, :settings_full_refresh_button_text, :settings_manual_sync_button_text, :settings_flush_cache_button_text, :settings_check_updates_button_text, :settings_stop_kiosk_mode_button_text, :settings_start_kiosk_mode_button_text,
        :settings_log_out_button_text, :settings_change_event_button_text, :settings_filters_header_text, :search_input_placeholder, :search_menu_bar_attendee, :search_menu_bar_session, :search_menu_bar_exhibitor, :no_results_message, :notes_session_note_title,
        :notes_exhibitor_note_title, :notes_attendee_note_title, :notes_general_note_title, :no_notes_message, :notes_synced_text, :notes_prompt_enter_your_email, :notes_session_code_prefix, :notes_attendee_name_prefix, :notes_title_label, :question_for_session_label,
        :notes_content_label, :question_content_label, :notes_add_edit_photo_link_text, :notes_update_gps_coordinates_link_text, :notes_set_gps_coordinates_link_text, :notes_submit_question_text, :notes_save_note_text, :note_form_title_placeholder_text,
        :note_form_content_placeholder_text, :messages_alert_must_have_active_internet_connection_to_sync_notes, :alert_notes_email_saved, :alert_notes_email_failed_to_save, :notes_alert_must_be_online_to_set_email, :notes_alert_must_be_online_to_submit_question,
        :notes_prompt_sync_notes, :messages_alert_must_have_internet_to_send_message, :messages_delete_message_confirm_box_text, :messages_delete_message_confirm_box_accept, :messages_delete_message_confirm_box_deny, :notes_synced_note_cant_be_synced_offline_alert,
        :messages_delete_note_confirm_box_text, :messages_delete_note_confirm_box_accept, :messages_delete_note_confirm_box_deny, :messages_unread_text, :messages_add_attendee_to_message_placeholder, :messages_recipients_list_heading, :message_title_heading,
        :message_content_heading, :message_title_placeholder_text, :message_content_placeholder_text, :message_submit_button_text, :messages_no_messages_text, :messages_messages_mini_header_text, :messages_new_message_mini_header_text, :sync_messages_confirm_text,
        :sync_messages_confirm_accept, :sync_messages_confirm_deny, :messages_no_connection_alert, :messages_alert_need_connection_to_start_thread, :messages_alert_need_one_recipient_to_start_thread, :notifications_heading_text, :loading_tweets_text,
        :default_menu_option_border_highlight, :default_menu_option_border_unhighlight, :multi_select_logo_style, :mlte_date_loc_line_style, :notice_logo_style, :multi_event_login_logo_style, :multi_event_login_email_input_style, :multi_event_login_password_input_style,
        :single_event_login_logo_style, :single_event_login_input_style, :single_event_password_input_style, :exhibitor_detail_logo_style, :exhibitor_detail_logo_style_small, :exhibitor_detail_logo_style_smaller, :exhibitor_detail_detail_icons_style,
        :exhibitor_detail_detail_icons_row_two_style, :exhibitor_detail_social_icon_style, :attendee_detail_social_icon_style, :attendee_menu_button_style, :attendee_photo_style_smaller, :session_detail_detail_icons_style, :session_detail_conference_note_icon_style,
        :speaker_session_detail_icons_style, :speaker_detail_logo_style, :attendee_detail_logo_style, :custom_lists_heading_style, :notifications_heading_style, :settings_heading_style, :attendee_profile_heading_style, :favourites_headings_style, :maps_heading_style,
        :social_heading_style, :videos_heading_style, :background, :game_instructions, :game_alert_prize1, :game_alert_prize2, :game_challenges_total_text, :game_points_total_text, :game_challenges_threshold_reached_message, :game_points_threshold_reached_message,
        :game_challenges_total_complete_text, :game_points_total_complete_text, :game_challenges_text],
      EKM_numbers:[:max_length_session_scroll, :networkHeartbeatWatchInterval, :primaryServerHeartbeatWatchInterval, :sqliteBatchSize, :kioskTime, :homeButtonsPerPage, :HSSwipeCountLimit, :messageWatchInterval, :messageListWatchInterval, :earned_badges,
        :game_expected_badge_count, :game_challenges_threshold, :game_points_threshold, :home_screen_visits_per_reporting_push],
      EKM_floats:[:percent_elapsed_session_scroll])
  end

  def can_be_fields? check_value
    begin
      JSON.parse(check_value.to_json)
      true
    rescue StandardError => e
      false
    end
  end

  def attendee_badge_portal_settings_params
    params.require(:setting).permit(:attendee_badge_portal_heading, :ga_key, :html_title, :attendee_badge_portal_subheading, :attendee_badge_portal_duration, :attendee_badge_portal_content, :portal_open, :body_background_color, :body_background_image, :body_background_position, :body_background_size, :body_background_repeat, :h1_color, :h2_color, :h3_color, :h4_color, :dark_bg_theme, :bold_text, :text_shadow, :text_shadow_h1, :text_shadow_h2, :search_attendee_by, :badge_format, :portal_open, :badge_format_for_attendee, :badge_format_for_exhibitor, :badge_format_for_speakers, :show_badge_search_field_for_attendee, :show_badge_search_field_for_exhibitor, :show_badge_search_field_for_speaker, :allowed_times_to_print_badge, :use_pin_for_security, :overide_code)
  end

end
