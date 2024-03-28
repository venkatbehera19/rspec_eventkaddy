class SpeakersController < ApplicationController
  layout :set_layout

  load_and_authorize_resource

  def bulk_set_speakers_photos_to_online
    master_url = Event.find(session[:event_id]).master_url
    count      = 0

    if master_url.blank?
      raise "This event's master url is not set, and the action could not be performed."
    end

    # Bergevin had to name the event_files.name with the url because this
    # route didn't exist yet. So in cases where the path contains the url
    # (because on saving a speaker, the name was set to the relative dir location
    # + the name, I'm guessing) remove the master url and everything before it.
    # This does not clean the broken speaker paths in the cms, but it should
    # prevent a client from breaking the existing hack; We could just as easily
    # save the result of this to the event_file if we wanted to fix that too, but
    # for now I will make the minimum change 10/12/17
    def clean_hack_for_speaker_photos path, master_url
      if path.match master_url
        path.split(master_url).last
      else
        path
      end
    end

    Speaker
      .where( event_id: session[:event_id] )
      .where('photo_event_file_id IS NOT NULL')
      .each {|s| next unless s.event_file_photo # in case id is set but record is lost
                 count    += 1
                 full_url  = master_url + clean_hack_for_speaker_photos(
                   s.event_file_photo.path, master_url
                 )
                 s.update! photo_filename: full_url }
    redirect_to speakers_url, notice: "#{count} speakers photos set to online."
  end

  # def mobile_data

  #  @empty_data = "[]"

	# if (params[:event_id]) then

	# 		Rails.cache.fetch "speakers-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}" do

	# 			@speakers = Speaker.select('speakers.honor_prefix,speakers.honor_suffix,speakers.first_name,speakers.last_name,speakers.email,speakers.title,speakers.company,speakers.photo_filename,speakers.biography,sessions.*,event_files.path AS file_url,DATE_FORMAT(start_at,\'%H-%i\') AS start_at_formatted,DATE_FORMAT(end_at,\'%H-%i\') AS end_at_formatted,DATE_FORMAT(start_at,\'%l:%i %p\') AS start_at_12h,DATE_FORMAT(end_at,\'%l:%i %p\') AS end_at_12h,location_mappings.name as location_name,location_mappings.x AS location_x, location_mappings.y AS location_y, location_mappings.map_id AS map_id, sessions.id AS session_id, sessions_speakers.id as ssid').joins('
	# 		    LEFT OUTER JOIN sessions_speakers ON sessions_speakers.speaker_id=speakers.id
	# 		    LEFT OUTER JOIN sessions ON sessions_speakers.session_id=sessions.id
	# 		    LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id
	# 		    LEFT OUTER JOIN event_files ON speakers.photo_event_file_id=event_files.id').where("speakers.event_id= ? AND sessions_speakers.id > ?",params[:event_id],params[:record_start_id]).order('ssid ASC').limit(350).to_json

	# 		end

	# 		@speakers = Rails.cache.read "speakers-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}"


	# 	if (JSON.parse(@speakers).length > 0) then
	# 		render :json => @speakers, :callback => params[:callback]
	# 	else
	# 		render :json => @empty_data, :callback => params[:callback]
	# 	end

  #   end

  # end


  def bulk_add_speaker_photos
    @event = Event.find session[:event_id]
  end

  def bulk_create_speaker_photos
    @event = Event.find session[:event_id]

    BulkUploadEventFileImage.new(
      event:              @event,
      event_file_type_id: EventFileType.where(name:'speaker_photo')[0].id,
      files:              params[:event_files],
      owner_class:        Speaker,
      owner_assoc:        :photo_event_file_id,
      owner_identifier:   :speaker_code,
      target_path:        Rails.root.join('public', 'event_data', @event.id.to_s, 'speaker_photos'),
      rename_image:       false,
      new_width:          150,
      new_height:         150
    ).call

    respond_to do |format|
      unless @event.errors.full_messages.length > 0
        format.html {
          redirect_to("/speakers/bulk_add_speaker_photos",
          :notice => "#{params[:event_files].inject('') {|m, f| m += "#{f.original_filename} "}} successfully added.")}
      else
        format.html {
          redirect_to("/speakers/bulk_add_speaker_photos",
          :alert => "#{@event.errors.full_messages.inject('') {|m, e| m += "#{e} "}}")}
      end
    end

  end

  def index

	if (session[:event_id]) then

    @event_id = session[:event_id]
    @current_user = current_user

    #disabled while using server-side fetch for datatables
		#@speakers = Speaker.select('DISTINCT speakers.*').where("event_id= ?",session[:event_id])

	    respond_to do |format|
	      format.html # index.html.erb
	      format.xml  { render :xml => @speakers }
	      #format.json { render :json => @speakers.to_json, :callback => params[:callback] }
        format.json { render json: SpeakersDatatable.new(view_context,@event_id,@current_user) }
	    end

    else
      redirect_to "/home/session_error"
    end

  end

  # GET /speakers/1
  # GET /speakers/1.xml
  def show
    @speaker = Speaker.find(params[:id])
    @speaker_types = SpeakerType.all
    @sessions = Session.where("event_id = ? and id not in (?)", session[:event_id], @speaker.sessions.ids)
    @sessions_speaker = SessionsSpeaker.new
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @speaker }
      format.json { render :json => @speaker.to_json, :callback => params[:callback] }
    end
  end

  # GET /speakers/new
  # GET /speakers/new.xml
  def new
    @speaker = Speaker.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @speaker }
    end
  end

  def edit
    @speaker = Speaker.find(params[:id])
  end

  def create
    params[:speaker][:event_id] = session[:event_id]
    @speaker = Speaker.new(speaker_params)
    @speaker.event_id = session[:event_id]
    @speaker.updatePhoto(params)
    @speaker.updateCV(params)
    @speaker.updateFD(params)
    @speaker.photo_filename = params[:online_url].eql?('1') ? @speaker.online_url : nil
    respond_to do |format|
      if @speaker.save!
        # Add newly created speaker to session if it is created from sessions side
        @sessions_speaker = params[:session_id] && params[:speaker_type_id] ?
          SessionsSpeaker.new(session_id: params[:session_id], speaker_id: @speaker.id,
             speaker_type_id: params[:speaker_type_id]) : nil
        @sessions_speaker.save! unless @sessions_speaker.nil?

        format.html { redirect_to(@speaker, :notice => 'Speaker was successfully created.') }
        format.xml  { render :xml => @speaker, :status => :created, :location => @speaker }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @speaker.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @speaker = Speaker.find(params[:id])
    @speaker.updatePhoto(params)
    @speaker.updateCV(params)
    @speaker.updateFD(params)
    params[:speaker][:photo_filename] = params[:online_url] == '1' ? @speaker.online_url : nil

    respond_to do |format|
      if @speaker.update!(speaker_params)
        ## update published status of session association records to match speaker only if unpublished
        if @speaker.unpublished
          @speaker.sessions_speakers.each {|s| s.update!(unpublished: true)}
        end
        format.html { redirect_to(@speaker, :notice => 'Speaker was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @speaker.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @speaker = Speaker.find(params[:id])
    @speaker.destroy

    respond_to do |format|
      format.html { redirect_to(speakers_url) }
      format.xml  { head :ok }
    end
  end

  def edit_travel_detail
    @speaker = Speaker.find(params[:id])
    @speaker_travel_detail = SpeakerTravelDetail.where(speaker_id:@speaker.id)
    #create record if none exists
    if (@speaker_travel_detail.length==0) then
      @speaker_travel_detail = SpeakerTravelDetail.new()
    else
      @speaker_travel_detail = @speaker_travel_detail.first
    end
  end

  def update_travel_detail
    @speaker = Speaker.find(params[:speaker_travel_detail][:speaker_id])
    @speaker_travel_detail= SpeakerTravelDetail.where(speaker_id:@speaker.id)

    #create record if none exists
    if (@speaker_travel_detail.length==0) then
      @speaker_travel_detail = SpeakerTravelDetail.new()
    else
      @speaker_travel_detail = @speaker_travel_detail.first
    end

    respond_to do |format|
      if @speaker_travel_detail.update!(speaker_travel_details_params)

        format.html { redirect_to("/speakers/#{@speaker.id}", :notice => 'Travel details successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { redirect_to("/speakers/edit_travel_detail", :notice => 'Update error.') }
        format.xml  { render :xml => @speaker.errors, :status => :unprocessable_entity }
      end
    end

  end

  #GET
  #edit
  def edit_payment_detail

    @speaker = Speaker.find(params[:id])
    @speaker_payment_detail = SpeakerPaymentDetail.where(speaker_id:@speaker.id)

    #create record if none exists
    if (@speaker_payment_detail.length==0) then
      @speaker_payment_detail = SpeakerPaymentDetail.new()
    else
      @speaker_payment_detail = @speaker_payment_detail.first
    end

  end

  #PUT
  #update
  def update_payment_detail

    @speaker = Speaker.find(params[:speaker_payment_detail][:speaker_id])
    @speaker_payment_detail= SpeakerPaymentDetail.where(speaker_id:@speaker.id)

    #create record if none exists
    if (@speaker_payment_detail.length==0) then
      @speaker_payment_detail = SpeakerPaymentDetail.new()
    else
      @speaker_payment_detail = @speaker_payment_detail.first
    end

    respond_to do |format|
      if @speaker_payment_detail.update!(speaker_payment_detail_params)

        format.html { redirect_to("/speakers/#{@speaker.id}", :notice => 'Payment details successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { redirect_to("/speakers/edit_payment_detail", :notice => 'Update error.') }
        format.xml  { render :xml => @speaker.errors, :status => :unprocessable_entity }
      end
    end

  end





  #send speaker photo
  def send_photo
  	@filename ="#{RAILS_ROOT}/tmp/test/test.doc"

	 send_file( '/Users/my_name/Desktop/image.jpg',
                :disposition => 'inline',
                :type => 'image/jpeg',
                :stream => false,
                :filename => 'image.jpg' )
  end

  def download_all_zip

    @event_id     = session[:event_id]
    @speaker_file = SpeakerFile.where(event_id:@event_id).first
    raise ActionController::RoutingError, "No speaker files have been uploaded for this event." unless @speaker_file
    @event_name   = Event.where(id:@event_id).first.name.gsub(/\s/,'_')
    @speaker_file.event_name=@event_name
    @speaker_file.bundleFiles

    filename = @event_name+'_speaker_files.zip'
    path = Rails.root.join( 'download','event_data',session[:event_id].to_s,'speaker_files', filename )

    if ((current_user.role? :superadmin) && File.exists?(path) || (current_user.role? :client) && File.exists?(path))
      send_file( path, x_sendfile: true )
    else
      raise ActionController::RoutingError, "File not available."
    end

  end

  # def download_all_zip
    # @event_id = session[:event_id]
    # @speaker_files = SpeakerFile.where(event_id:@event_id)
  #   @speaker_files.bundleFiles

  #   send_file 'public/event_data/'+@speaker_file.event_id.to_s+'/speaker_files/'+@speaker.id.to_s+'_files', :type => 'application/zip'

  # end

  private
    def set_layout
    if current_user.role? :trackowner then
      session[:layout]
    elsif current_user.role? :speaker then
      'speakerportal_2013'
    else
      'subevent_2013'
    end
  end

  def speaker_params
    params.require(:speaker).permit(:event_id, :unpublished, :first_name, :last_name, :honor_prefix, :honor_suffix, :title, :company, :biography, :photo_filename, :photo_event_file_id, :email, :user_id, :speaker_code, :middle_initial, :notes, :availability_notes, :address1, :address2, :address3, :city, :state, :country, :zip, :work_phone, :mobile_phone, :home_phone, :fax, :financial_disclosure, :cv_event_file_id, :fd_tax_id, :fd_pay_to, :fd_street_address, :fd_city, :fd_state, :fd_zip, :fd_event_file_id, :speaker_type_id, :twitter_url, :facebook_url, :linked_in, :unsubscribed, :token, :custom_filter_1, :custom_filter_2, :custom_filter_3)
  end

  def speaker_travel_details_params
    params.require(:speaker_travel_detail).permit(:speaker_id, :approved_arrival_date, :approved_departure_date, :approved_departure_date,
      :approved_departure_date, :actual_arrival_date, :actual_arrival_date, :actual_arrival_date, :actual_departure_date,
      :actual_departure_date, :actual_departure_date, :hotel_name,
      :hotel_confirmation_number, :hotel_cost, :hotel_reimbursement,
      :airfare_cost, :airfare_reimbursement, :mileage, :comments)
  end

  def speaker_payment_detail_params
    params.require(:speaker_payment_detail).permit(:speaker_id, :vip_code, :direct_bill_travel, :direct_bill_housing, :eligible_housing_nights,
      :payment_type, :eligible_payment_rate, :total_honorarium, :total_per_diem)
  end

end
