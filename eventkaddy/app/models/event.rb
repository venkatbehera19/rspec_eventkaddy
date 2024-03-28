class Event < ApplicationRecord
  # attr_accessible :org_id, :logo_event_file_id, :user_ids, :users, :name, :description, :event_start_at, :event_end_at, :longitude, :latitude, :url_web, :url_facebook, :url_twitter, :url_rss, :iphone, :android, :mobile_site, :touchscreen, :soma_record, :exhibitors, :enhanced_listings, :sponsorship, :notification_UA_AK, :notification_UA_AMS, :master_url, :event_server, :utc_offset, :pn_filters, :type_to_pn_hash, :tag_sets_hash, :flare_enabled, :hide_in_app, :multi_event_status, :api_key, :cms_url, :chat_url, :reporting_url, :cloud_storage_type_id
  attr_accessor :userselect

  serialize :type_to_pn_hash, JSON
  serialize :tag_sets_hash, JSON

  # include EventRelationships::EventTags
  include EventTags
  include Magick

  belongs_to :organization, :foreign_key => 'org_id'
  belongs_to :event_file, :foreign_key => 'logo_event_file_id', optional: true
  has_many :tracks, :dependent => :destroy
  has_many :notifications, :dependent => :destroy
  has_many :home_button_groups, :dependent => :destroy
  has_many :users_events, :dependent => :destroy
  # has_many :users, :through => :users_events
	has_and_belongs_to_many :users, :join_table => :users_events
	has_and_belongs_to_many :av_list_items, :join_table => :events_av_list_items
  has_many :attendees, :dependent => :destroy
  has_many :feedbacks
  has_many :session_files
  has_many :session_file_versions
  has_many :session_av_requirements
  has_many :sessions
  has_many :room_layouts
  has_many :speakers
  has_many :speaker_files
  has_one  :event_setting
  has_many :messages
  has_many :event_files
  has_many :mobile_web_settings
  has_many :attendee_scans
  has_many :hidden_events
  has_many :domains
  has_many :polls
  has_many :event_sponsor_level_types
  has_many :sponsor_level_types, through: :event_sponsor_level_types
  has_many :app_submission_forms do
    def ios_form
      where(app_form_type_id: IOS_ID)
    end

    def android_form
      where(app_form_type_id: ANDROID_ID)
    end
  end

  has_many :event_tickets
  has_many :custom_forms
  has_many :download_requests

  # this code prevents logo update on pages that don't have a userselect box. Need to resolve this.
  # ( we would probably do this by update_attribute to ignore validation. But really we should not be
  # using a model validation to check a form element. That can either be done in javascript or in the
  # controller action
  # validate :must_be_at_least_one_user

  # def must_be_at_least_one_user
  #     if userselect.nil?
  #       errors.add(:users, "must be selected")
  #     end
  # end

  # special methods to call when when I want to make sure I'm using a testing
  # UA key if I'm working locally. Only risky thing is if someone gets
  # complacent and uses the column name instead, but since it only works with
  # a database named "stable_copy" I'm (Ed) likely the only one to use it
  def notification_app_key
    Dev.local_database? ? "df1p-HZaTb2KZwZpjHPXWQ" : notification_UA_AK
  end

  def notification_app_master_secret
    Dev.local_database? ? "fjB_9eVVThSIjmq4QCdfwA" : notification_UA_AMS
  end

  def self.names_and_ids
    Event.select('id, name').all.map {|e| [e.id, e.name] }
  end

  # get automatic and standard pn filters combined
  def all_pn_filters
    filters      = pn_filters ? JSON.parse(pn_filters) : []
    auto_filters = type_to_pn_hash ? type_to_pn_hash.values.flatten : []
    (filters + auto_filters).uniq
  end

  def self.active_events
    select('events.*, MAX(sessions.date) AS latest_session, MIN(sessions.date) AS earliest_session').
      where("event_start_at <= ? AND event_end_at >= ?", Time.now, Time.now - 1.days).
      joins("LEFT OUTER JOIN sessions ON sessions.event_id = events.id").
      group('events.id').
      order(:event_start_at)
  end

  def self.upcoming_events
    select('events.*, MAX(sessions.date) AS latest_session, MIN(sessions.date) AS earliest_session').
      where("event_start_at >= ?", Time.now - 1.days).
      joins("LEFT OUTER JOIN sessions ON sessions.event_id = events.id").
      group('events.id').
      order(:event_start_at)
  end

  def self.past_events
    select('events.*, MAX(sessions.date) AS latest_session, MIN(sessions.date) AS earliest_session').
      where("event_end_at <= ?", Time.now - 1.days).
      joins("LEFT OUTER JOIN sessions ON sessions.event_id = events.id").
      group('events.id').
      order("event_start_at DESC" )
  end

  def session_date_loc_meta_tags?
    cms_settings = Setting.return_cms_settings_or_false id
    cms_settings && cms_settings.tag_date_loc_meta_data
  end

  def get_offset
    offset          = "+00:00"
    event_offset    = self.utc_offset
    offset          = event_offset unless event_offset.blank?
    return offset
  end

  # smell: duplication, convoluted, should not accept 'params'
  def fillPlaceholders(params)
    if !(params[:event_files].nil?) && params[:event_files].length == 1
      event_files = EventFile.where(event_id:id,name:params[:event_files].first.original_filename.gsub(/\s/,'_'))
      if event_files.length > 0
        event_file                          = event_files.first
        @session_file_version               = event_file.session_file_version
        @session_file_version.document      = params[:event_files].first
        params[:no_user]                    = true
        @session_file_version.update!(final_version:true)
        @session_file_version.updateFile(params)
        @session_file_version.session_file.update! unpublished: nil if params[:publish_all] == '1'
      else
        errors.add("File", "#{params[:event_files].first.original_filename} does not have a matching record in the database.")
      end
    elsif !(params[:event_files].nil?)
      params[:event_files].each do |file|
        event_files = EventFile.where(event_id:id,name:file.original_filename.gsub(/\s/,'_'))
        if event_files.length > 0
          event_file                          = event_files.first
          @session_file_version               = event_file.session_file_version
          @session_file_version.document      = file
          params[:no_user]                    = true
          @session_file_version.update!(final_version:true)
          @session_file_version.updateFile(params)
          @session_file_version.session_file.update! unpublished: nil if params[:publish_all] == '1'
        else
          errors.add("File", "#{file.original_filename} does not have a matching record in the database.")
        end
      end
    end
  end

  def fillExhibitorFilePlaceholders(params)
    dirname = File.dirname(Rails.root.join('public', 'event_data', id.to_s, 'exhibitor_files', 'no_dir.pdf'))
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    unless params[:event_files].nil?
      params[:event_files].each {|file|
        event_files = EventFile.where event_id: id, name: file.original_filename
        if event_files.length > 0
          new_filename = file.original_filename
          uploaded_io  = file
          path         = Rails.root.join 'public', 'event_data', id.to_s, 'exhibitor_files', new_filename
          File.open(path, 'wb') { |f| f.write uploaded_io.read }
        else
          errors.add("File", "#{file.original_filename} does not have a matching record in the database.")
        end
      }
    end
  end

  def copy_file_to_apollo(file, relative_destination_directory)
    unless CURRENT_SERVER==="APOLLO" || CURRENT_SERVER.blank?
      path = "/home/deploy/ek-cms-prod/public/#{relative_destination_directory}"
      `scp #{file} deploy@173.230.132.66:#{path}`
      true
    else
      false
    end
  end

  # s3 updated
  def uploadGalleryPhotos(params)
    if !(params[:event_files].nil?) && params[:event_files].length > 0

      params[:event_files].each do |gallery_photo|

        if (gallery_photo.original_filename.match(/jpeg|jpg/i)) || (gallery_photo.original_filename.match(/png/i)) then

          if (gallery_photo.original_filename.match(/jpeg|jpg/i)) then
            file_ext = '.jpg'
          elsif (gallery_photo.original_filename.match(/png/i)) then
            file_ext = '.png'
          end

          new_filename     = "#{Time.now.strftime("%Y%m%d%H%M_%N")}#{file_ext}"
          target_path 	   = Rails.root.join('public','event_data', self.id.to_s,'photobooth_photos','uploads').to_path
          event_file_type  = EventFileType.find_by_name("pg-photobooth").id
          event_file       = EventFile.new(event_id:event_id,event_file_type_id:event_file_type_id)

          cloud_storage_type_id   = Event.find(session[:event_id]).cloud_storage_type_id
          cloud_storage_type      = nil
          unless cloud_storage_type_id.blank?
            cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
          end

          UploadEventFileImage.new(
            event_file:              event_file,
            image:                   gallery_photo,
            target_path:             target_path,
            new_filename:            new_filename,
            event_file_owner: 			 nil,
            cloud_storage_type:      cloud_storage_type
          ).call
        else
          errors.add("File", "#{params[:event_files].first.original_filename} failed to upload (not a jpeg or png).")
        end

      end

    end
  end

  # s3 updated
  def addLogo(params)
    #add logo image
    if (params[:event_logo_file]!=nil) then
      #upload the image
      uploaded_io             = params[:event_logo_file]
      target_path             = Rails.root.join('public','event_data', self.id.to_s,'event_logo').to_path
      event_file_type_id      = EventFileType.find_by_name("event_logo").id
			event_file 							= logo_event_file_id ? EventFile.find(logo_event_file_id)
                                : EventFile.new(event_id:self.id, event_file_type_id:event_file_type_id)
      cloud_storage_type_id   = Event.find(self.id).cloud_storage_type_id
      cloud_storage_type      = nil
      unless cloud_storage_type_id.blank?
        cloud_storage_type    = CloudStorageType.find(cloud_storage_type_id)
      end
      UploadEventFileImage.new(
        event_file:              event_file,
        image:                   uploaded_io,
        target_path:             target_path,
        new_filename:            uploaded_io.original_filename,
        event_file_owner: 			 self,
        event_file_assoc_column: :logo_event_file_id,
        cloud_storage_type:      cloud_storage_type
      ).call
    end
  end

  def updateMobileWebSettings(params,mobilewebsettings)

    mobilewebsettings.where(mobile_web_setting_types: { name: 'title' }).first.update!(:content=>params[:title])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'text_hilite_color' }).first.update!(:content=>params[:text_hilite_color])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'link_color' }).first.update!(:content=>params[:link_color])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'visited_link_color' }).first.update!(:content=>params[:visited_link_color])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'g_analytics_web' }).first.update!(:content=>params[:g_analytics_web])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'g_analytics_app' }).first.update!(:content=>params[:g_analytics_app])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_codes' }).first.update!(:enabled=>nilCheck(params[:session_codes]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'simple_schedule' }).first.update!(:enabled=>nilCheck(params[:simple_schedule]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'calendar_button' }).first.update!(:enabled=>nilCheck(params[:calendar_button]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'attend_button' }).first.update!(:enabled=>nilCheck(params[:attend_button]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'feedback' }).first.update!(:enabled=>nilCheck(params[:feedback]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_days' }).first.update!(:enabled=>nilCheck(params[:session_button_days]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_days_name' }).first.update!(:content=>params[:session_button_days_name])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_tracks' }).first.update!(:enabled=>nilCheck(params[:session_button_tracks]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_tracks_name' }).first.update!(:content=>params[:session_button_tracks_name])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_speakers' }).first.update!(:enabled=>nilCheck(params[:session_button_speakers]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_speakers_name' }).first.update!(:content=>params[:session_button_speakers_name])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_sponsors' }).first.update!(:enabled=>nilCheck(params[:session_button_sponsors]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_sponsors_name' }).first.update!(:content=>params[:session_button_sponsors_name])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_type' }).first.update!(:enabled=>nilCheck(params[:session_button_type]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_type_name' }).first.update!(:content=>params[:session_button_type_name])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_audience' }).first.update!(:enabled=>nilCheck(params[:session_button_audience]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'session_button_audience_name' }).first.update!(:content=>params[:session_button_audience_name])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'exhibitor_button_directory' }).first.update!(:enabled=>nilCheck(params[:exhibitor_button_directory]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'exhibitor_button_directory_name' }).first.update!(:content=>params[:exhibitor_button_directory_name])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'exhibitor_button_category' }).first.update!(:enabled=>nilCheck(params[:exhibitor_button_category]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'exhibitor_button_category_name' }).first.update!(:content=>params[:exhibitor_button_category_name])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'attendee_button_directory' }).first.update!(:enabled=>nilCheck(params[:attendee_button_directory]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'attendee_button_directory_name' }).first.update!(:content=>params[:attendee_button_directory_name])
    mobilewebsettings.where(mobile_web_setting_types: { name: 'attendee_button_category' }).first.update!(:enabled=>nilCheck(params[:attendee_button_category]))
    mobilewebsettings.where(mobile_web_setting_types: { name: 'attendee_button_category_name' }).first.update!(:content=>params[:attendee_button_category_name])


  end #updateMobileWebSettings

  def updateRequirements(params,requirements)

    requirements.where(requirement_types: { name: 'company' }).first.update!(:required=>nilCheck(params[:company]))
    requirements.where(requirement_types: { name: 'biography' }).first.update!(:required=>nilCheck(params[:biography]))
    requirements.where(requirement_types: { name: 'photo_event_file_id' }).first.update!(:required=>nilCheck(params[:photo_event_file_id]))
    requirements.where(requirement_types: { name: 'address1' }).first.update!(:required=>nilCheck(params[:address1]))
    requirements.where(requirement_types: { name: 'city' }).first.update!(:required=>nilCheck(params[:city]))
    requirements.where(requirement_types: { name: 'state' }).first.update!(:required=>nilCheck(params[:state]))
    requirements.where(requirement_types: { name: 'country' }).first.update!(:required=>nilCheck(params[:country]))
    requirements.where(requirement_types: { name: 'zip' }).first.update!(:required=>nilCheck(params[:zip]))
    requirements.where(requirement_types: { name: 'work_phone' }).first.update!(:required=>nilCheck(params[:work_phone]))
    requirements.where(requirement_types: { name: 'mobile_phone' }).first.update!(:required=>nilCheck(params[:mobile_phone]))
    requirements.where(requirement_types: { name: 'fax' }).first.update!(:required=>nilCheck(params[:fax]))
    requirements.where(requirement_types: { name: 'financial_disclosure' }).first.update!(:required=>nilCheck(params[:financial_disclosure]))
    requirements.where(requirement_types: { name: 'cv_event_file_id' }).first.update!(:required=>nilCheck(params[:cv_event_file_id]))
    requirements.where(requirement_types: { name: 'fd_pay_to' }).first.update!(:required=>nilCheck(params[:fd_pay_to]))
    requirements.where(requirement_types: { name: 'fd_tax_id' }).first.update!(:required=>nilCheck(params[:fd_tax_id]))
    requirements.where(requirement_types: { name: 'fd_street_address' }).first.update!(:required=>nilCheck(params[:fd_street_address]))
    requirements.where(requirement_types: { name: 'fd_city' }).first.update!(:required=>nilCheck(params[:fd_city]))
    requirements.where(requirement_types: { name: 'fd_state' }).first.update!(:required=>nilCheck(params[:fd_state]))
    requirements.where(requirement_types: { name: 'fd_zip' }).first.update!(:required=>nilCheck(params[:fd_zip]))

  end #updateRequirements

  def nilCheck(input)
    if input.nil?
      return false
    else
      return true
    end
  end

  def self.search_event_by_search_param(search_param)
    joins(:organization).where("events.name like ? or organizations.name like ?", "%#{search_param}%", "%#{search_param}%")
  end

  def self.options_for_select_events(user_events)
    order('updated_at DESC')
                      .all
                      .map    { |event| [event.name, event.id] }
                      .reject { |event| user_events.include? event }
  end

  def self.event_options
    data = []
    order('updated_at DESC')
      .all
      .each do |event|
        event_data = {}
        event_data["name"] = event.name
        event_data["id"]   = event.id
        data << event_data
      end
    data.to_json
  end

  def self.event_options_for_user(user_events)
    user_event_data = user_events.pluck(:event_id)
    data = []
    order('updated_at DESC')
      .all
      .each do |event|
        event_data = {}
        event_data["name"] = event.name
        event_data["id"]   = event.id
        if !user_event_data.include?(event.id)
          data << event_data
        end
      end
    data.to_json
  end
end
