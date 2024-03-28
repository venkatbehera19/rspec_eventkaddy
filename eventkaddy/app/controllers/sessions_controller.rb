class SessionsController < ApplicationController
  layout :set_layout
  load_and_authorize_resource

  def bulk_add_session_thumbnails
    @event = Event.find session[:event_id]
  end

  def bulk_create_session_thumbnails
    @event = Event.find session[:event_id]
    BulkUploadEventFileImage.new(
      event:              @event,
      event_file_type_id: EventFileType.where(name:'session_thumbnail')[0].id,
      files:              params[:event_files],
      owner_class:        Session,
      owner_assoc:        :thumbnail_event_file_id,
      owner_identifier:   :session_code,
      target_path:        Rails.root.join('public', 'event_data', @event.id.to_s, 'session_thumbnails'),
      rename_image:       false,
      new_height:         320,
      new_width:          320
    ).call

    respond_to do |format|
      unless @event.errors.full_messages.length > 0
        format.html {
          redirect_to("/sessions/bulk_add_session_thumbnails",
                      :notice => "#{params[:event_files].inject('') {|m, f| m += "#{f.original_filename} "}} successfully added.")}
      else
        format.html {
          redirect_to("/sessions/bulk_add_session_thumbnails",
                      :alert => "#{@event.errors.full_messages.inject('') {|m, e| m += "#{e} "}}")}
      end
    end

  end

  def mobile_data

    @empty_data = "[]"

    if (params[:event_id] && params[:record_start_id])

      Rails.cache.fetch "sessions-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}" do
        @sessions = Session.select('sessions.*,DATE_FORMAT(start_at,\'%H-%i\') AS start_at_formatted,DATE_FORMAT(start_at,\'%l:%i %p\') AS start_at_12h,DATE_FORMAT(end_at,\'%l:%i %p\') AS end_at_12h, DATE_FORMAT(end_at,\'%H-%i\') AS end_at_formatted,DATE_FORMAT(date,\'%W, %M %e\') AS date_formatted, location_mappings.name as location_name, location_mappings.x AS location_x, location_mappings.y AS location_y, location_mappings.map_id AS map_id,speakers.honor_prefix,speakers.honor_suffix,speakers.first_name,speakers.last_name,speakers.title, speakers.company AS speaker_company, sessions_speakers.id as ssid').joins('
    LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id
    LEFT OUTER JOIN sessions_speakers ON sessions_speakers.session_id=sessions.id
     LEFT OUTER JOIN speakers ON sessions_speakers.speaker_id=speakers.id
    ').where("sessions.event_id= ? AND sessions_speakers.id > ?",params[:event_id],params[:record_start_id]).order('ssid ASC').limit(100).to_json

      end

      @sessions = Rails.cache.read "sessions-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}"

      if (JSON.parse(@sessions).length > 0)
        Rails::logger.debug "sessions records returned"
        render :json => @sessions, :callback => params[:callback]
      else
        Rails::logger.debug "sessions empty"
        render :json => @empty_data, :callback => params[:callback]
      end

    end

  end


  def mobile_data_sessions_only

    @empty_data = "[]"

    if (params[:event_id] && params[:record_start_id])

      Rails.cache.fetch "sessions-only-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}" do

        @sessions = Session.select('sessions.*,DATE_FORMAT(start_at,\'%H-%i\') AS start_at_formatted,DATE_FORMAT(start_at,\'%l:%i %p\') AS start_at_12h,DATE_FORMAT(end_at,\'%l:%i %p\') AS end_at_12h, DATE_FORMAT(end_at,\'%H-%i\') AS end_at_formatted,DATE_FORMAT(date,\'%W, %M %e\') AS date_formatted, location_mappings.name as location_name, location_mappings.x AS location_x, location_mappings.y AS location_y, location_mappings.map_id AS map_id').joins('
    LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id
    ').where("sessions.event_id= ? AND sessions.id > ?",params[:event_id],params[:record_start_id]).order('sessions.id ASC').limit(100).to_json

      end

      @sessions = Rails.cache.read "sessions-only-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}"

      if (JSON.parse(@sessions).length > 0)
        Rails::logger.debug "sessions records returned"
        render :json => @sessions, :callback => params[:callback]
      else
        Rails::logger.debug "sessions empty"
        render :json => @empty_data, :callback => params[:callback]
      end

    end

  end


  def mobile_data_session_leaf_tags

    @empty_data = "[]"

    if (params[:event_id] && params[:record_start_id])

      Rails.cache.fetch "session-leaf-tags-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}" do

        @tags = Tag.select('tags.*,tag_types.name AS type_name,sessions.id AS session_id,tags_sessions.id AS tsid').joins('
        JOIN tag_types ON tags.tag_type_id=tag_types.id
        LEFT OUTER JOIN tags_sessions ON tags.id=tags_sessions.tag_id
        LEFT OUTER JOIN sessions ON tags_sessions.session_id=sessions.id
      ').where("tag_types.name= ? AND tags.event_id= ? AND tags_sessions.id > ?",'session',params[:event_id],params[:record_start_id]).order('tags_sessions.id ASC').limit(100).to_json

      end

      @tags = Rails.cache.read "session-leaf-tags-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}"


      if (JSON.parse(@tags).length > 0)
        Rails::logger.debug "tags sessions records returned"
        render :json => @tags, :callback => params[:callback]
      else
        Rails::logger.debug "tags sessions empty"
        render :json => @empty_data, :callback => params[:callback]
      end

    end

  end

  def mobile_data_session_nonleaf_tags

    @empty_data = "[]"

    if (params[:event_id] && params[:record_start_id])

      Rails.cache.fetch "session-nonleaf-tags-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}" do

        @tags = Tag.select('tags.*, tag_types.name AS type_name').joins('
        JOIN tag_types ON tags.tag_type_id=tag_types.id
        ').where("tags.event_id= ? AND tags.leaf=? AND tag_types.name= ? AND tags.id > ?",params[:event_id],'0','session',params[:record_start_id]).order('tags.id ASC').limit(100).to_json

      end

      @tags = Rails.cache.read "session-nonleaf-tags-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}"

      if (JSON.parse(@tags).length > 0)
        Rails::logger.debug "tags sessions records returned"
        render :json => @tags, :callback => params[:callback]
      else
        Rails::logger.debug "tags sessions empty"
        render :json => @empty_data, :callback => params[:callback]
      end

    end

  end


  def mobile_data_session_sponsors

    @empty_data = "[]"

    if (params[:event_id] && params[:record_start_id])
      @sponsors = Exhibitor.select('exhibitors.company_name AS company_name, exhibitors.id AS sponsor_id, sessions_sponsors.session_id AS session_id, sessions_sponsors.id AS ssid').joins('
      JOIN sessions_sponsors ON sessions_sponsors.sponsor_id=exhibitors.id')
      .where("exhibitors.event_id= ? AND sessions_sponsors.id > ?",params[:event_id],params[:record_start_id]).order('ssid ASC').limit(100)

      if (@sponsors.length > 0)
        Rails::logger.debug "session sponsor records returned"
        render :json => @sponsors.to_json, :callback => params[:callback]
      else
        Rails::logger.debug "session sponsors empty"
        render :json => @empty_data, :callback => params[:callback]
      end

    end

  end

  #unused?
  def mobile_data_count

  if (params[:event_id])
    @sessions = Session.select('COUNT(sessions.id) AS record_count').where("sessions.event_id= ?",params[:event_id])

    render :json => @sessions.to_json, :callback => params[:callback]

  end

  end

  def index
    #@sessions = Session.all
    if (session[:event_id])

      @event_id = session[:event_id]
      @current_user = current_user
      @event_setting = EventSetting.where(event_id:@event_id).first

      #disabled while using server-side fetch for datatables
      #@sessions = Session.select("DISTINCT sessions.*,location_mappings.name, CONCAT_WS(' ', DATE_FORMAT(sessions.date, '%Y-%m-%d'),' | ',DATE_FORMAT(sessions.start_at, '%H:%i')) AS session_date").joins('LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id').where("sessions.event_id= ?",session[:event_id]).order('session_code ASC')

        respond_to do |format|
          format.html # index.html.erb
          format.xml  { render :xml => @sessions }
          #format.json { render :json => @sessions.to_json, :callback => params[:callback] }
          format.json { render json: SessionsDatatable.new(view_context,@event_id,@current_user) }
        end

    else
      redirect_to "/home/session_error"
    end

  end


  def show
    @session = Session.find(params[:id])

    @links = Link.where('links.session_id = ?',@session.id)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @session }
      format.json { render :json => @session.to_json, :callback => params[:callback] }
    end
  end

  def new
    @session = Session.new

    #setup speakers list
    @speakers = Speaker.select('DISTINCT(speakers.id),first_name,last_name,honor_prefix').where("event_id= ?",session[:event_id]).order('last_name ASC')

    #setup location_mappings list
    @room_mapping_type = LocationMappingType.where(type_name:'Room').first.id
    @location_mappings = LocationMapping.where("location_mappings.mapping_type= ? AND event_id=?",@room_mapping_type,session[:event_id]).order('location_mappings.name ASC')

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @session }
    end
  end

  def edit
    @session = Session.find params[:id]

    #setup speakers list
    @speakers = Speaker
      .select('DISTINCT(speakers.id), first_name, last_name, honor_prefix')
      .where(event_id:session[:event_id])
      .order('last_name ASC')

    #previously selected speakers
    @session_speakers = SessionsSpeaker.where("session_id = ?", params[:id])
    @speaker_list=[]
    @session_speakers.each do |session_speaker|
      @speaker_list << session_speaker.speaker_id
    end

    #setup location_mappings list
    @room_mapping_type = LocationMappingType.where(type_name:'Room').first.id
    @location_mappings = LocationMapping.where("location_mappings.mapping_type= ? AND event_id=?",@room_mapping_type,session[:event_id]).order('location_mappings.name ASC')

  end

  def create
    params[:session][:event_id] = session[:event_id]

    @session = Session.new session_params
    respond_to do |format|
      if @session.save!

        params
          .fetch(:speaker_ids, [])
          .each {|speaker_id| SessionsSpeaker.where(session_id: @session.id, speaker_id: speaker_id).first_or_create }

        @session.update_thumbnail(params[:thumbnail_file]) if params[:thumbnail_file]

        format.html {
          redirect_to(
            event_session_path(@session),
            :notice => 'Session was successfully created.'
          ) 
        }

        format.xml  {
          render(
            :xml      => @session,
            :status   => :created,
            :location => @session
          )
        }
      else

        format.html {
          render :action => "new" 
        }

        format.xml  {
          render :xml => @session.errors,
          :status     => :unprocessable_entity
        }

      end
    end
  end

  def update
    @session = Session.find(params[:id])

    respond_to do |format|
        params
          .fetch(:speaker_ids, [])
          .each {|speaker_id| SessionsSpeaker.where(session_id: @session.id, speaker_id: speaker_id).first_or_create }

      if @session.update!(session_params)
        @session.update_thumbnail(params[:thumbnail_file]) if params[:thumbnail_file]
        @session.tags.each {|t| t.add_session_meta_tag_data } if Event.find(session[:event_id]).session_date_loc_meta_tags?

        format.html { redirect_to(event_session_path(@session), :notice => 'Session was successfully updated.') }
        format.xml  { head :ok }
      else
        # format.html { render :action => "edit" }
        format.html { redirect_to("/sessions/#{params[:id]}/edit", :alert => "#{@session.errors.full_messages[0]}")}
        # format.xml  { render :xml => @session.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @session = Session.find(params[:id])
    @session.destroy

    respond_to do |format|
      format.html { redirect_to(event_sessions_url) }
      format.xml  { head :ok }
    end
  end

  def session_speakers

    @session = Session.find(params[:id])
    @speakers = Speaker.select('DISTINCT(speakers.id),first_name,last_name,honor_prefix').where("event_id= ?",session[:event_id]).order('last_name ASC')
    @speaker_types = SpeakerType.all
    @sessions_speaker = SessionsSpeaker.new

    ## this is incorrectly named; it makes you think you're getting sessions_speakers records, and you are not.
    @session_speakers = Speaker.select('speakers.*,sessions.id AS session_id,
      sessions.session_code,speaker_types.speaker_type AS speaker_type_name').joins(

      'JOIN sessions_speakers ON sessions_speakers.speaker_id=speakers.id
       JOIN sessions ON sessions_speakers.session_id=sessions.id
       LEFT JOIN speaker_types ON sessions_speakers.speaker_type_id=speaker_types.id').where(
       'sessions.event_id=? AND sessions.id=?',session[:event_id],params[:id])


    respond_to do |format|
        format.html {  render action:"session_speakers"  } # index.html.erb
    end

  end

  def add_session_speaker

    if (SessionsSpeaker.where(sessions_speaker_params).length==0)
        @sessions_speaker = SessionsSpeaker.new(sessions_speaker_params)
    else
      @sessions_speaker = nil
    end

    respond_to do |format|

      if (@sessions_speaker!=nil && @sessions_speaker.save())
        format.html { redirect_to("/sessions/#{@sessions_speaker.session_id}/session_speakers/", :notice => 'Speaker was successfully added to session.') }
      else
        format.html { redirect_to("/sessions/#{params[:sessions_speaker][:session_id]}/session_speakers/", :notice => 'Speaker could not be added to session.') }
      end
    end

  end

  def remove_session_speaker

    session_id=params[:id]
    speaker_id=params[:speaker_id]
    @session_speaker = SessionsSpeaker.where(session_id:session_id,speaker_id:speaker_id)

    respond_to do |format|

      if ( @session_speaker.destroy_all )
        format.html { redirect_to("/sessions/#{session_id}/session_speakers/", :notice => 'Speaker was successfully removed from session.') }
      else
        format.html { redirect_to("/sessions/#{session_id}/session_speakers/", :notice => 'Speaker could not be removed from session.') }
      end
    end

  end

  def session_sponsors

    @session = Session.find(params[:id])
#     @sponsors = Exhibitor.select('DISTINCT(exhibitors.id),company_name').where("event_id= ? AND is_sponsor=?",session[:event_id],1).order('company_name ASC')
    @sponsors = Exhibitor.select('DISTINCT(exhibitors.id),company_name').where("event_id= ?",session[:event_id]).order('company_name ASC')
    @sessions_sponsor = SessionsSponsor.new

    @session_sponsors = Exhibitor.select('exhibitors.company_name,exhibitors.id AS exhibitor_id,sessions.id AS session_id').joins(

      'JOIN sessions_sponsors ON sessions_sponsors.sponsor_id=exhibitors.id
       JOIN sessions ON sessions_sponsors.session_id=sessions.id').where(
       'exhibitors.event_id=? AND sessions.id=?',session[:event_id],@session.id)


    respond_to do |format|
        format.html {  render action:"session_sponsors"  } # index.html.erb
    end

  end

  def add_session_sponsor

    if (SessionsSponsor.where(sessions_sponsor_params).length==0)
        @sessions_sponsor = SessionsSponsor.new(sessions_sponsor_params)
    else
      @sessions_sponsor = nil
    end

    respond_to do |format|

      if (@sessions_sponsor!=nil && @sessions_sponsor.save())
        format.html { redirect_to("/sessions/#{@sessions_sponsor.session_id}/session_sponsors/", :notice => 'Sponsor was successfully added to session.') }
      else
        format.html { redirect_to("/sessions/#{params[:sessions_sponsor][:session_id]}/session_sponsors/", :notice => 'Sponsor could not be added to session.') }
      end
    end

  end

  def remove_session_sponsor

    session_id=params[:id]
    sponsor_id=params[:sponsor_id]
    @session_sponsor = SessionsSponsor.where(session_id:session_id,sponsor_id:sponsor_id)

    respond_to do |format|

      if ( @session_sponsor.destroy_all )
        format.html { redirect_to("/sessions/#{session_id}/session_sponsors/", :notice => 'Sponsor was successfully removed from session.') }
      else
        format.html { redirect_to("/sessions/#{session_id}/session_sponsors/", :notice => 'Sponsor could not be removed from session.') }
      end
    end

  end

  def session_tags
    @session = Session.find(params[:id])
    @tagType = TagType.where(name:params[:tag_type_name])[0]

    @tags_session = TagsSession
      .select('session_id, tag_id, tags.parent_id AS tag_parent_id, tags.name AS tag_name')
      .joins(' JOIN tags ON tags_sessions.tag_id=tags.id')
      .where('session_id=? AND tags.tag_type_id=?', @session.id, @tagType.id)

    @tag_groups = []
    @tags_session.each_with_index do |tag_session, i|

      @tag_groups[i] = []

      #add leaf tag
      @tag_groups[i] << tag_session.tag_name
      parent_id = tag_session.tag_parent_id #acquired from above table join

      #add ancestor tags, if any
      while (parent_id!=0)
        tag = Tag.where(event_id:session[:event_id],id:parent_id)
        if (tag.length==1)
          @tag_groups[i] << tag[0].name
          parent_id = tag[0].parent_id
        else
          parent_id=0
        end
      end

      @tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root

      #add blank entries for each set
      @tag_groups[i] << '' << '' << ''
    end

    #add blank tag groups on the end
    for i in @tag_groups.length..(@tag_groups.length+4)
      @tag_groups[i] = []
      for j in 0..4
        @tag_groups[i] << ''
      end
    end

    respond_to do |format|
      format.html { render action:"session_tags" }
    end
  end

  def update_session_tags
    @session      = Session.find params[:id]
    tag_type_id   = params[:tag_type_id]
    tag_type_name = TagType.find(params[:tag_type_id]).name
    tag_groups    = Tag.assemble_tag_array params

    respond_to do |format|
      if @session.update_tags tag_groups, tag_type_name
        format.html { redirect_to("/sessions/#{@session.id}/#{tag_type_name}/session_tags/", :notice => "#{tag_type_name.capitalize} tags successfully updated.") }
      else
        format.html { redirect_to("/sessions/#{@session.id}/#{tag_type_name}/session_tags/", :notice => "#{tag_type_name.capitalize} tags could not be updated.") }
      end
    end
  end

  def tags_autocomplete
    if params[:term]
      @tags = Tag.where('name LIKE ? AND event_id=?', "%#{params[:term]}%",session[:event_id])
    else
      @tags = Tag.where(event_id:session[:event_id])
    end
    respond_to do |format|
      format.json { render :json => @tags.to_json }
    end
  end

  def select_pdf_date
    if (session[:event_id])
      @event_id = session[:event_id]
      @dates = Session.where(event_id:@event_id).order(:date).pluck(:date).uniq
    else
      redirect_to "/home/session_error"
    end
  end

  def list_pdfs
    if (session[:event_id])
      @event_id = session[:event_id]
      date = params[:date]
      region = params[:region]
      @event_server = Event.find(@event_id).event_server
      if region != nil
        @sessions = Session.where(event_id:@event_id,custom_fields:region).order(:start_at)
      elsif date != nil 
        @sessions = Session.where(event_id:@event_id,date:date).order(:start_at)
      else
        @sessions = Session.where(event_id:@event_id).order(:start_at)
      end
    else
      redirect_to "/home/session_error"
    end
  end

  def bulk_update_publish_pdf_field
    @sessions = Session.update(params[:sessions].keys, params[:sessions].values)
    if @sessions.empty?
      flash[:notice] = "Error updating sessions"
    else
      flash[:notice] = "Updating sessions"
    end
    redirect_back fallback_location: root_path
  end

  private

  def set_layout
    if current_user.role? :trackowner
      session[:layout]
    elsif current_user.role? :speaker
      'speakerportal_2013'
    else
      'subevent_2013'
    end
  end

  def session_params
    params.require(:session).permit(:event_id, :on_demand, :unpublished, :session_code, :poster_number, :session_cancelled, :title, :description, :location_mapping_id, :tag_twitter, :date, :start_at, :end_at, :timezone_offset, :published, :favourite_locked, :record_type, :embedded_video_url, :video_iphone, :video_ipad, :video_android, :video_thumbnail, :thumbnail_event_file_id, :video_duration, :price, :capacity, :credit_hours, :race_approved, :program_type_id, :ticketed, :wvctv, :track_subtrack, :session_file_urls, :publish_pdf, :admin_pdf_blocked, :survey_url, :learning_objective, :poll_url, :custom_fields, :tags_safeguard, :custom_filter_1, :custom_filter_2, :custom_filter_3, :feedback_enabled, :qa_enabled, :promotion, :keyword, :sold_out, :is_poster, :custom_fields_2, :sanitized_title, :speaker_names, :cloud_storage_type_id, :video_file_location, :subtitle_file_location, :premium_access, :publish_video, :short_title, :admin_video_blocked, :chat_enabled, :encoded_videos)
  end

  def sessions_sponsor_params
    params.require(:sessions_sponsor).permit(:session_id, :sponsor_id) 
  end

  def sessions_speaker_params
    params.require(:sessions_speaker).permit(:session_id, :speaker_id, :unpublished, :is_moderator, :speaker_type_id)
  end

end