class EventsController < ApplicationController
  layout "superadmin_2013"
  # load_and_authorize_resource #:only => [:show,:new,:destroy,:edit,:update,:index]
  load_and_authorize_resource
  extend ControllerHistory
  track_history(
    "Bulk Deletion",
    :deleteall_home_buttondata,
    :deleteall_notificationdata,
    :deleteall_homebuttondata,
    :deleteall_sessiondata,
    :deleteall_sessiontags,
    :deleteall_exhibitortags,
    :deleteall_attendeetags,
    :deleteall_exhibitordata,
    :deleteall_mappingdata,
    :deleteall_eventconfigdata,
    :deleteall_attendeedata,
    :delete_abandoned_tags
  )

  track_history(
    "Integration Pull",
    :refresh_external_api_import_script
  )

  track_history(
    "Spreadsheet Upload",
    :upload_sessions,
    :upload_sessions_full,
    :upload_speakers,
    :upload_exhibitors,
    :upload_maps,
    :upload_mobileconfs,
    :upload_attendees,
    :upload_notifications,
    :upload_home_buttons
  )

  track_history(
    "Other",
    :populate_preselected_attendee_favourites,
    :avma_regenerate_attendee_tags,
    :update_track_subtrack,
    :refresh_custom_adjustment_script,
    :create_exhibitor_files_for_placeholders,
    :create_files_for_placeholders
  )

  # def diff_event_settings
  #   a = Setting.where(event_id: params[:event_id_a])
  #   b = Setting.where(event_id: params[:event_id_b])

  #   diffs = {}

  #   a.each do |s_a|
  #     s_b = b.where(setting_type_id: s_a.setting_type_id)
  #     if s_b.first
  #       s_b = s_b.first
  #       vals = s_a.json.to_a - s_b.json.to_a
  #       diffs["#{s_a.event_id}-#{s_b.event_id}_#{s_a.setting_type.name}"] = []
  #       vals.each do |v|
  #         diffs["#{s_a.event_id}-#{s_b.event_id}_#{s_a.setting_type.name}"] << {
  #           "#{ params[:event_id_a] }_#{v[0]}" => s_a.json[v[0]],
  #           "#{ params[:event_id_b] }_#{v[0]}" => s_b.json[v[0]]
  #         }
  #       end
  #     else
  #       diffs["#{s_a.event_id}-#{params[:event_id_b]}_#{s_a.setting_type.name}"] = "No setting for #{params[:event_id_b]}"
  #     end
  #   end

  #   render :json => diffs
  # end

  # for hiding events in multi event listing in cordova app
  before_action :convert_ids_string_to_array, only: [:create, :update]
  def hide_in_app_events
    @events           = Event.select('id, name, hide_in_app').all.reverse
    @hidden_event_ids = @events.reject {|e| !e.hide_in_app }.map &:id
    render layout: 'subevent_2013'
  end

  def update_hide_in_app_events

    Event.where(id:params[:event_ids]).update_all hide_in_app: true
    Event.where('id NOT IN(?)', params[:event_ids]).update_all hide_in_app: nil

    respond_to do |f|
      f.html {
        redirect_to(
          "/events/hide_in_app_events",
          :notice => "Updated Events Hidden In App (#{(params[:event_ids] || []).join(', ')})"
        )
      }
    end
  end

  def change_reports
    # @change_reports = Dir["./public/event_data/#{session[:event_id].to_s}/deltas/*.xlsx"].reverse.map do |file|
    #   {
    #     name: file.split('/').last.split('_delta').first,
    #     date: Time.parse( file.split('_').last.gsub('.xlsx', '') ).strftime('%D %T'),
    #     path: "#{file.split('public').last}"
    #   }
    # end

    @change_reports = ChangeReport.where(event_id: session[:event_id])
    render layout: "dashboard"
  end

  # for hiding events from admin list of events in cms
  def hidden_events
    @events           = Event.select('id, name').all.reverse
    @hidden_event_ids = HiddenEvent.where(user_id: current_user.id).pluck(:event_id)
    render layout: 'subevent_2013'
  end

  def update_hidden_events

    params[:event_ids].each do |event_id|
      HiddenEvent.where(event_id:event_id, user_id: current_user.id).first_or_create
    end

    HiddenEvent.
      where(user_id:current_user.id).
      where('event_id NOT IN(?)', params[:event_ids]).
      destroy_all

    respond_to do |f|
      f.html {
        redirect_to(
          "/events/hidden_events",
          :notice => "Updated Hidden Events (#{params[:event_ids].join(', ')})"
        )
      }
    end
  end

  def edit_preset_tag_options
    @event   = Event.find(session[:event_id])
    @tag_sets = @event.tag_sets_hash || {}
    render layout: 'subevent_2013'
  end

  def update_preset_tag_options
    tag_sets_hash = params.select {|k, v|
      (k.match /set_\d*_key/) && !v.blank?
    }.to_unsafe_h.inject({}) { |memo, (key,type)|
      unless params[key.gsub('key', 'value')].blank?
        memo[type] ||= []
        memo[type] << params[key.gsub('key', 'value')].split('||')
      end
      memo
    }

    Event.find(session[:event_id]).update!(tag_sets_hash: tag_sets_hash)

    respond_to do |f|
      f.html {
        redirect_to(
          "/events/edit_preset_tag_options",
          :notice => 'Updated Event Preset Tag Options'
        )
      }
    end
  end

  def add_preset_tags 
    event_id = session[:event_id]
    tag_id   = params[:tag_id]
    tag = Tag.where(id: tag_id).first
    if tag.present?
      event = Event.where(id: event_id).first
      tag_sets = event.tag_sets_hash[tag.tag_type_id.to_s]
      if !tag_sets.flatten.include?(tag.name)
        tag_sets.last.push(tag.name)
        event.tag_sets_hash[tag.tag_type_id.to_s] = tag_sets
        event.save
        redirect_to "/settings/speaker_portal/other_tags", :notice => "Tags added to the session tag."
      else
        redirect_to "/settings/speaker_portal/other_tags", :alert => "Tag is already there."
      end
    end
  end

  def remove_preset_tags 
    event_id = session[:event_id]
    tag_id   = params[:tag_id]
    event = Event.where(id: event_id).first
    tag = Tag.where(id: tag_id).first
    if event.present?
      tag_set_hashes = event.tag_sets_hash[tag.tag_type_id.to_s]
      if tag_set_hashes.flatten.include?(tag.name)
        updated_tag_set_hashes = deep_remove!(tag.name, tag_set_hashes)
        event.tag_sets_hash[tag.tag_type_id.to_s] = updated_tag_set_hashes
        event.save
        redirect_to "/settings/speaker_portal/other_tags", :notice => "Tag removed from the session tag."
      else
        redirect_to "/settings/speaker_portal/other_tags", :alert => "Tag is not there."
      end
    end
  end

  def add_preset_keywords 
    event_id = session[:event_id]
    keyword_id   = params[:keyword_id]
    session = SessionKeyword.where(id: keyword_id).first
    if session.present?
      event = Event.where(id: event_id).first
      session_tag_type = TagType.where(name: 'session-keywords').first 
      tag_sets = event.tag_sets_hash[session_tag_type.id.to_s]
      if !tag_sets.flatten.include?(session.name)
        tag_sets.last.push(session.name)
        event.tag_sets_hash[session_tag_type.id.to_s] = tag_sets
        event.save
        redirect_to "/settings/speaker_portal/other_session_keywords", :notice => "Keyword added to the session Keywords."
      else
        redirect_to "/settings/speaker_portal/other_session_keywords", :alert => "Keyword is already there."
      end
    end
  end

  def remove_preset_keywords
    event_id = session[:event_id]
    keyword_id   = params[:keyword_id]
    session_keyword = SessionKeyword.where(id: keyword_id).first
    event = Event.where(id: event_id).first
    if event.present? && session_keyword.present?
      session_tag_type = TagType.where(name: 'session-keywords').first
      tag_sets = event.tag_sets_hash[session_tag_type.id.to_s]
      if tag_sets.flatten.include?(session_keyword.name)
        updated_tag_set_hashes = deep_remove!(session_keyword.name, tag_sets)
        event.tag_sets_hash[session_tag_type.id.to_s] = tag_sets
        event.save
        redirect_to "/settings/speaker_portal/other_session_keywords", :notice => "Keyword removed from the session Keywords."
      else
        redirect_to "/settings/speaker_portal/other_session_keywords", :alert => "Keyword not found"
      end
    end
  end

  def edit_type_to_pn_hash
    @event   = Event.find(session[:event_id])
    @pn_hash = @event.type_to_pn_hash || {}
    render layout: 'subevent_2013'
  end

  def update_type_to_pn_hash
    @event   = Event.find session[:event_id]
    # @pn_hash = @event.type_to_pn_hash || {}

    # get all the text_boxes for keys that weren't blank
    # then if the matches value text box wasn't blank as well
    # add it to a hash, resulting in the text box for a key
    # being the key, and the matching text box for a value
    # being the value
    # This code assumes every set_index_key has a matching
    # set_index_value
    # update: any type can be an array of automated filters
    filtered_entries = params.select {|k, v|
      (k.match /set_\d*_key/) && !v.blank?
    }.to_unsafe_h.inject({}) { |memo, (key,type)|
      unless params[key.gsub('key', 'value')].blank?
        memo[type] ||= []
        params[key.gsub('key', 'value')].split(',').each do |filter|
          memo[type] << filter.strip
        end
      end
      memo
    }

    # convert to camelCase and remove duplicates
    filtered_entries.each do |type, filters|
      results = []
      filters.each do |filter|
        ary = filter.split
        results << [ary[0][0].downcase + ary[0][1..-1]] # downcase first letter
            .concat(ary[1..-1].map(&:capitalize)).join # cap first letter
      end
      filtered_entries[type] = results.uniq
    end

    @event.update! type_to_pn_hash: filtered_entries

    respond_to do |f|
      f.html {
        redirect_to(
          "/events/edit_type_to_pn_hash",
          :notice => 'Event Types to Push Notification Filters Updated'
        )
      }
    end
  end

  def edit_event_settings
    @event = Event.find session[:event_id]
    @cms_domain_type_id = DomainType.where(name:"cms").first.id
    @video_portal_domain_type_id = DomainType.where(name:"video_portal").first.id
    @chat_domain_type_id = DomainType.where(name:"chat").first.id
    @reporting_domain_type_id = DomainType.where(name:"reporting").first.id
    render layout: 'subevent_2013'
  end

  def update_event_settings
    # unlike update, this method is just for toggling a few settings
    # such as push notifications keys, master url, etc

    # split into an array and convert to camel case and trim leading
    # and trailing white space
    if params[:event][:pn_filters]
      params[:event][:pn_filters] =
        params[:event][:pn_filters]
          .split(',')
          .map(&:strip)
          .map {|a|
            ary = a.split
            [ary[0][0].downcase + ary[0][1..-1]] # downcase first letter
             .concat(ary[1..-1].map(&:capitalize)).join # cap first letter
          }.to_s
    end

    Event.find( session[:event_id] ).update! event_params
    respond_to do |f|
      f.html { redirect_to("/dev", :notice => 'Event Settings Updated') }
    end
  end

  # def mobile_data

  #  @empty_data = "[]"

  # if (params[:event_id]) then
  #   @events = Event.select('event_files.path AS logo_file_path,events.id').joins('LEFT OUTER JOIN event_files ON events.logo_event_file_id=event_files.id').where("events.id= ? AND events.id > ?",params[:event_id],params[:record_start_id]).order('events.id ASC').limit(100)
  #     if (@events.length > 0) then
  #       render :json => @events.to_json, :callback => params[:callback]
  #     else
  #       render :json => @empty_data, :callback => params[:callback]
  #     end
  #   end
  # end

  def add_files_to_placeholders
    @event = Event.where(id:session[:event_id]).first

    respond_to do |format|
      format.html { render "add_files_to_placeholders", :layout => "subevent_2013" }# configure.html.erb
      #format.xml  { render :xml => @event }
    end
  end

  def create_files_for_placeholders
    @event = Event.where(id:session[:event_id]).first
    @event.fillPlaceholders(params)
    Session.where(event_id: session[:event_id]).each &:update_session_file_urls_json
    message = ''

    params[:event_files].each do |file|
      message += "#{file.original_filename} "
    end

    respond_to do |format|
      unless @event.errors.full_messages.length > 0
        format.html { redirect_to("/events/add_files_to_placeholders", :notice => "#{message} successfully added.")}
      else
        format.html { redirect_to("/events/add_files_to_placeholders", :alert => "#{@event.errors.full_messages.each do |error|; error end}")}
      end
    end

  end

  def add_exhibitor_files_to_placeholders
    @event = Event.where(id:session[:event_id]).first

    respond_to do |format|
      format.html { render "add_exhibitor_files_to_placeholders", :layout => "subevent_2013" }
    end
  end

  def create_exhibitor_files_for_placeholders
    @event = Event.where(id:session[:event_id]).first
    @event.fillExhibitorFilePlaceholders(params)
    message = ''

    params[:event_files].each do |file|
      message += "#{file.original_filename} "
    end

    respond_to do |format|
      unless @event.errors.full_messages.length > 0
        format.html { redirect_to("/events/add_exhibitor_files_to_placeholders", :notice => "#{message} successfully added.")}
      else
        format.html { redirect_to("/events/add_exhibitor_files_to_placeholders", :alert => "#{@event.errors.full_messages.each do |error|; error end}")}
      end
    end

  end

  def index
    @events = Event.all.order(event_start_at: :desc)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
    end
  end

  def indexfororg
    @events = Event.where("org_id = ?",params[:org_id])
    @organization_for_events = Organization.find(params[:org_id])

    respond_to do |format|
      #format.html { render :layout => "superadmin_2013" } # indexfororg.html.erb
      format.xml  { render :xml => @event }
    end
  end

  def configure
    selected_event = params[:event_id]
    @form_token = form_authenticity_token

    @jobs = Job.where("event_id= ? AND updated_at >= ?", session[:event_id], Time.zone.now.beginning_of_day)

    if current_user.role? :super_admin
      @event = Event.find(session[:event_id])
      @script_buttons = Script.where(event_id:@event.id, published:true)
      respond_to do |format|
        format.html { render "configure", :layout => "dashboard" }
      end
    elsif current_user.role? :client
      if current_user.users_events.where(event_id:selected_event).length > 0
        @event = Event.find(session[:event_id])
        @script_buttons = Script.where(event_id:@event.id, published:true)
        respond_to do |format|
          format.html { render "configure", :layout => "dashboard" }
        end
      else
        render :text => "You do not have access to this event."
      end
    end
  end

  # def refresh_external_api_import_script
  #   Rails.cache.clear
  #   Rails::logger.debug "refresh_external_api_import_script"
  #   @event = Event.find(session[:event_id])
  #   Rails::logger.debug "name: #{@event.name}"
  #   script = Script.find(params[:script_id])
  #   file_name = script.file_name
  #   Rails::logger.debug "file_name: #{file_name}"

  #   #specific to this method. Other file locations will need a new method
  #   script_path = "ek_scripts/external-api-imports"
    
  #   if params[:job_id]
  #     script_path = Rails.root.join("#{script_path}/#{file_name} \"#{session[:event_id]}\" \"#{params[:job_id]}\"")
  #     Rails::logger.debug "Script path #{script_path}"
  #     pid = Process.spawn("ROO_TMP='/tmp' ruby #{script_path} 2>&1")
  #     Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
  #     Job.find(params[:job_id]).update!(pid:pid)
  #     Process.detach pid
  #   else
  #     script_path = Rails.root.join("#{script_path}/#{file_name} \"#{session[:event_id]}\"")
  #     Rails::logger.debug "Script path #{script_path}"
  #     pid = Process.spawn("ROO_TMP='/tmp' ruby #{script_path} 2>&1")
  #     Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
  #     Process.detach pid
  #   end
  #   render :json => {status:true}
  # end

  def refresh_external_api_import_script
    Rails.cache.clear
    Rails::logger.debug "refresh_external_api_import_script"
    @event = Event.find(session[:event_id])
    Rails::logger.debug "name: #{@event.name}"
    script = Script.find(params[:script_id])
    file_name = script.file_name
    # refresh = false
    # attendee_type = "standard_attendee"
    # if script.button_label.include?("Refresh")
    # end
    script.button_label.include?("Exhibitors") ? attendee_type = "Exhibitor" : attendee_type = "standard_attendee"
    script.button_label.include?("Refresh") ? refresh = true : refresh = false
    Rails::logger.debug "file_name: #{file_name}"
    #specific to this method. Other file locations will need a new method
    script_path = "ek_scripts/external-api-imports"

    if params[:job_id]
      script_path = Rails.root.join("#{script_path}/#{file_name} \"#{session[:event_id]}\" \"#{params[:job_id]}\" \"#{refresh}\" \"#{attendee_type}\"")
      Rails::logger.debug "Script path #{script_path}"
      pid = Process.spawn("ROO_TMP='/tmp' ruby #{script_path} 2>&1")
      Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
      Job.find(params[:job_id]).update!(pid:pid)
      Process.detach pid
    else
      script_path = Rails.root.join("#{script_path}/#{file_name} \"#{session[:event_id]}\"")
      Rails::logger.debug "Script path #{script_path}"
      pid = Process.spawn("ROO_TMP='/tmp' ruby #{script_path} 2>&1")
      Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
      Process.detach pid
    end
    render :json => {status:true}
  end

  def show
    @event = Event.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
    end
  end

  def new
    @event = Event.new

    #all available users
    @users = User.select('users.*').joins('
      JOIN users_roles ON users_roles.user_id=users.id
      JOIN roles ON users_roles.role_id=roles.id
      ').where('roles.name=? OR roles.name=?','Client','SuperAdmin')

    @organization_id = params[:organization_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  def edit
    @event = Event.find(params[:id])

    #all available users
    @users = User.select('users.*').joins('
      JOIN users_roles ON users_roles.user_id=users.id
      JOIN roles ON users_roles.role_id=roles.id
      ').where('roles.name=? OR roles.name=?','Client','SuperAdmin')

    #previously selected users
    @selected_users = User.select('users.*').joins('
      JOIN users_events ON users.id=users_events.user_id
      ').where('users_events.event_id=?',params[:id])

    @user_list=[]
    @selected_users.each do |user|
      @user_list << user.id
    end

    #set org id
    @organization_id = @event.org_id

  end

  def create
    @event = Event.new(event_params)
    @event.userselect=params[:user_ids]

    #add logo image
    if (params[:photo_file]!=nil) then
			uploaded_io = params[:photo_file]
			event_file_type_id      = EventFileType.where(name:"event_logo").first.id
			filename                = uploaded_io.original_filename
			file_extension          = File.extname uploaded_io.original_filename
			event_file              = EventFile.where(event_id:event_id,event_file_type_id:event_file_type_id).first_or_initialize
			target_path 						= Rails.root.join('public','event_data', session[:event_id].to_s,'event_logo').to_path
			cloud_storage_type_id   = Event.find(session[:event_id]).cloud_storage_type_id
			cloud_storage_type      = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
			end

			UploadEventFileImage.new(
				event_file:              event_file,
				image:                   uploaded_io,
				target_path:             target_path,
				new_filename:            filename,
				event_file_owner: 			 @event,
				event_file_assoc_column: :logo_event_file_id,
				cloud_storage_type:      cloud_storage_type
			).call
		end

    respond_to do |format|
      if @event.save
        #add users to event
        params[:user_ids].each do |user_id|
          puts "adding user_id: #{user_id} to event"
          @user_event= UsersEvent.new
          @user_event.user_id=user_id
          @user_event.event_id=@event.id
          @user_event.save
        end

        #create the event_data file structure
        FileOperations.create_directories(
          0777,
          'deploy',
          'deploy',
          [
            Rails.root.join('public', 'event_data', @event.id.to_s),
            Rails.root.join('public', 'event_data', @event.id.to_s,'import_data'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'maps'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'session_files'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'speaker_photos'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'speaker_cvs'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'speaker_fds'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'speaker_pdfs'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'room_layouts'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'event_logo'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'exhibitor_logos'),
            # Rails.root.join('public', 'event_data', @event.id.to_s,'enhanced_listing_images'),
            # Rails.root.join('public', 'event_data', @event.id.to_s,'session_link_files'),
            Rails.root.join('public', 'event_data', @event.id.to_s,'home_button_group_images'),
            # Rails.root.join('public', 'event_data', @event.id.to_s,'home_button_entry_images')
          ]
        )

        ### copy defaults into event_data subfolders ###

        #home screen icons
        src=Rails.root.join('public', 'defaults','home_button_group_images/*')
        dst=Rails.root.join('public', 'event_data', @event.id.to_s,'home_button_group_images/')
        cp_result=`cp #{src} #{dst}`

        #exhibitor logos
        src=Rails.root.join('public', 'defaults','exhibitor_logos/*')
        dst=Rails.root.join('public', 'event_data', @event.id.to_s,'exhibitor_logos/')
        cp_result=`cp #{src} #{dst}`

        #speaker photos
        src=Rails.root.join('public', 'defaults','speaker_photos/*')
        dst=Rails.root.join('public', 'event_data', @event.id.to_s,'speaker_photos/')
        cp_result=`cp #{src} #{dst}`

        #maps
        src=Rails.root.join('public', 'defaults','maps/*')
        dst=Rails.root.join('public', 'event_data', @event.id.to_s,'maps/')
        cp_result=`cp #{src} #{dst}`

        #event logo
        src=Rails.root.join('public', 'defaults','event_logo/*')
        dst=Rails.root.join('public', 'event_data', @event.id.to_s,'event_logo/')
        cp_result=`cp #{src} #{dst}`

        format.html { redirect_to("/organizations/#{@event.org_id}", :notice => 'Event was successfully created.') }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else

        #@event = Event.new

        #all available users
        @users = User.select('users.*').joins('
          JOIN users_roles ON users_roles.user_id=users.id
          JOIN roles ON users_roles.role_id=roles.id
          ').where('roles.name=? OR roles.name=?','Client','SuperAdmin')

        @organization_id = params[:organization_id]

       format.html { render :action => "new" }
       format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @event = Event.find(params[:id])

    @event.userselect=params[:user_ids]

    #all available users
    @users = User.select('users.*').joins('
      JOIN users_roles ON users_roles.user_id=users.id
      JOIN roles ON users_roles.role_id=roles.id
                                          ').where('roles.name=? OR roles.name=?','Client','SuperAdmin')

    #previously selected users
    @selected_users = User.select('users.*').joins('
      JOIN users_events ON users.id=users_events.user_id
                                                   ').where('users_events.event_id=?',params[:id])

    @user_list=[]
    @selected_users.each do |user|
      @user_list << user.id
    end

    #add logo image
    if (params[:photo_file]!=nil) then
      #upload the image
      uploaded_io = params[:photo_file]
      File.open(Rails.root.join('public','event_data', params[:id].to_s,'event_logo',uploaded_io.original_filename), 'wb',0777) do |file|
        file.write(uploaded_io.read)
      end
      #file table ref
      @event_file = EventFile.new
      @event_file.name=uploaded_io.original_filename
      @event_file.path="/event_data/#{params[:id].to_s}/event_logo/#{uploaded_io.original_filename}"
      @event_file.event_id= @event.id
      @event_file.save()

      @event.logo_event_file_id=@event_file.id
    end

    #clear event users with roles Client or SuperAdmin (leaving Speaker Portal users alone)
    @users_event = UsersEvent.joins("
        LEFT JOIN users_roles ON users_roles.user_id=users_events.user_id
        LEFT JOIN roles ON users_roles.role_id=roles.id").where("(roles.name = ? OR roles.name =?) AND event_id = ?", "Client","SuperAdmin", params[:id])
    @users_event.each do |event_user|
      event_user.delete
    end

    #add selected users to event
    params[:user_ids].each do |user_id|
      puts "adding user_id: #{user_id} to event"
      @user_event= UsersEvent.where(user_id:user_id,event_id:@event.id).first_or_initialize()
      @user_event.save()
      #@user_event.user_id=user_id
      #@user_event.event_id=@event.id
      #@user_event.save
    end

    respond_to do |format|
      if @event.update!(event_params)
        format.html { redirect_to("/organizations/#{@event.org_id}", :notice => 'Event was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to("/organizations/#{@event.org_id}") }
      format.xml  { head :ok }
    end
  end

  def upload_sessions

    Rails::logger.debug "starting upload sessions"

    Rails.cache.clear

    @event = Event.find(session[:event_id]) #select('events.id').where('events.id = ?',session[:event_id]).first
    #puts "SESSION FILE: #{params[:sessions_file]}"
    #uploaded_io.original_filename

    #create directory structure if necessary
    uploaded_io = params[:file]
    dirname = File.dirname(Rails.root.join('public','event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename))
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    #upload the session data ODS file

    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import session data spreadsheet into the database
    ods_session_path = Rails.root.join('public', 'event_data',@event.id.to_s,'import_data',uploaded_io.original_filename)
    session_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-sessions-mysql2-matched.rb \"#{@event.id}\" \"#{ods_session_path}\" \"#{params[:job_id]}\" \"#{current_user.id}\"")


    puts "ODS/XLS PATH #{ods_session_path}"
    puts "SESSION CMD #{session_import_cmd}"

    pid = Process.spawn("ROO_TMP='/tmp' ruby #{session_import_cmd} 2>&1")
    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    #puts "\n--------- import script output ---------\n\n #{@import_session_result} \n------------------- \n"
    #@import_session_result.gsub!(/\n/,"<br/>")

    #if request.xhr? || remotipart_submitted?
    # render :upload_sessions
    #else
    # render :configure
    #end

    respond_to do |format|
      #format.js   { render :upload_sessions }
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end
  end

  # def download_sessions

  #   @event_id = session[:event_id]
  #   @sessions = Session.where(event_id:@event_id)

  #   respond_to do |format|
  #     format.xlsx { render :action => :download_sessions, disposition: "attachment", filename: "session_data.xlsx" }
  #   end
  # end

  def upload_sessions_full

    Rails::logger.debug "starting upload sessions"

    Rails.cache.clear

    @event      = Event.find(session[:event_id])
    uploaded_io = params[:file]
    dirname     = Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data')

    ensure_directory_exists(dirname)

    #upload the session data ODS file

    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import session data spreadsheet into the database
    ods_session_path = Rails.root.join('public', 'event_data',@event.id.to_s,'import_data',uploaded_io.original_filename)
    session_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-sessions-full-mysql2-matched.rb \"#{@event.id}\" \"#{ods_session_path}\" \"#{params[:job_id]}\" \"#{current_user.id}\"")

    puts "ODS/XLS PATH #{ods_session_path}"
    puts "SESSION CMD #{session_import_cmd}"


    pid = Process.spawn("ROO_TMP='/tmp' ruby #{session_import_cmd} 2>&1")
    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    respond_to do |format|
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end
  end

  # def download_sessions_full

  #   @event_id = session[:event_id]
  #   @sessions = Session.where(event_id:@event_id)

  #   respond_to do |format|
  #     format.xlsx { render :action => :download_sessions_full, disposition: "attachment", filename: "session_data_full.xlsx" }
  #   end
  # end

  def upload_speakers

    Rails::logger.debug "starting upload speakers"

    Rails.cache.clear

    @event = Event.find(session[:event_id])

    #create directory structure if necessary
    uploaded_io = params[:file]
    dirname = File.dirname(Rails.root.join('public','event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename))
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    #upload the speaker data ODS file

    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import speaker data spreadsheet into the database
    ods_speaker_path = Rails.root.join('public', 'event_data',@event.id.to_s,'import_data',uploaded_io.original_filename)
    speaker_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-speakers-mysql2-matched.rb \"#{@event.id}\" \"#{ods_speaker_path}\" \"#{params[:job_id]}\" \"#{current_user.id}\"")

    puts "ODS/XLS PATH #{ods_speaker_path}"
    puts "SPEAKER CMD #{speaker_import_cmd}"


    pid = Process.spawn("ROO_TMP='/tmp' ruby #{speaker_import_cmd} 2>&1")
    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    #puts "\n--------- import script output ---------\n\n #{@import_speaker_result} \n------------------- \n"
    #@import_speaker_result.gsub!(/\n/,"<br/>")

    #if request.xhr? || remotipart_submitted?
    # render :upload_speakers
    #else
    # render :configure
    #end

    respond_to do |format|
      #format.js   { render :upload_speakers }
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end
  end

  # this is now located in Reports Controller, to take advantage of instance methods related to jobs defined there
  # def download_speakers

  #   @event_id = session[:event_id]
  #   @speakers = Speaker.where(event_id:@event_id)

  #   respond_to do |format|
  #     format.xlsx { render :action => :download_speakers, disposition: "attachment", filename: "speaker_data.xlsx" }
  #   end
  # end

  def upload_captrust_exhibitors
    Rails.cache.clear

    @event = Event.find(session[:event_id])

    uploaded_io = params[:exhibitors_file]

    #create directory structure if necessary
    dirname = File.dirname(Rails.root.join('public','event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename))
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import exhibitor data spreadsheet into the database
    ods_exhibitor_path   = Rails.root.join('public', 'event_data',session[:event_id].to_s,'import_data',uploaded_io.original_filename)
    exhibitor_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-exhibitors-mysql2-matched-v3-captrust-mod.rb \"#{session[:event_id]}\" \"#{ods_exhibitor_path}\"")

    puts "ODS/XLS PATH #{ods_exhibitor_path}"
    puts "EXHIBITOR CMD #{exhibitor_import_cmd}"

    @import_exhibitor_result = `ROO_TMP='/tmp' ruby #{exhibitor_import_cmd} 2>&1`
    Rails::logger.debug "\n--------- import script output ---------\n\n #{@import_exhibitor_result} \n------------------- \n"
    @import_exhibitor_result.gsub!(/\n/,'<br/>')

    respond_to do |format|
      format.js   { render :upload_exhibitors }
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end
  end

  def upload_exhibitors

    Rails.cache.clear

    @event = Event.find(session[:event_id])

    uploaded_io = params[:file]

    #create directory structure if necessary
    dirname = File.dirname(Rails.root.join('public','event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename))
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import exhibitor data spreadsheet into the database
    ods_exhibitor_path   = Rails.root.join('public', 'event_data',session[:event_id].to_s,'import_data',uploaded_io.original_filename)
    exhibitor_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-exhibitors-mysql2-matched-v3.rb \"#{session[:event_id]}\" \"#{ods_exhibitor_path}\" \"#{params[:job_id]}\" \"#{current_user.id}\"")

    puts "ODS/XLS PATH #{ods_exhibitor_path}"
    puts "EXHIBITOR CMD #{exhibitor_import_cmd}"

    pid = Process.spawn("ROO_TMP='/tmp' ruby #{exhibitor_import_cmd} 2>&1")
    Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
    # @import_exhibitor_result.gsub!(/\n/,'<br/>')

    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    respond_to do |format|
      format.js   { render :upload_exhibitors }
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end
  end

  # this is now located in Reports Controller, to take advantage of instance methods related to jobs defined there
  # def download_exhibitors

  #   @event_id   = session[:event_id]
  #   @exhibitors = Exhibitor.where(event_id:@event_id)

  #   respond_to do |format|
  #     format.xlsx { render :action => :download_exhibitors, disposition: "attachment", filename: "exhibitor_data.xlsx" }
  #   end
  # end

  def upload_maps

    Rails.cache.clear

    @event      = Event.find(session[:event_id])
    #upload the session data ODS file
    uploaded_io = params[:file]
    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import map spreadsheet into the database
    ods_map_path   = Rails.root.join('public', 'event_data',session[:event_id].to_s,'import_data',uploaded_io.original_filename)
    map_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-maps-mysql2-matched.rb \"#{session[:event_id]}\" \"#{ods_map_path}\" \"#{params[:job_id]}\" \"#{current_user.id}\"")

    puts "ODS/XLS PATH #{ods_map_path}"
    puts "map CMD #{map_import_cmd}"

    pid = Process.spawn("ROO_TMP='/tmp' ruby #{map_import_cmd} 2>&1")
    Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    respond_to do |format|
      format.js   { render :upload_maps }
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end
  end

  def download_maps

    @event_id = session[:event_id]
    @maps     = LocationMapping.where(event_id:@event_id)

    respond_to do |format|
      format.xlsx { render :action => :download_maps, disposition: "attachment", filename: "map_data.xlsx" }
    end
  end

  def upload_mobileconfs

    Rails.cache.clear

    @event = Event.find(session[:event_id])
  #upload the session data ODS file
    uploaded_io = params[:file]
    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import mobileconf data spreadsheet into the database
    ods_mobileconf_path = Rails.root.join('public', 'event_data',session[:event_id].to_s,'import_data',uploaded_io.original_filename)
    mobileconf_import_cmd = Rails.root.join('ek_scripts',"import-mobileconfs-mysql2.rb \"#{session[:event_id]}\" \"#{ods_mobileconf_path}\" \"#{params[:job_id]}\"")

    puts "ODS/XLS PATH #{ods_mobileconf_path}"
    puts "mobileconf CMD #{mobileconf_import_cmd}"

    pid = Process.spawn("ROO_TMP='/tmp' ruby #{mobileconf_import_cmd} 2>&1")
    Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    respond_to do |format|
      format.js   { render :upload_mobileconfs }
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end

  end

  # def download_mobileconfs

  #   @event_id = session[:event_id]

  #   respond_to do |format|
  #     format.xlsx { render :action => :download_mobileconfs, disposition: "attachment", filename: "mobile_configuration_data.xlsx" }
  #   end
  # end

  def upload_attendees

    Rails.cache.clear

    @event = Event.find(session[:event_id])

    #create directory structure if necessary
    uploaded_io = params[:file]
    dirname = File.dirname(Rails.root.join('public','event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename))
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    #upload the session data ODS file

    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import attendee data spreadsheet into the database
    ods_attendee_path   = Rails.root.join('public', 'event_data',session[:event_id].to_s,'import_data',uploaded_io.original_filename)
    attendee_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-attendees-mysql2-matched-v2.rb \"#{session[:event_id]}\" \"#{ods_attendee_path}\" \"#{params[:job_id]}\" \"#{current_user.id}\"")

    puts "ODS/XLS PATH #{ods_attendee_path}"
    puts "attendee CMD #{attendee_import_cmd}"

    pid = Process.spawn("ROO_TMP='/tmp' ruby #{attendee_import_cmd} 2>&1")
    Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    respond_to do |format|
      format.js   { render :upload_attendees }
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end

  end

  # this is now located in Reports Controller, to take advantage of instance methods related to jobs defined there
  # def download_attendees
  #   @event_id = session[:event_id]
  #   respond_to do |format|
  #     format.xlsx { render :action => :download_attendees, disposition: "attachment", filename: "attendee_data.xlsx" }
  #   end
  # end

  def upload_notifications

    Rails.cache.clear

    @event = Event.find(session[:event_id])

    #create directory structure if necessary
    uploaded_io = params[:file]
    dirname = File.dirname(Rails.root.join('public','event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename))
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    #upload the notification data ODS file

    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import attendee data spreadsheet into the database
    ods_notification_path   = Rails.root.join('public', 'event_data',session[:event_id].to_s,'import_data',uploaded_io.original_filename)
    notification_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-notifications-matched.rb \"#{session[:event_id]}\" \"#{ods_notification_path}\" \"#{params[:job_id]}\" \"#{current_user.id}\"")

    puts "ODS/XLS PATH #{ods_notification_path}"
    puts "attendee CMD #{notification_import_cmd}"

    pid = Process.spawn("ROO_TMP='/tmp' ruby #{notification_import_cmd} 2>&1")
    Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    respond_to do |format|
      # format.js   { render :upload_notifications }
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end

  end

  def download_notifications
    @event_id = session[:event_id]
    respond_to do |format|
      format.xlsx { render(action:      :download_notifications,
                           disposition: "attachment",
                           filename:    "notification_data.xlsx") }
    end
  end

  def upload_mobile_css
    @event = Event.find(session[:event_id])

    #create directory structure if necessary
    uploaded_io = params[:file]
    m = uploaded_io.original_filename.match(/.*(.css|.scss)$/i)
    if (m!=nil) then
      file_ext = m[1]
    else
      respond_to do |format|
        format.html { redirect_to("/events/configure/#{session[:event_id]}", :alert => 'Invalid file format. It can accept .css or .scss files') }
      end
      return
    end
    target_path             = Rails.root.join('public','event_data', session[:event_id].to_s,'mobile_css')
    cloud_storage_type_id   = Event.find(session[:event_id]).cloud_storage_type_id
    cloud_storage_type      = nil
    unless cloud_storage_type_id.blank?
      cloud_storage_type 		= CloudStorageType.find(cloud_storage_type_id)
    end
    # Please create new EventFileType with name = 'mobile_css'
    event_file_type_id 			= EventFileType.where(name:'mobile_css').first.id
    event_file							= EventFile.where(event_id: session[:event_id], event_file_type_id: event_file_type_id).first_or_initialize

    UploadEventFile.new(
      event_file:              event_file,
      file:                    uploaded_io,
      target_path:             target_path,
      new_filename:            'event_styles.css',
      cloud_storage_type:      cloud_storage_type
    ).call
    respond_to do |format|
      format.html { redirect_to("/event_settings/edit_restricted_event_settings", :notice => 'File was successfully uploaded.') }
    end
  end

  def upload_home_buttons

    Rails.cache.clear

    @event = Event.find(session[:event_id])

    #create directory structure if necessary
    uploaded_io = params[:file]
    dirname = File.dirname(Rails.root.join('public','event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename))
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    #upload the home_button data ODS file

    File.open(Rails.root.join('public', 'event_data', session[:event_id].to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end

    #import home_button data spreadsheet into the database
    ods_home_button_path   = Rails.root.join('public', 'event_data',session[:event_id].to_s,'import_data',uploaded_io.original_filename)
    home_button_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-home-buttons-matched.rb \"#{session[:event_id]}\" \"#{ods_home_button_path}\" \"#{params[:job_id]}\" \"#{current_user.id}\"")

    puts "ODS/XLS PATH #{ods_home_button_path}"
    puts "attendee CMD #{home_button_import_cmd}"

    pid = Process.spawn("ROO_TMP='/tmp' ruby #{home_button_import_cmd} 2>&1")
    Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    respond_to do |format|
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end

  end

  def download_home_buttons
    @event_id = session[:event_id]
    respond_to do |format|
      format.xlsx { render(action:      :download_home_buttons,
                           disposition: "attachment",
                           filename:    "home_button_data.xlsx") }
    end
  end

  def deleteall_home_buttondata
    [HomeButton, CustomList, CustomListItem].each {|m|
      m.where(event_id:session[:event_id]).destroy_all }
    respond_to do |format|
      format.html { redirect_to("/events/configure/#{session[:event_id]}",
                                :notice => 'Home Button data was successfully deleted.') }
    end
  end

  def deleteall_notificationdata
    Notification.where(event_id:session[:event_id]).destroy_all
    respond_to do |format|
      format.html { redirect_to("/events/configure/#{session[:event_id]}",
                                :notice => 'Notification data was successfully deleted.') }
    end
  end

  def deleteall_homebuttondata
    HomeButton.where(event_id:session[:event_id]).destroy_all
    respond_to do |format|
      format.html { redirect_to("/events/configure/#{session[:event_id]}",
                                :notice => 'Home Button data was successfully deleted.') }
    end
  end

  # first idea about a special destroy_all script;
  # but for sessions which have about 15 different associations,
  # and associations for those associations a few levels deeper,
  # it was melting the computer. So instead we'll do something a
  # little more tricky, which is getting the association schema
  # and manually building up the delete_all queries which we
  # know to be very fast.
  # def destroy_all_script script_name, event_id, job_id
  #   Rails::logger.debug "deleteall - running script: #{script_name}"
  #   # not sure why this line is in all our download methods;
  #   # is it safety against cached sql queries? Maybe clients were
  #   # getting old data at some point years ago.
  #   Rails.cache.clear

  #   puts script_name

  #   delete_script = Rails.root.join(
  #     'ek_scripts',
  #     'config_page_scripts',
  #     "#{script_name}.rb \"#{event_id}\" \"#{job_id}\""
  #   )

  #   pid = Process.spawn("ROO_TMP='/tmp' ruby #{delete_script} 2>&1")
  #   Job.find( job_id ).update! pid: pid
  #   Process.detach pid
  # end

  # deleteall_sessiondata is too slow even when the only destroy_all
  # is on Session and Speaker. But not so slow it can't be a job. So
  # the data get wiped with delete_alls on most things, which should
  # prevent crazy numbers of objects from being loaded into memory, but
  # every session will still end up doing a bunch of sql queries because
  # activerecord is not smart enough to do joins by itself for destroy_all
  # def deleteall_sessiondata

  #   destroy_all_script "destroy_all_sessions", session[:event_id], params[:job_id]

  #   respond_to do |format|
  #       format.html {
  #         redirect_to("/events/configure/#{session[:event_id]}",
  #                     :notice => 'Session Data was successfully deleted.')
  #       }
  #   end
  # end

  def deleteall_sessiondata_preivew
    @session_data = ModelInfo.count_all_dependent_destroy_records_for_event( Session, :event_id, session[:event_id] )
    @speaker_data = ModelInfo.count_all_dependent_destroy_records_for_event( Speaker, :event_id, session[:event_id] )
    render layout: 'subevent_2013'
  end

  def deleteall_sessiondata
    # we are not able to properly call destroy_all on Session because of the very large number
    # of callbacks it invokes due to its many, many relationships. Even calling delete_all
    # on problem tables first is not enough. So we have this somewhat difficult to maintain method,
    # but at the very least it is the only one that works this way, the others all use destroy_all.
    #
    # ModelInfo.ids_for_all_dependent_destroy_records_for_event does seem like something that could
    # programmatically keep these delete_alls maintained, but at the time of writing I've deemed it
    # to risky to add into production. It seems to work, but it may have bugs. It is very similar
    # to count_all_dependent_destroy_records_for_event
    #
    # use these functions to help you keep this function up to date
    # @session_data = ModelInfo.count_all_dependent_destroy_records_for_event( Session, :event_id, session[:event_id] )
    # @speaker_data = ModelInfo.count_all_dependent_destroy_records_for_event( Speaker, :event_id, session[:event_id] )

    Rails.cache.clear

    event_id       = session[:event_id]
    session_ids    = Session.where(event_id:event_id).pluck(:id)
    speaker_ids    = Speaker.where(event_id:event_id).pluck(:id)
    event_file_ids = []

    event_file_ids << SpeakerFile.where(event_id:event_id).pluck(:event_file_id).reject { |f| f.nil? || f.blank? }
    event_file_ids << SessionFileVersion.where(event_id:event_id).pluck(:event_file_id).reject { |f| f.nil? || f.blank? }
    event_file_ids << Speaker.where(event_id:event_id).pluck(:photo_event_file_id).reject { |f| f.nil? || f.blank? }
    event_file_ids << Speaker.where(event_id:event_id).pluck(:cv_event_file_id).reject { |f| f.nil? || f.blank? }
    event_file_ids << Speaker.where(event_id:event_id).pluck(:fd_event_file_id).reject { |f| f.nil? || f.blank? }

    event_file_ids.flatten!

    EventFile.where(id:event_file_ids).delete_all

    #delete related session rows
    # could be refactored into a lambda which just takes the classes
    SessionsTrackowner.where(session_id:session_ids).delete_all
    SessionsSubtrack.where(session_id:session_ids).delete_all
    SessionsSponsor.where(session_id:session_ids).delete_all
    SessionsAttendee.where(session_id:session_ids).delete_all
    SurveySession.where(session_id:session_ids).delete_all
    TagsSession.where(session_id:session_ids).delete_all
    SessionFile.where(event_id:event_id).delete_all
    SessionFileVersion.where(event_id:event_id).delete_all
    SessionAvRequirement.where(event_id:event_id).delete_all
    SessionsRoomLayout.where(event_id:event_id).delete_all

    # new
    AttendeeScan.where(session_id: session_ids).delete_all
    SurveySession.where(session_id: session_ids).delete_all

    Session.where(event_id:event_id).delete_all

    #delete related Speaker rows
    SpeakerTravelDetail.where(speaker_id:speaker_ids).delete_all
    SpeakerPaymentDetail.where(speaker_id:speaker_ids).delete_all
    SpeakerFile.where(event_id:event_id).delete_all
    SessionsSpeaker.where(session_id:session_ids).delete_all

    Speaker.where(event_id:event_id).delete_all

    respond_to do |format|
        format.html { redirect_to("/events/configure/#{event_id}", :notice => 'Session Data was successfully deleted.') }
    end
  end

  def deleteall_sessiontags
    event_id    = session[:event_id]
    session_ids = Session.where(event_id:event_id).pluck(:id)
    tag_ids     = Tag
      .where('event_id=? AND (tag_types.name="session" OR tag_types.name="session-audience")', event_id)
      .joins('LEFT JOIN tag_types ON tag_types.id=tags.tag_type_id')
      .pluck(:id)
    Tag.where(id:tag_ids).delete_all
    TagsSession.where(session_id:session_ids).delete_all
    respond_to do |format|
      format.html { redirect_to("/tags_generation_center", :notice => 'Session Tags were successfully deleted.') }
    end
  end

  def deleteall_exhibitortags
    event_id      = session[:event_id]
    exhibitor_ids = Exhibitor.where(event_id:event_id).pluck(:id)
    tag_ids       = Tag
      .where('event_id=? AND tag_types.name="exhibitor"', event_id)
      .joins('LEFT JOIN tag_types ON tag_types.id=tags.tag_type_id')
      .pluck(:id)

    Tag.where(id:tag_ids).delete_all
    TagsExhibitor.where(exhibitor_id:exhibitor_ids).delete_all

    respond_to do |format|
      format.html { redirect_to("/tags_generation_center", :notice => 'Exhibitor Tags were successfully deleted.') }
    end
  end

  def deleteall_attendeetags
    event_id      = session[:event_id]
    attendee_ids = Attendee.where(event_id:event_id).pluck(:id)
    tag_ids       = Tag
      .where('event_id=? AND tag_types.name="attendee"', event_id)
      .joins('LEFT JOIN tag_types ON tag_types.id=tags.tag_type_id')
      .pluck(:id)

    Tag.where(id:tag_ids).delete_all
    TagsAttendee.where(attendee_id:attendee_ids).delete_all

    respond_to do |format|
      format.html { redirect_to("/tags_generation_center", :notice => 'Attendee Tags were successfully deleted.') }
    end
  end

  def deleteall_exhibitordata

    Rails.cache.clear

    @event = Event.find(session[:event_id])
    @exhibitors = Exhibitor.where('event_id=?',session[:event_id])
    @exhibitors.destroy_all

    @location_mappings = LocationMapping.where('event_id=? AND mapping_type=?',session[:event_id],2)
    @location_mappings.destroy_all

    @exhibitor_files = ExhibitorFile.where(event_id:session[:event_id]).destroy_all
    # this query doesn't make sense; there's not even and exhibitor_ids defined, so it would be
    # deleting all exhibitor_id == nil; the destroy_all should take care of it
    # TagsExhibitor.where(exhibitor_id:exhibitor_ids).delete_all

    respond_to do |format|
      format.html { redirect_to("/events/configure/#{session[:event_id]}", :notice => 'Exhibitor Data was successfully deleted.') }
    end
  end

  def deleteall_mappingdata

    Rails.cache.clear

    @event = Event.find(session[:event_id])

    @location_mappings = LocationMapping.where('event_id=?',session[:event_id])
    @location_mappings.destroy_all
    @event_maps = EventMap.where('event_id=?',session[:event_id]).destroy_all

    respond_to do |format|
      format.html { redirect_to("/events/configure/#{session[:event_id]}", :notice => 'Mapping Coordinate data was successfully deleted.') }
    end
  end

  def deleteall_eventconfigdata

    Rails.cache.clear

    @event = Event.find(session[:event_id])

    #fill in code
    @notifications = Notification.where('event_id=?',session[:event_id]).destroy_all
    @home_button_groups = HomeButtonGroup.where('event_id=?',session[:event_id])
    @home_button_groups.each do |hbgroup|
      @home_button_entry = HomeButtonEntry.where('group_id=?',hbgroup.id).destroy_all
    end

    @home_button_groups.where('event_id=?',session[:event_id]).destroy_all

    @event_files = EventFile.where('event_id=? AND (event_file_types.name=? OR event_file_types.name=?)',session[:event_id],'home_button_icon','home_button_entry_icon').joins('
    LEFT OUTER JOIN event_file_types ON event_file_types.id=event_files.event_file_type_id').destroy_all

    respond_to do |format|
      format.html { redirect_to("/events/configure/#{session[:event_id]}", :notice => 'Event Configuration data was successfully deleted.') }
    end
  end

  def deleteall_attendeedata

    Rails.cache.clear

    @event = Event.find(session[:event_id])

    Attendee.where('event_id=?',session[:event_id]).find_each do |attendee|
      attendee.destroy
    end

    respond_to do |format|
      format.html { redirect_to("/events/configure/#{session[:event_id]}", :notice => 'Attendee data was successfully deleted.') }
    end
  end

  def refresh_custom_adjustment_script
    Rails.cache.clear
    Rails::logger.debug "refresh_custom_adjustment_script"
    @event = Event.find(session[:event_id])
    Rails::logger.debug "name: #{@event.name}"
    script = Script.find(params[:script_id])
    file_name = script.file_name
    Rails::logger.debug "file_name: #{file_name}"

    #specific to this method. Other file locations will need a new method
    script_path = "ek_scripts/custom-adjustment-scripts"
    
    if params[:job_id]
      script_path = Rails.root.join("#{script_path}/#{file_name} \"#{session[:event_id]}\" \"#{params[:job_id]}\"")
      Rails::logger.debug "Script path #{script_path}"
      pid = Process.spawn("ROO_TMP='/tmp' ruby #{script_path} 2>&1")
      Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
      Job.find(params[:job_id]).update!(pid:pid)
      Process.detach pid
      render :json => {status:true}
    else
      script_path = Rails.root.join("#{script_path}/#{file_name} \"#{session[:event_id]}\"")
      Rails::logger.debug "Script path #{script_path}"
      pid = Process.spawn("ROO_TMP='/tmp' ruby #{script_path} 2>&1")
      Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
      Process.detach pid
    
      respond_to do |format|
        format.html { redirect_to("/events/configure/#{session[:event_id]}", :notice => "#{script.button_label} was updated.")}
      end
    end
  end

  # def update_meta_tags
  #   meta_tags_script = 'add_meta_data_to_event_tags.rb'
  #   @result          = ''

  #   meta_script_cmd = Rails.root.join('ek_scripts/custom-adjustment-scripts',"#{meta_tags_script} \"#{session[:event_id]}\"")
  #   Rails::logger.debug "METATAGS CMD #{meta_script_cmd}"
  #   @import_session_result = `ROO_TMP='/tmp' ruby #{meta_script_cmd} 2>&1`
  #   Rails::logger.debug "\n--------- import script output ---------\n\n #{@result} \n------------------- \n"
  #   @result.gsub!(/\n/,"<br/>")

  #   respond_to do |format|
  #     format.html { redirect_to("/events/configure/#{session[:event_id]}") }
  #   end
  # end

  def update_track_subtrack
    track_subtrack_script = 'add_track_subtracks_to_sessions.rb'
    @result          = ''

    track_subtrack_script_cmd = Rails.root.join('ek_scripts/custom-adjustment-scripts',"#{track_subtrack_script} \"#{session[:event_id]}\"")
    Rails::logger.debug "METATAGS CMD #{track_subtrack_script_cmd}"
    @import_session_result = `ROO_TMP='/tmp' ruby #{track_subtrack_script_cmd} 2>&1`
    Rails::logger.debug "\n--------- import script output ---------\n\n #{@result} \n------------------- \n"
    @result.gsub!(/\n/,"<br/>")

    @event = Event.find(session[:event_id])

    respond_to do |format|
      format.html { redirect_to("/events/configure/#{session[:event_id]}") }
    end
  end

  def change_event
    # binding.pry
    if current_user.role?(:super_admin) || current_user.users_events.where(event_id:params[:event_id]).length > 0
      @event = Event.find(params[:event_id])
    else
      render :text => "You do not have access to this event."
      return
    end

    session[:event_id]   = @event.id
    session[:event_name] = @event.name

    #mark if the event has a speaker portal
    if eventHasPortal @event.id
      session[:event_has_portal]=true
    end
    if current_user.role? :super_admin
      # this actually breaks the regular login process, because select_event
      # will get redirected back to itself. Maybe I'll just leave this alone
      # if request.referrer.include?  "/events/configure/"
        # I believe this is the only url in the app which contains event_id, so
        # the only place this needs to accounted for
        # alternatively I could just cautiously scan the referrer for anything
        # including the event_id, even if it was only a coicidence
        redirect_to "/events/configure/#{params[:event_id]}"
      # else
      #   redirect_to :back
      # end
    elsif (current_user.role? :speaker) && params[:role] == "speaker"
      redirect_to "/speaker_portals/checklist"
    elsif (current_user.role? :exhibitor) && params[:role] == "exhibitor"
      redirect_to "/exhibitor_portals/landing"
    elsif current_user.role?(:track_owner) && params[:role] == "trackowner"
      redirect_to "/trackowner_portals/landing"
    elsif current_user.role?(:speaker) && params[:role] == "speaker"
      redirect_to "/speaker_portals/checklist"
    elsif current_user.role?(:attendee) && params[:role] == "attendee"
      attendee = Attendee.where(user_id: current_user.id, event_id: @event.id).first
      if attendee.present?
        redirect_to "/attendee_portals/landing/#{attendee.slug}"
      end
    elsif current_user.role?(:moderator) && params["role"] == "moderator"
      redirect_to "/moderator_portals/landing"
    elsif current_user.role?(:partner) && params[:role] == "partner"
      redirect_to "/partner_portals/landing"
    else # user is a client
      # don't use redirect to back... or a client could end up in places
      # they're not supposed to, with access to feature available to them in
      # other events that shouldn't be available to them in the event they're
      # changing to. Not really likely, but they don't need to switch events like we do
      redirect_to "/events/configure/#{params[:event_id]}"
    end

  end

  def show_gallery_photos
    @event = Event.find(session[:event_id])
    event_file_types = [EventFileType.where(name:"pg-camera").first.id,EventFileType.where(name:"pg-photobooth").first.id]
    @photos = EventFile.where(event_id:session[:event_id], event_file_type_id:event_file_types)

    respond_to do |format|
      format.html { render "show_gallery_photos", :layout => "subevent_2013" }# configure.html.erb
    end
  end

  def upload_gallery_photos
    @event = Event.find(session[:event_id])
    @event.uploadGalleryPhotos(params)
    message = ''

    params[:event_files].each do |file|
      message += "#{file.original_filename} "
    end

    respond_to do |format|
      unless @event.errors.full_messages.length > 0
        format.html { redirect_to("/events/show_gallery_photos", :notice => "#{message} successfully added.")}
      else
        format.html { redirect_to("/events/show_gallery_photos", :alert => "#{@event.errors.full_messages.each do |error|; error end}")}
      end
    end
  end

  def gallery_photos_json_data

    json_hash = JSON.parse("[]")
    pseudo_id = 0
    domain = Event.find(params[:event_id]).cms_url

    Dir["public/event_data/#{params[:event_id].to_s}/gallery_photos/*"].each do |file|

      file.slice!(0, 7)
      pseudo_id+=1
      json_hash << {"pseudo_id"=>"#{pseudo_id}",
      "photo_url"=>"#{domain}/#{file}",
      "thumbnail_url"=>"#{domain}/event_data/#{params[:event_id].to_s}/gallery_photo_thumbnails/#{File.basename(file,File.extname(file))}_small#{File.extname(file)}",
      "type"=>"#{File.extname(file)}",
      "time"=>"#{File.ctime('public/'+file).strftime('%H:%M')}",
      "date"=>"#{File.ctime('public/'+file).strftime('%Y-%m-%d')}",
      "album"=>"Booth Photo"}

    end

    # Dir["/home/deploy/BCBS_2015_PHOTO_GALLERY_UPLOADS/SORTED_APP_PHOTOS/*/"].each do |datedir|
    Dir["public/event_data/#{params[:event_id].to_s}/BCBS_2015_PHOTO_GALLERY_UPLOADS/SORTED_APP_PHOTOS/*/"].each do |datedir|
      # puts datedir
      Dir["#{datedir}*.jpg"].each do |file|
        file.slice!(0, 7)
        pseudo_id+=1
        json_hash << {"pseudo_id"=>"#{pseudo_id}",
        "photo_url"=>"#{domain}/#{file}",
        "thumbnail_url"=>"#{domain}/#{datedir.slice(7,200)}THUMBS/#{File.basename(file)}",
        "type"=>"#{File.extname(file)}",
        "time"=>"#{File.ctime('public/'+file).strftime('%H:%M')}",
        "date"=>"#{File.ctime('public/'+file).strftime('%Y-%m-%d')}",
        "album"=>"#{datedir.split("/").last}"}
      end
    end

    render :json => json_hash.to_json
  end

  def delete_abandoned_tags
    tag_count = Tag.where(event_id:session[:event_id]).pluck(:id).length
    RemoveUnusedTagsForEvent.new(session[:event_id]).call if session[:event_id].is_a? Numeric
    tag_count -= Tag.where(event_id:session[:event_id]).pluck(:id).length
    respond_to do |format|
      if params[:abandoned_tags_page]
        format.html { redirect_to("/tags/abandoned_tags", notice: "#{tag_count} tags removed.", layout: "dashboard") }
      else
        format.html { redirect_to("/dev", notice: "#{tag_count} tags removed.", layout: "subevent_2013") }
      end
    end
  end

  # BNS request to have this in a separate script
  # def populate_preselected_attendee_favourites
  #   Rails::logger.debug "begin attendees prepop favs"

  #   Rails.cache.clear

  #   @event = Event.find(session[:event_id])

  #   Rails::logger.debug "name: #{@event.name}"

  #   # could rename the script more generically; inside the script
  #   # there is a case statement based on event id to decide
  #   # what session codes to prepop with
  #   prepop_fav_cmd = Rails.root.join(
  #     'ek_scripts/custom-adjustment-scripts',
  #     "bcbs-prepopulate-attendee-favourites.rb \"#{@event.id}\" \"#{params[:job_id]}\""
  #   )

  #   Rails::logger.debug "PREPOP FAV CMD #{prepop_fav_cmd}"

  #   pid = Process.spawn("ROO_TMP='/tmp' ruby #{prepop_fav_cmd} 2>&1")

  #   Job.find(params[:job_id]).update!(pid:pid)

  #   Process.detach pid

  #   render json: {status: true}
  # end

  # def avma_regenerate_attendee_tags
  #   Rails::logger.debug "begin attendees avma regenerate tags"

  #   Rails.cache.clear

  #   @event = Event.find(session[:event_id])

  #   Rails::logger.debug "name: #{@event.name}"

  #   attendee_script = 'regenerate_avma_attendee_tags_2016.rb'

  #   attendee_import_cmd = Rails.root.join('ek_scripts/custom-adjustment-scripts',"#{attendee_script} \"#{params[:job_id]}\"")
  #   Rails::logger.debug "PREPOP FAV CMD #{attendee_import_cmd}"

  #   pid = Process.spawn("ROO_TMP='/tmp' ruby #{attendee_import_cmd} 2>&1")
  #   Job.find(params[:job_id]).update!(pid:pid)
  #   Process.detach pid
  #   render json: {status: true}
  # end

  def download_generated_certificates_as_zip
    generated_certificate_paths = Dir["./app/services/pdf_generators/event_#{session[:event_id]}/*"]
      .map {|f|
        f
          .sub("./app/services/pdf_generators/event_#{session[:event_id]}/generate_", "")
          .sub(".rb", "")
      }
      .map {|name|
        Dir["./public/event_data/#{session[:event_id]}/generated_pdfs/*"]
          .select {|f|
            f.downcase.gsub(/\s/, "_").match(name)
          }
      }
      .flatten
      .map {|path| Pathname.new path }


    # render :text => t.inspect
    destination = Rails.root.join(
      'public',
      'event_data',
      session[:event_id].to_s,
      'generated_pdfs',
      "#{Event.find(session[:event_id]).name.downcase.split(' ').join('_')}_generated_certificates.zip"
    )

    FileOperations.bundle_files destination, generated_certificate_paths

    def file_exists_and_user_privileged? destination, user
      File.exists?(destination) && user.role?(:superadmin) || user.role?(:client)
    end

    if generated_certificate_paths.length == 0
      render plain: 'No certificates have been generated for this event yet.'
    elsif file_exists_and_user_privileged? destination, current_user
      send_file destination, x_sendfile: true
    else
      raise ActionController::RoutingError, "File not available."
    end
  end

  def statistics
    @db = DatabaseStats.new session[:event_id]
    
    #For getting duck logins from reporting db
    reporting_db_config = Rails.root.join('config', 'reporting_database.yml')
    raise "Reporting database configuration not found" unless File.exist? reporting_db_config
    @reporting_db = Mysql2::Client.new( YAML.load(File.open(reporting_db_config))[Rails.env] )
    @video_portal_logins = @reporting_db.query(%{
      select count(reporting.logins.attendee_id) as total_logins, count(distinct(reporting.logins.attendee_id))
      as unique_logins from reporting.logins where reporting.logins.event_id = #{session[:event_id]}
    }).first
    @purchases = AttendeeProduct.includes(:attendee, :transactions).where(attendee: {event_id: session[:event_id]}).where('transactions.amount >= 0')
    render layout: 'dashboard'
  end

  def statistics_pdf
    respond_to do |format|
      pdf_url = StatsPdf.new(Event.find(session[:event_id])).call
      format.html { redirect_to(pdf_url) }
    end
  end

  def game_statistics
    @db = DatabaseStats.new session[:event_id]
    render layout: 'dashboard'
  end

  def report_downloads
    @jobs  = Job.where("event_id= ? AND updated_at >= ?", session[:event_id], Time.zone.now.beginning_of_day)
    @event = Event.find(session[:event_id])
    render layout: 'dashboard'
  end

  def download_sessions_async
    run_job_in_background(
      "ek_scripts/config_page_scripts/export-sessions-mysql2-matched.rb \"#{session[:event_id]}\" \"#{params[:job_id]}\"",
      params[:job_id]
    )
  end

  def download_sessions_full_async
    run_job_in_background(
      "ek_scripts/config_page_scripts/export-sessions-full-mysql2-matched.rb \"#{session[:event_id]}\" \"#{params[:job_id]}\"",
      params[:job_id]
    )
  end

  def sort_search_toggle_view
    view_type = params[:view_type].present? ? params[:view_type] : "grid_view"
    sort_type = params[:sort_type].present? ? params[:sort_type] : "desc"
    search_text = params[:search_text].present? ? params[:search_text] : ""
    @events = Event.search_event_by_search_param(search_text).order(event_start_at: sort_type)
    render partial: "events_#{view_type}", locals: {events: @events}
  end

  def attendee_checked_in
    @attendees = Attendee.joins(:attendee_badge_prints).where(event_id: session[:event_id]).uniq
    render layout: 'dashboard'
  end

  private

  def run_job_in_background cmd, job_id
    pid = Process.spawn("ROO_TMP='/tmp' ruby #{cmd} 2>&1")
    Job.find(job_id).update!(pid:pid)
    Process.detach pid
    render json: {:status => true, job_id: job_id}
  end

  # why do I have this.
  def eventHasPortal(event_id)

    event = Event.find(event_id)
    event.domains.length > 0

  end

  def event_params
    params.require(:event).permit(:org_id, :logo_event_file_id, :name, :description, :splash_screen, :background_color, :logo, :email_title, :email_body, :facebook_title, :facebook_body, :twitter_body, :event_start_at, :event_end_at, :address_line1, :address_line2, :city, :state, :zip, :longitude, :latitude, :url_web, :url_facebook, :url_twitter, :url_rss, :exhibitors, :enhanced_listings, :sponsorship, :iphone, :android, :mobile_site, :touchscreen, :soma_record, :notification_UA_AK, :notification_UA_AMS, :utc_offset, :master_url, :pn_filters, :type_to_pn_hash, :tag_sets_hash, :diy_status, :diy_login_ct, :diy_login_ct_allowed, :diy_fullscale, :multi_event_status, :hide_in_app, :diy_username, :diy_user_pass, :flare_enabled, :event_server, :api_key, :cloud_storage_type_id, :virtual_portal_url, :chat_url, :reporting_url, :cms_url, :mailer_name)
  end

  def convert_ids_string_to_array
    params[:user_ids] = params[:user_ids].split(" ")
  end

  # for removing the element from nested array 
  def deep_remove!(text, array)
    array.delete_if do |value|
      case value
      when String
        value.include? text
      when Array
        deep_remove!(text, value)
        false
      else
        false
      end
    end
  end

end