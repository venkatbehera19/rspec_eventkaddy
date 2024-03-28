class SpeakerPortalsController < ApplicationController
layout :set_layout

# nice for booting non-logged in user to homepage, but store_url feature causes problems with other requirements (event_id)
# before_action :authenticate_user!

before_action :set_layout_variables

  def new 
    @session = Session.new
    speaker = Speaker.where(user_id: current_user.id).first;
    @event = Event.find speaker.event_id
    @speaker_portal_settings = Setting.return_speaker_portal_settings(@event.id)
    @tag_type = TagType.where(name: "session").first
    @tag_type_session_keyword = TagType.where(name: "session-keywords").first
    @keywords = @event.tag_sets_hash ? 
                @event.tag_sets_hash[@tag_type_session_keyword.id.to_s] ? @event.tag_sets_hash[@tag_type_session_keyword.id.to_s]&.flatten : [] : []
  end

  def create
    title           = params[:session][:title]
    description     = params[:session][:description]
    program_type_id = params[:session][:program_type_id]
    tag_type        = params[:session][:tag_type]
    session_tags    = params[:session][:session_tag]
    learning_objective = params[:session][:learning_objective]
    tag_type        = params[:session][:tag_type]
    event_id        = params[:session][:event_id]
    other_session_tags = params[:session][:other_session_tag]
    session_keywords = params[:session][:session_keyword]
    other_keyword_tags = params[:session][:other_keyword_tag]
    speaker_portal_settings = Setting.return_speaker_portal_settings(event_id)
    # creating the uniq session code
    program_type = ProgramType.where(id: program_type_id).first.name.split(' ').join('_')
    last_session = Session.where("session_code LIKE '%#{program_type}%' ").last

    user = current_user.id
    speaker_id = Speaker.find_by(user_id: user).id
    session_count = SessionsSpeaker.where(speaker_id: speaker_id).count
    
    if session_count+1 > speaker_portal_settings&.total_session.to_i
      redirect_to "/speaker_portals/sessions", :alert => "You have reached the maximum number of Abstracts you can create." and return
    end
    
    if last_session.blank?
      session_code = program_type.upcase.split(" ").join("_") + "S" + 1.to_s
    else
      last_session_number = last_session.session_code.scan(/\d+/).first.to_i + 1
      session_code = program_type.upcase.split(" ").join("_") + "S" + last_session_number.to_s
    end
    
    session = Session.create(
      event_id: event_id,
      session_code: session_code,
      title: title,
      description: description,
      published: false,
      learning_objective: learning_objective,
      program_type_id: program_type_id.to_i
    )
    speaker_type_id = SpeakerType.where(speaker_type: 'Primary Presenter').first.id

    # creating session speakers

    session_speaker = SessionsSpeaker.create(
      session_id:      session.id,
      speaker_id:      speaker_id,
      speaker_type_id: speaker_type_id
    )

    # creating session tags
    session_tags.each do |session_tag|
      if session_tag.present?
        tag = Tag.where(event_id: event_id, level: 1, leaf: true, parent_id: 0, name: session_tag).first
        if tag.present?
          tag.tags_session.create(tag_id: tag.id, session_id: session.id)
        else
          tag = Tag.create(
            name: session_tag, 
            level: 1, 
            leaf: true, 
            event_id: event_id, 
            parent_id: 0, 
            tag_type_id: tag_type )
          tag.tags_session.create(tag_id: tag.id, session_id: session.id)
        end
      end
    end

    if other_session_tags && !other_session_tags.empty?
      other_session_tags.split("||").each do |other_session_tag|
        tag = Tag.create(
          name: other_session_tag, 
          level: 1, 
          leaf: true, 
          event_id: event_id, 
          parent_id: 0, 
          tag_type_id: tag_type 
        )
        tag.tags_session.create(tag_id: tag.id, session_id: session.id, other_tag: true)
      end
    end
    
    key_words = ""
    session_keywords.each do |session_keyword| 
      if session_keyword.present?
        key_words = key_words + session_keyword + ","
        SessionKeyword.create(
          session_id: session.id,
          speaker_id: speaker_id,
          event_id: event_id,
          name: session_keyword
        )
      end
    end
    
    if other_keyword_tags && !other_keyword_tags.empty?
      other_keyword_tags.split("||").each do |other_keyword_tag|
        key_words = key_words + other_keyword_tag + ","
        SessionKeyword.create(
          session_id: session.id,
          speaker_id: speaker_id,
          event_id: event_id,
          name: other_keyword_tag,
          other_keyword: true
        )
      end
    end
    
    session.keyword = key_words.split(",").join(",")
    session.save

    fields = speaker_portal_settings.json["fields"]

    if params[:user]
      fields.each do |field|
        field["value"] = params[:user][field["name"]]
        
        if field['type'] == "radio-group"
          field['values'].each do |radio_field|
            if radio_field["value"] == params[:user][field["name"]]
              radio_field["selected"] = true
            else
              radio_field["selected"] = false
            end
          end
        end
  
        if field['type'] == "checkbox-group"
          if params[:user][field['name']]
            field['values'].each do |check_field|
              if params[:user][field['name']].include?(check_field["value"])
                check_field["selected"] = true
              else
                check_field["selected"] = false
              end
            end
          end
        end
      end
    end
    
    if fields
      session.update_column(:fields, JSON.generate(fields))
    else
      session.update_column(:fields, JSON.generate([]))
    end
    
    redirect_to "/speaker_portals/sessions"
  end

  def edit
    session_id = params[:id]
    @session = Session.where(id: params[:id]).first
    @event = Event.find @session.event_id
    @speaker_portal_settings = Setting.return_speaker_portal_settings(@event.id)
    @tag_type = TagType.where(name: "session").first
    @tag_type_session_keyword = TagType.where(name: "session-keywords").first
    @keywords = @event.tag_sets_hash ? 
                @event.tag_sets_hash[@tag_type_session_keyword.id.to_s] ? 
                @event.tag_sets_hash[@tag_type_session_keyword.id.to_s]&.flatten : [] : []
    @session_tags = Tag.joins(:tags_session).where(tags_sessions: { session: @session, other_tag: false})
    @other_session_tags = Tag.joins(:tags_session).where(tags_sessions: { session: @session, other_tag: true})
    @session_keywords = SessionKeyword.where(event_id: @event.id, session_id: @session.id, other_keyword: false)
    @session_other_keywords = SessionKeyword.where(event_id: @event.id, session_id: @session.id, other_keyword: true)
    begin
      @session_fields = JSON.parse @session.fields
    rescue => exception
      puts exception
    end
  end

  def update
    session            = Session.where(id: params[:id]).first
    event_id           = params[:session][:event_id]
    title              = params[:session][:title]
    description        = params[:session][:description]
    program_type_id    = params[:session][:program_type_id]
    tag_type           = params[:session][:tag_type]
    learning_objective = params[:session][:learning_objective]
    session_tags    = params[:session][:session_tag]
    other_session_tags = params[:session][:other_session_tag]
    session_keywords = params[:session][:session_keyword]
    other_keyword_tags = params[:session][:other_keyword_tag]
    all_session_keyword = SessionKeyword.where(event_id: event_id, session_id: session.id)
    speaker_portal_settings = Setting.return_speaker_portal_settings(event_id)
    speaker = Speaker.find_by(user_id: current_user.id)

    session.tags_sessions.delete_all
    all_session_keyword.delete_all

    session_tags&.each do |session_tag|
      if session_tag.present?
        tag = Tag.where(event_id: event_id, level: 1, leaf: true, parent_id: 0, name: session_tag).first
        if tag.present?
          tag.tags_session.create(tag_id: tag.id, session_id: session.id)
        else
          tag = Tag.create(
            name: session_tag, 
            level: 1, 
            leaf: true, 
            event_id: event_id, 
            parent_id: 0, 
            tag_type_id: tag_type )
          tag.tags_session.create(tag_id: tag.id, session_id: session.id)
        end
      end
    end

    if other_session_tags && !other_session_tags.empty?
      other_session_tags.split("||").each do |other_session_tag|
        tag = Tag.create(
          name: other_session_tag, 
          level: 1, 
          leaf: true, 
          event_id: event_id, 
          parent_id: 0, 
          tag_type_id: tag_type 
        )
        tag.tags_session.create(tag_id: tag.id, session_id: session.id, other_tag: true)
      end
    end
    key_words = ""
    session_keywords&.each do |session_keyword| 
      key_words = key_words + session_keyword + ","
      if session_keyword.present?
        SessionKeyword.create(
          session_id: session.id,
          event_id: event_id,
          name: session_keyword,
          speaker_id: speaker.id
        )
      end
    end
    
    if other_keyword_tags && !other_keyword_tags.empty?
      other_keyword_tags.split("||").each do |other_keyword_tag|
        key_words = key_words + other_keyword_tag + ","
        SessionKeyword.create(
          session_id: session.id,
          event_id: event_id,
          name: other_keyword_tag,
          other_keyword: true,
          speaker_id: speaker.id
        )
      end
    end
    
    if session.program_type_id != program_type_id.to_i
      program_type = ProgramType.where(id: program_type_id).first.name.split(' ').join('_')
      last_session = Session.where("session_code LIKE '%#{program_type}%' ").order('id asc').last

      last_session_counter = 0
      
      last_session.present? && 
        last_session_counter = last_session.session_code.split('S').last 
                                
      current_session_counter = last_session_counter.to_i + 1
      session_code = program_type.upcase.split(" ").join("_") + "S" + current_session_counter.to_s
      session.session_code = session_code
    end

    session.event_id = event_id
    session.title = title
    session.description = description
    session.learning_objective = learning_objective
    session.program_type_id = program_type_id.to_i
    session.keyword = key_words.split(",").join(",")
    session.save
    if !session.fields.nil?
      fields = JSON.parse session.fields
          
      if params[:user]
        fields&.each do |field|
          field["value"] = params[:user][field["name"]]
          
          if field['type'] == "radio-group"
            field['values'].each do |radio_field|
              if radio_field["value"] == params[:user][field["name"]]
                radio_field["selected"] = true
              else
                radio_field["selected"] = false
              end
            end
          end
          
          if field['type'] == "checkbox-group"
            if params[:user][field['name']]
              field['values'].each do |check_field|
                if params[:user][field['name']].include?(check_field["value"])
                  check_field["selected"] = true
                else
                  check_field["selected"] = false
                end
              end
            end
          end
        end
      else
        fields&.each do |field|
          if field['type'] == "checkbox-group"
            if !params[:user].present?
              field['values'].each do |check_field|
                check_field["selected"] = false
              end
            end
          end
        end
      end
      session.update_column(:fields, JSON.generate(fields))
    end
    
    redirect_to "/speaker_portals/sessions", :notice => "Session Update Succesfully"
  end

  def show
    session_id = params[:id]
    @session = Session.where(id: params[:id]).first
    @event = Event.find @session.event_id
    @speaker_portal_settings = Setting.return_speaker_portal_settings(@event.id)
    @tag_type = TagType.where(name: "session").first
    @tag_type_session_keyword = TagType.where(name: "session-keywords").first
    @keywords = @event.tag_sets_hash ? 
                @event.tag_sets_hash[@tag_type_session_keyword.id.to_s] ? 
                @event.tag_sets_hash[@tag_type_session_keyword.id.to_s]&.flatten : [] : []
    @session_tags = Tag.joins(:tags_session).where(tags_sessions: { session: @session, other_tag: false})
    @other_session_tags = Tag.joins(:tags_session).where(tags_sessions: { session: @session, other_tag: true})
    @session_keywords = SessionKeyword.where(event_id: @event.id, session_id: @session.id, other_keyword: false)
    @session_other_keywords = SessionKeyword.where(event_id: @event.id, session_id: @session.id, other_keyword: true)
    begin
      @session_fields = JSON.parse @session.fields
    rescue => exception
      puts exception
    end
  end

  def download
    fileid       = params[:file_id]
    speaker_file = SpeakerFile.find(fileid)
    filename     = speaker_file.event_file.name
    path         = Rails.root.join( 'download','event_data',session[:event_id].to_s,'speaker_files', filename )
    speaker      = get_speaker

    if current_user.role? :trackowner
      trackowner = get_trackowner

      if File.exists?(path) && (trackowner.speaker_files.where(id:fileid).length > 0)
        send_file( path, x_sendfile: true )
      else
        render :text => "<center><h2>File not available.</h2></center>"
      end
    elsif ((current_user.role? :superadmin) && File.exists?(path) || (current_user.role? :client) && File.exists?(path)) || File.exists?(path) && (speaker.speaker_files.where(id:fileid).length > 0)
      send_file( path, x_sendfile: true )
    else
      render :text => "<center><h2>File not available.</h2></center>"
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

      @tabs = Tab.where(event_id:session[:event_id],tab_type_id:@tab_type_ids).order(:order)
    end
  end

  def home

  end

  def faq
    @current_tab = get_current_tab("FAQ")

  end

  def checklist

    @user            = User.find(current_user.id)
    @event_setting   = EventSetting.where("event_id= ?",session[:event_id]).first
    @current_tab     = get_current_tab("Welcome")
    session[:layout] = 'speakerportal_2013'

  end

  #GET, display contact info
  def show_contactinfo
  	@speaker = get_speaker
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

    @current_tab = get_current_tab("Contact Details")

  end

  #PUT, update contact info
  def update_contactinfo
  	@speaker = get_speaker
	  #update (potentially uploaded) photo,cv,financial disclosure
    @speaker.updatePhoto(params)
    @speaker.updateCV(params)
    @speaker.updateFD(params)
    params[:speaker][:photo_filename] = params[:online_url] == '1' ? @speaker.online_url : nil

    respond_to do |format|
      if @speaker.update!(speaker_update_params)

        format.html { redirect_to("/speaker_portals/show_contactinfo", :notice => 'Speaker was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { redirect_to("/speaker_portals/show_contactinfo", :notice => 'Update error.') }
        format.xml  { render :xml => @speaker.errors, :status => :unprocessable_entity }
      end
    end


  end

  #GET, display payment details
  def show_payment_detail
    @speaker = get_speaker
    @speaker_payment_detail = SpeakerPaymentDetail.where(speaker_id:@speaker.id)

    @current_tab = get_current_tab("Payment Details")

    if (@speaker_payment_detail.length==0) then
      @speaker_payment_detail = nil #SpeakerPaymentDetail.new
    else
      @speaker_payment_detail = @speaker_payment_detail.first
    end

  end

  #PUT, update contact info
  def update_payment_detail

    @speaker = get_speaker
    if (@speaker.speaker_payment_detail.nil?) then
      @speaker_payment_detail = SpeakerPaymentDetail.new()
    else
      @speaker_payment_detail = @speaker.speaker_payment_detail
    end
    @speaker_payment_detail.speaker_id = @speaker.id

    # @speaker_payment_detail.updateFields(params)

    respond_to do |format|
      if @speaker_payment_detail.update!(params[:speaker_payment_detail])

        format.html { redirect_to("/speaker_portals/show_payment_detail", :notice => 'Payment details were successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { redirect_to("/speaker_portals/show_payment_detail", :notice => 'Update error.') }
        format.xml  { render :xml => @speaker_payment_detail.errors, :status => :unprocessable_entity }
      end
    end


  end

  #GET
  def show_travel_detail

    @speaker = get_speaker
    @speaker_travel_detail = SpeakerTravelDetail.where(speaker_id:@speaker.id)
		@speaker_payment_detail = SpeakerPaymentDetail.where(speaker_id:@speaker.id)

    @current_tab = get_current_tab("Travel & Lodging")

    if (@speaker_travel_detail.length==0) then
      @speaker_travel_detail = nil
    else
      @speaker_travel_detail = @speaker_travel_detail.first
    end

    if (@speaker_payment_detail.length==0) then
      @speaker_payment_detail = nil
    else
      @speaker_payment_detail = @speaker_payment_detail.first
    end




  end


  #GET
  #show speaker sessions
  def sessions

    @speaker = get_speaker
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
    @speaker_portal_settings = Setting.return_speaker_portal_settings(session[:event_id])

    session_count = SessionsSpeaker.where(speaker_id: @speaker.id).count

    @session_limit_reached = session_count >= @speaker_portal_settings&.total_session.to_i

    @current_tab = get_current_tab("Sessions")

    speaker_type = SpeakerType.where(speaker_type:params[:speaker_type]) if params[:speaker_type].present?

    unless (speaker_type.blank? ) #show only speaker sessions of requested type
      speaker_type_id = speaker_type.first.id

      @sessions = Session.select('sessions.*,location_mappings.name AS location_mapping_name,speaker_types.speaker_type as
        speaker_type_name').joins('
          LEFT JOIN sessions_speakers ON sessions.id=sessions_speakers.session_id
          LEFT JOIN location_mappings on sessions.location_mapping_id=location_mappings.id
          LeFT JOIN speaker_types on sessions_speakers.speaker_type_id=speaker_types.id').where('
          sessions_speakers.speaker_id=? AND sessions_speakers.speaker_type_id=?',@speaker.id,speaker_type_id)

    else #show all speaker sessions

      @sessions = Session.select('sessions.*,location_mappings.name AS location_mapping_name,speaker_types.speaker_type as
        speaker_type_name').joins('
          LEFT JOIN sessions_speakers ON sessions.id=sessions_speakers.session_id
          LEFT JOIN location_mappings on sessions.location_mapping_id=location_mappings.id
          LeFT JOIN speaker_types on sessions_speakers.speaker_type_id=speaker_types.id').where('
          sessions_speakers.speaker_id=?',@speaker.id)

    end



  end

  #GET
  #show session detail page
  def session_detail

    @speaker = get_speaker
    @session = Session.find(params[:session_id])

  end

  #GET
  #edit name/description for speaker session
  def edit_session

    @session = Session.find(params[:id])

    respond_to do |format|

      format.html { render:'edit_session', layout:'speakerportal_2013' }
    end

  end

  #PUT
  #update name/description for speaker session
  def update_session

    @session = Session.find(params[:id])

      respond_to do |format|
        if @session.update!(params.require(:session).permit(:title, :description))

          format.html { redirect_to('/speaker_portals/sessions', :notice => 'Session was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit_session" }
          format.xml  { render :xml => @session.errors, :status => :unprocessable_entity }
        end
      end
  end



  #show change password page
  def edit_account
    @user = User.find(current_user.id)

  end

  #PUT
  #update password
  def update_account

    @user = current_user

    #@user.original_email=@user.email
    #puts "first check oe: #{@user.original_email}"

    if params[:user][:password].blank? and params[:user][:email]==@user.email
      [:password,:password_confirmation,:current_password].collect{|p| params[:user].delete(p) }

    else
      @user.errors[:base] << "The password you entered is incorrect" unless @user.valid_password?(params[:user][:current_password])
    end

    respond_to do |format|
      if @user.errors[:base].empty? and @user.update!(params.require(:user).permit(:password,:password_confirmation))
        flash[:notice] = "Your password has been updated"
        sign_in(@user, bypass:true)
        format.json { render :json => @user.to_json, :status => 200 }
        format.xml  { head :ok }
        format.html { redirect_back fallback_location: root_url }
      else
        format.json { render :text => "Could not update user", :status => :unprocessable_entity } #placeholder
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.html { render :action => :edit_account, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml, :html)


  end

  def edit_email
    @user = current_user
  end

  def update_email
    @user = current_user

    # @user.original_email=@user.email
    # puts "first check oe: #{@user.original_email}"

    if params[:user][:email]==@user.email
      [:current_password].collect{|p| params[:user].delete(p) }

    else
      @user.errors[:base] << "The password you entered is incorrect" unless @user.valid_password?(params[:user][:current_password])
    end

    respond_to do |format|
      if @user.errors[:base].empty? and @user.update!(params.require(:user).permit(:email))
        flash[:notice] = "Your email has been updated"
        sign_in(@user, bypass:true)
        format.json { render :json => @user.to_json, :status => 200 }
        format.xml  { head :ok }
        format.html { redirect_back fallback_location: root_url }
      else
        format.json { render :text => "Could not update user", :status => :unprocessable_entity } #placeholder
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.html { render :action => :edit_email, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml, :html)
  end


  ### PDF Management ###

  #GET
  #show existing PDFs for editing
  def index_pdf

    #retrieve existing pdfs
    @event_file_type = EventFileType.where(name:'speaker_pdf_upload').first
    @event_file_type2 = EventFileType.where(name:'speaker_pdf_no_sign').first
    @pdf_files = EventFile.where(event_id:session[:event_id],event_file_type_id:[@event_file_type.id,@event_file_type2.id])

    respond_to do |format|

        format.html { render:'index_pdf', layout:'subevent_2013'}
    end

  end

  #GET
  #create a new pdf
  def new_pdf

    @pdf = EventFile.new

    respond_to do |format|

        format.html { render:'new_pdf', layout:'subevent_2013'}
    end

  end

  #POST
  #create a pdf event_file
  def create_pdf
    @pdf = EventFile.new(event_file_params)
    @pdf.event_id = session[:event_id]
    @pdf.uploadPDF(params)
    @pdf.save()


    respond_to do |format|

      format.html { redirect_to('/speaker_portals/index_pdf', :notice => 'PDF successfully created') }
    end

  end

  #GET
  #edit a pdf
  def edit_pdf

    @pdf = EventFile.find(params[:id])
    @signed = @pdf.event_file_type.name.eql? "speaker_pdf_upload"

    respond_to do |format|

      format.html { render:'edit_pdf', layout:'subevent_2013' }
    end
  end


  #PUT
  #update a pdf
  def update_pdf

    @pdf = EventFile.find(params[:id])
    @pdf.uploadPDF(params)

    respond_to do |format|
      if @pdf.update!(event_file_params)

        format.html { redirect_to('/speaker_portals/index_pdf', :notice => 'PDF was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit_pdf" }
        format.xml  { render :xml => @pdf.errors, :status => :unprocessable_entity }
      end
    end

  end

  #DELETE
  #remove a pdf
  def delete_pdf
    @pdf = EventFile.find(params[:id])
    @pdf.destroy

    respond_to do |format|
      format.html { redirect_to('/speaker_portals/index_pdf') }
    end

  end

  #GET
  #list pdfs in speaker portal for download
  def download_pdf

    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

    speaker = get_speaker
    @speaker=speaker
    #retrieve existing pdfs
    @event_file_type = EventFileType.where(name:'speaker_pdf_upload').first
    @pdf_files = EventFile.where(event_id:speaker.event_id,event_file_type_id:@event_file_type.id)
    @event_file_type = EventFileType.where(name:'speaker_pdf_no_sign').first
    @info_pdf_files=EventFile.where(event_id:speaker.event_id,event_file_type_id:@event_file_type.id)

    @current_tab = get_current_tab("PDF Downloads")


  end

  def messages
    @event         = Event.where(id:session[:event_id]).first
    @messages      = Message.where(event_id:@event.id, message_type:[1,3])
    @event_setting = EventSetting.where("event_id= ?",@event.id).first
    @speaker       = get_speaker

    @current_tab = get_current_tab("Messages")

  end

  def favourite_exhibitors
    @event=Event.where(id:session[:event_id]).first
    @messages=Message.where(event_id:@event.id,status:"active")
    @event_setting = EventSetting.where("event_id= ?",@event.id).first

    @current_tab = get_current_tab("Messages")

  end

  def show_favourite_exhibitor
    @event=Event.where(id:session[:event_id]).first
    @messages=Message.where(event_id:@event.id,status:"active")
    @event_setting = EventSetting.where("event_id= ?",@event.id).first

    @current_tab = get_current_tab("Messages")

  end

  def help
  end

  def print_view
    @speaker = get_speaker
    @sessions = @speaker.sessions.order('date', 'start_at')

    render :layout => "print_view"
  end

  def session_polls
    @speaker = get_speaker
    @sessions = @speaker.sessions
  end

  def session_polls_list
    @session = Session.find_by(id: params[:session_id])
    @polls = Poll.where(event_id: @session.event_id).where.not(id: @session.poll_sessions.map(&:poll_id))
  end

  def new_poll_by_speaker
    @poll = Poll.new
  end

  private

    def get_speaker
      if current_user.role? :speaker then
        current_user.first_or_create_speaker( session[:event_id] )
      end
    end

    def get_trackowner
      user = User.find(current_user.id)
      return Trackowner.where(email:user.email,event_id:session[:event_id]).first
    end

    def get_current_tab(default_name)
      # current_tab = Tab.select('tabs.*,tab_types.default_name').joins('
      # JOIN tab_types ON tabs.tab_type_id=tab_types.id').where('event_id=? AND default_name=?',session[:event_id],default_name).first
      # return current_tab

      current_tab = Tab.tab_by_event_and_default_name session[:event_id], default_name, 'speaker'
    end

    def set_layout
      if current_user.role? :speaker then
        'speakerportal_2013'
      else
        'subevent_2013'
      end
    end

    def event_file_params
      params.require(:event_file).permit(:event_id, :name, :size, :mime_type, :path, :event_file_type_id, :created_at, :updated_at, :exhibitor_id)
    end

    def speaker_update_params
      params.require(:speaker).permit(:first_name, :middle_initial, :last_name, :email, :honor_prefix,
        :honor_suffix, :company, :address1, :address2, :address3, :city, :state, :country, :zip, :work_phone, :mobile_phone, 
        :home_phone, :fax, :biography, :notes, :availability_notes, :financial_disclosure,
        :fd_tax_id, :fd_pay_to, :fd_street_address, :fd_city, :fd_state, :fd_zip, :event_id, :photo_filename
      )
    end

end
