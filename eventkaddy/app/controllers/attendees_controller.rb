class AttendeesController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  skip_before_action :verify_authenticity_token, :only => [:generate_ce_sessions_pdf_report, :options, :email_attendee_notes,:generate_lead_surveys_report]
  def initialize
    super
    @@reporting_db = reporting_db
  end


  def bulk_set_attendees_photos_to_online
    master_url = Event.find(session[:event_id]).master_url
    count      = 0

    if master_url.blank?
      raise "This event's master url is not set, and the action could not be performed."
    end

    Attendee
      .where( event_id: session[:event_id] )
      .where('photo_event_file_id IS NOT NULL')
      .each {|a| next unless a.event_file_photo # in case id is set but record is lost
                 count    += 1
                 full_url  = master_url + a.event_file_photo.path
                 a.update! photo_filename: full_url }
    redirect_to attendees_url, notice: "#{count} attendees photos set to online."
  end

  def mobile_data

	   @empty_data = "[]"


		if (params[:event_id]) then
			@attendees = Attendee.select('attendees.id,attendees.event_id,first_name,last_name,honor_prefix,honor_suffix,title,company,biography,business_unit,business_phone,mobile_phone,
			email,event_files.path AS file_url').joins('
			LEFT OUTER JOIN event_files ON attendees.photo_event_file_id=event_files.id').where("attendees.event_id= ? AND attendees.id > ?",params[:event_id],params[:record_start_id]).order('id ASC').limit(150)


			if (@attendees.length > 0) then
				render :json => @attendees.to_json, :callback => params[:callback]
			else
				render :json => @empty_data, :callback => params[:callback]
			end

		end

  end

  def validar_push

    def get_attendee_email(attendee)
      if attendee.email.blank? then return "Unavailable" else return attendee.email; end
    end

    def return_string_of_session_favourites(sessions_attendees,attendee)
      sessions_favourited = ''
      length              = sessions_attendees.where(attendee_id:attendee.id).length

      sessions_attendees.where(attendee_id:attendee.id).each_with_index do |session, index|
        unless (index+1)===length
          sessions_favourited += "#{session.session_code}; "
        else
          sessions_favourited += "#{session.session_code}"
        end
      end
      return sessions_favourited
    end

    def return_xml_update_for_attendee_as_string(attendee,email,sessions_favourited)
      attendee_title = ''
      attendee_title = attendee.title.gsub(/[&]/, '&amp;') unless attendee.title.blank?
      return "<update>

 <AssociateIDNumber>#{attendee.account_code}</AssociateIDNumber>
 <MeetingBadgeFirstName>#{attendee.first_name}</MeetingBadgeFirstName>
 <MeetingBadgeLastName>#{attendee.last_name}</MeetingBadgeLastName>
 <Title>#{attendee_title}</Title>
 <BusinessUnit>#{attendee.business_unit}</BusinessUnit>
 <WorkPhone>#{attendee.business_phone}</WorkPhone>
 <MobilePhone>#{attendee.mobile_phone}</MobilePhone>
 <EmailAddress>#{email}</EmailAddress>
 <GeneralSessionSeatingAssignment>#{attendee.assignment}</GeneralSessionSeatingAssignment>
 <SessionKeys>#{sessions_favourited}</SessionKeys>
 <walkIn>false</walkIn>

</update>"
    end

    def make_validar_soap_request_apd(updates)
      client = Savon::Client.new do |wsdl, http|
        wsdl.document = "https://registration.validar.com/WebServices/V1/Partner/PartnerService.asmx?WSDL"
      end
      client.wsse.credentials "#{VALIDARUSER}", "#{VALIDARPASS}"

      return client.request "PutRegistrationData" do
        soap.version = 1

        http.headers = {
          "Host"           => "registration.validar.com",
          "Content-Type"   => "text/xml;charset=utf-8",
          "Content-Length" => "880",
          "SOAPAction"     => '"https://portal.validar.com/PutRegistrationData"'
        }

        #List of possible elements expected: 'MeetingBadgeLastName, WorkPhone, SessionKeys, Title, BusinessUnit, MobilePhone, GeneralSessionSeatingAssignment, EmailAddress, MeetingBadgeFirstName, walkIn, AssociateIDNumber'.
        soap.xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>

<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">

 <soap:Header>

 <AuthenticationSoapHeader xmlns=\"https://portal.validar.com/\">

 <Username>#{VALIDARUSER}</Username>

 <Password>#{VALIDARPASS}</Password>
 </AuthenticationSoapHeader>

 </soap:Header>

 <soap:Body>

 <PutRegistrationData xmlns=\"https://portal.validar.com/\">

 <eventGuid>#{VALIDARGUID}</eventGuid>

 <data>

 <![CDATA[<updates>" + updates + "

</updates>]]>
</data>

 </PutRegistrationData>

 </soap:Body>

</soap:Envelope>"

      end
    end

    attendees          = Attendee.where(event_id:session[:event_id])
     #AND first_name IS NOT NULL AND last_name IS NOT NULL AND first_name!='' AND last_name!=''")
    sessions_attendees = SessionsAttendee.where(:attendee_id => @attendees)
    updates            = ''


    attendees.each do |attendee|
      email               = get_attendee_email(attendee)
      sessions_favourited = return_string_of_session_favourites(sessions_attendees,attendee)
      updates             += return_xml_update_for_attendee_as_string(attendee,email,sessions_favourited)
    end

    response         = make_validar_soap_request_apd(updates)
    response_hash    = response.to_hash[:put_registration_data_response][:put_registration_data_result]
    response_result  = Nori.parse(response_hash)[:put_registrant_data_status][:success]
    response_message = Nori.parse(response_hash)[:put_registrant_data_status][:message]

    response_message = ActionController::Base.helpers.sanitize("Attendee data SOAP request failed. Validar response:<br><br> #{response_message}".gsub("Message:","<br><br>Message:"), tags: %w(br))

    respond_to do |format|
      if response.success? && response_result == true
        format.html { redirect_to("/attendees", :notice => "Attendee data SOAP request successfully sent to Validar.") }
      elsif response_result == false
        format.html { redirect_to("/attendees", :alert =>  response_message) }
      else
        format.html { redirect_to("/attendees", :alert => 'Attendee data SOAP request failed #{error.to_s}') }
      end
    end

  end

  def generate_lead_surveys_report
  	puts "generate lead survey report"
    if access_allowed?
      set_access_control_headers
      headers['Content-Type'] = "text/javscript; charset=utf8"
      @result                   = {}
      @result["status"]         = 'false'
      @result["error_messages"] = []

      if params['api_proxy_key'] === API_PROXY_KEY

        if params['event_id'].to_i == 216
          attendee = Attendee.where(event_id:params['event_id'],account_code:params['account_code']).first
          attendee.update!(notes_email:params['email']) ## set attendee email to what they provide in cordova prompt
          AttendeeMailer.lead_report_unavailable( attendee.notes_email, attendee ).deliver
        else

          attendee = Attendee.where(event_id:params['event_id'],account_code:params['account_code']).first
          attendee.update!(notes_email:params['email']) ## set attendee email to what they provide in cordova prompt

          cmd = Rails.root.join('ek_scripts',"generate_and_mail_lead_survey_report.rb \"#{attendee.id}\"")

          pid = Process.spawn("ROO_TMP='/tmp' ruby #{cmd} 2>&1")
          Process.detach pid
        end
        @result["status"] = 'true'
      else
        @result["error_messages"] << "Error: Incorrect proxy key."
      end
      render :json => @result.to_json
    else
      head :forbidden
    end
  end

  def cms_generate_lead_surveys_report
     @attendee = Attendee.find_by(event_id: params['event_id'], account_code: params['attendee_code'])
     @event = Event.find_by(id: params['event_id'])
     render xlsx: "cms_generate_lead_surveys_report", filename: "lead_survey_report_for_#{@attendee.full_name.gsub(' ', '_')}.xlsx", formats: [:xlsx]
  end

  def generate_ce_sessions_pdf_report
  	puts "generate ce sessions"
    if access_allowed?
      set_access_control_headers
      headers['Content-Type'] = "text/javscript; charset=utf8"
      proxy_key               = params['api_proxy_key']
      account_code            = params['account_code']
      event_id                = params['event_id']
      send_email              = params['send_email']
      email                   = params['email']
      type                    = params['type']
      certificate_id          = params['certificate_id']

      @result                   = {}
      @result["status"]         = 'false'
      @result["error_messages"] = []

      if (proxy_key === API_PROXY_KEY) then
        attendee = Attendee.where(event_id:event_id,account_code:account_code).first
        attendee.update!(notes_email:email) ## set attendee email to what they provide in cordova prompt
        attendee.generate_and_send_ce_sessions_pdf_report(send_email, type, certificate_id)
        @result["status"] = 'true'
      else
        @result["error_messages"] << "Error: Incorrect proxy key."
      end
      if !!params['local_request']
        redirect_to attendee_path(attendee.id) and return
      else
        render :json => @result.to_json
      end
    else
      head :forbidden
    end
  end

  def attendee_sessions

		event_id=params[:event_id]
		attendee_account_code=params[:attendee_auth_val]
		@empty_data = "[]"

		if (event_id && attendee_account_code) then
			@sessions = Session.select('sessions.session_code, sessions_attendees.flag AS flag').joins('
			JOIN sessions_attendees ON sessions.session_code=sessions_attendees.session_code
			JOIN attendees ON sessions_attendees.attendee_id=attendees.id').where('sessions.event_id=? AND attendees.account_code=?',event_id,attendee_account_code)

			result=[]
			scount=0
			@sessions.each do |session|
			  result[scount]={}
			  result[scount][:session_code]=session.session_code
			  result[scount][:flag]=session.flag
				scount+=1
			end

			if (@sessions.length > 0) then
				render :json => result, :callback => params[:callback]
			else
				render :json => @empty_data, :callback => params[:callback]
			end

		else
			render :json => @empty_data
		end

	end

  def attendee_exhibitors

		event_id=params[:event_id]
		attendee_account_code=params[:attendee_auth_val]
		@empty_data = "[]"

		if (event_id && attendee_account_code) then
			@exhibitors = Exhibitor.select('exhibitors.company_name, exhibitor_attendees.flag AS flag').joins('
			JOIN exhibitor_attendees ON exhibitors.company_name=exhibitor_attendees.company_name
			JOIN attendees ON exhibitor_attendees.attendee_id=attendees.id').where('exhibitors.event_id=? AND attendees.account_code=?',event_id,attendee_account_code)

			result=[]
			scount=0
			@exhibitors.each do |exhibitor|
			  result[scount]={}
			  result[scount][:company_name]=exhibitor.company_name
			  result[scount][:flag]=exhibitor.flag
				scount+=1
			end

			if (@exhibitors.length > 0) then
				render :json => result, :callback => params[:callback]
			else
				render :json => @empty_data, :callback => params[:callback]
			end

		else
			render :json => @empty_data
		end

	end

  def view_history
    @event_id                = session[:event_id]
    @event                   = Event.find @event_id
    @attendee                = Attendee.find params[:id]

    @my_ce_sessions          = Session.select("sessions.session_code, sessions.title, sessions.date, sessions.start_at, sessions.end_at")
                              .joins('JOIN sessions_attendees ON sessions.session_code=sessions_attendees.session_code')
                              .where('sessions.event_id=? AND sessions_attendees.attendee_id=?',@event_id,@attendee.id)

    exhibitor_ids            = Exhibitor.where(event_id:@event_id).pluck(:id)
    exhibitor_ids            = ExhibitorAttendee.where(attendee_id:@attendee.id, exhibitor_id:exhibitor_ids).where("exhibitor_id IS NOT NULL").pluck(:exhibitor_id)
    @my_favorited_exhibitors = Exhibitor.select("contact_name, company_name").where(id: exhibitor_ids)

    @page_view_exhibitors    = @@reporting_db.query("SELECT vv.exhibitor_id,
                                                      vv.exhibitor_company,
                                                      vv.updated_at
                                                    FROM reporting.video_views as vv
                                                    WHERE vv.attendee_id=#{@attendee.id} AND vv.event_id=#{@event_id} AND vv.exhibitor_id IS NOT NULL")

    @page_view_sessions      = @@reporting_db.query(
                                "SELECT count(vv.session_code) as number_of_visits,
                                vv.id,
                                vv.event_id,
                                vv.session_title,
                                vv.session_code,
                                vv.updated_at,
                                s.date,
                                s.start_at,
                                s.end_at
                              FROM reporting.video_views as vv
                              JOIN #{primary_db}.sessions as s on s.session_code = vv.session_code AND s.event_id=vv.event_id
                              WHERE vv.attendee_id=#{@attendee.id} AND vv.event_id=#{@event_id}
                              GROUP BY vv.session_code")

    @video_views             = VideoView.select("video_views.id, video_views.session_id, video_views.view_total, sessions.title, sessions.session_code")
                                        .joins('JOIN sessions on sessions.id = video_views.session_id and sessions.event_id=video_views.event_id')
                                        .where(attendee_id: @attendee.id,event_id: @event_id)

    @platform_logins         = @@reporting_db.query(
                                "SELECT created_at
                              FROM reporting.logins
                              WHERE attendee_id=#{@attendee.id} AND event_id=#{@event_id}")
  end

  def ce_sessions_report
    @event                   = Event.find session[:event_id]
    @attendee                = Attendee.find params[:id]

    @my_ce_sessions          = Session.select("sessions.session_code, sessions.title, sessions.date, sessions.start_at, sessions.end_at")
                              .joins('JOIN sessions_attendees ON sessions.session_code=sessions_attendees.session_code')
                              .where('sessions.event_id=? AND sessions_attendees.attendee_id=?',@event.id,@attendee.id)
                              .order('sessions.session_code')

    render xlsx: "ce_sessions_report", filename: "#{@attendee.first_name}_#{@attendee.last_name}_ce_sessions_report.xlsx" , formats: [:xlsx]

  end


  def favorited_exhibitors_report
    @attendee                = Attendee.find params[:id]
    exhibitor_ids            = Exhibitor.where(event_id:session[:event_id]).pluck(:id)
    exhibitor_ids            = ExhibitorAttendee.where(attendee_id:@attendee.id, exhibitor_id:exhibitor_ids).where("exhibitor_id IS NOT NULL").pluck(:exhibitor_id)
    @my_favorited_exhibitors = Exhibitor.select("contact_name, company_name").where(id: exhibitor_ids).order('contact_name')
    render xlsx: "favorited_exhibitors_report", filename: "#{@attendee.first_name}_#{@attendee.last_name}_favorited_exhibitors_report.xlsx" , formats: [:xlsx]
  end

  def page_view_exhibitors_report
    @event                   = Event.find session[:event_id]
    @attendee                = Attendee.find params[:id]
    @page_view_exhibitors    = @@reporting_db.query("SELECT vv.exhibitor_id,
      vv.exhibitor_company,
      vv.updated_at
    FROM reporting.video_views as vv
    WHERE vv.attendee_id=#{@attendee.id} AND vv.event_id=#{@event.id} AND vv.exhibitor_id IS NOT NULL
    ORDER BY vv.exhibitor_company")
    render xlsx: "page_view_exhibitors_report", filename: "#{@attendee.first_name}_#{@attendee.last_name}_page_view_exhibitors_report.xlsx" , formats: [:xlsx]
  end

  def page_view_sessions_report
    @event                   = Event.find session[:event_id]
    @attendee                = Attendee.find params[:id]
    @page_view_sessions      = @@reporting_db.query(
      "SELECT count(vv.session_code) as number_of_visits,
      vv.id,
      vv.event_id,
      vv.session_title,
      vv.session_code,
      vv.updated_at,
      s.date,
      s.start_at,
      s.end_at
    FROM reporting.video_views as vv
    JOIN #{primary_db}.sessions as s on s.session_code = vv.session_code AND s.event_id=vv.event_id
    WHERE vv.attendee_id=#{@attendee.id} AND vv.event_id=#{@event.id}
    GROUP BY vv.session_code
    ORDER BY vv.session_code")
    render xlsx: "page_view_sessions_report", filename: "#{@attendee.first_name}_#{@attendee.last_name}_page_view_sessions_report.xlsx" , formats: [:xlsx]
  end

  def video_views_report
    @attendee                = Attendee.find params[:id]
    @video_views             = VideoView.select("video_views.id, video_views.session_id, video_views.view_total, sessions.title, sessions.session_code")
                                        .joins('JOIN sessions on sessions.id = video_views.session_id and sessions.event_id=video_views.event_id')
                                        .where(attendee_id: @attendee.id,event_id: session[:event_id])
                                        .order('sessions.session_code')
    render xlsx: "video_views_report", filename: "#{@attendee.first_name}_#{@attendee.last_name}_video_views_report.xlsx" , formats: [:xlsx]
  end

  def platform_logins_report
    @event                   = Event.find session[:event_id]
    @attendee                = Attendee.find params[:id]
    @platform_logins         = @@reporting_db.query(
      "SELECT created_at
    FROM reporting.logins
    WHERE attendee_id=#{@attendee.id} AND event_id=#{@event.id}")
    render xlsx: "platform_logins_report", filename: "#{@attendee.first_name}_#{@attendee.last_name}_platform_logins_report.xlsx" , formats: [:xlsx]
end

  def show_page_views
    @attendee_id     = params[:id]
    @session_code    = params[:session_code]
    @event           = Event.find session[:event_id]
    @attendee        = Attendee.find @attendee_id
    @video_views     = @@reporting_db.query(
      "SELECT video_views.attendee_id AS attendee_id,
        video_views.session_id,
        video_views.event_id,
        video_views.created_at AS created_at
      FROM reporting.video_views
      WHERE video_views.attendee_id=#{@attendee_id} AND
      video_views.session_code='#{@session_code}' AND
      video_views.event_id=#{@event.id}")
  end

  def show_video_views
    @attendee_id     = params[:id]
    @session_id      = params[:sid]
    @attendee        = Attendee.find @attendee_id
    @video_views     = VideoView.find params[:v_id]
  end

  #GET
  #send full list of iattend sessions for an attendee
  def iattend_list

    @attendees = Attendee.where(account_code:params[:account_code],event_id:params[:event_id])

    if ( @attendees.length == 0 || @attendees.length > 1 || params[:proxy_key] != API_PROXY_KEY ) then
      render :json => "{\"status\":false}", :callback => params[:callback]
    else
      render :json => "{\"status\":true,\"iattend_sessions\":\"#{@attendees.first.iattend_sessions}\"}", :callback => params[:callback]
    end

  end

  #GET
  #update list of iattend sessions for an attendee
  def iattend_update

    @attendees = Attendee.where(account_code:params[:account_code],event_id:params[:event_id])

    if ( @attendees.length == 0 || @attendees.length > 1 || params[:proxy_key] != API_PROXY_KEY ) then
      render :json => "{\"status\":false}", :callback => params[:callback]
    else

      #update the iattend list
      @attendee = @attendees.first
      @attendee.update!(iattend_sessions:params[:iattend_sessions])

      if (@attendee.save()) then
        render :json => "{\"status\":true}", :callback => params[:callback]
      else
        render :json => "{\"status\":false}", :callback => params[:callback]
      end

    end

  end

  #GET
  #send full list of attendee favourites
  def favouritessync_list

    @attendees = Attendee.where(account_code:params[:account_code],event_id:params[:event_id])

    @attendee_sessions = SessionsAttendee.select('sessions_attendees.session_code').joins('JOIN attendees on sessions_attendees.attendee_id=attendees.id').where('
      attendees.account_code=? AND attendees.event_id=? AND sessions_attendees.flag!=?',params[:account_code],params[:event_id],'cms_external_api')

    sessions = ''
    @attendee_sessions.each_with_index do |attendee_session,i|
      if (@attendee_sessions[i+1]!=nil) then
        sessions+= "#{attendee_session["session_code"]},"
      else
        sessions+= attendee_session["session_code"]
      end
    end

    if ( @attendees.length == 0 || @attendees.length > 1 || params[:proxy_key] != API_PROXY_KEY ) then
      render :json => "{\"status\":false}", :callback => params[:callback]
    else
      render :json => "{\"status\":true,\"favourites\":\"#{sessions}\"}", :callback => params[:callback]
    end

  end

  #update the favourite list on the cms
  def favouritessync_update

    @attendees = Attendee.where(account_code:params[:account_code],event_id:params[:event_id])

    if ( @attendees.length == 0 || @attendees.length > 1 || params[:proxy_key] != API_PROXY_KEY ) then
      render :json => "{\"status\":false}", :callback => params[:callback]
    else

      #update the favourites list
      @attendee = @attendees.first
      SessionsAttendee.where('attendee_id=? AND flag!=?',@attendee.id,'cms_external_api').destroy_all()

      session_codes = params[:favourite_sessions].split(',')

      session_codes.each do |session_code|

        session = Session.where(event_id:params[:event_id],session_code:session_code).first

        #make sure we're not trying to add a session already marked as read only
        ro_record = SessionsAttendee.where(session_code:session_code,attendee_id:@attendee.id,flag:"cms_external_api")

        if (ro_record.length > 0 ) then
          next
        else
          SessionsAttendee.where(attendee_id:@attendee.id,session_code:session_code).first_or_initialize().update!(session_id:session.id,flag:"web")

        end

      end

      render :json => "{\"status\":true}", :callback => params[:callback]

    end

  end

  def exhibitor_favouritessync_list

    @attendees = Attendee.where(account_code:params[:account_code],event_id:params[:event_id])

    @attendee_exhibitors = ExhibitorAttendee.select('exhibitor_attendees.company_name').joins('JOIN attendees on exhibitor_attendees.attendee_id=attendees.id').where('
      attendees.account_code=? AND attendees.event_id=?',params[:account_code],params[:event_id])

    exhibitors = ''
    @attendee_exhibitors.each_with_index do |attendee_exhibitor,i|
      if (@attendee_exhibitors[i+1]!=nil) then
        exhibitors+= "#{attendee_exhibitor["company_name"]},"
      else
        exhibitors+= attendee_exhibitor["company_name"]
      end
    end

    if ( @attendees.length == 0 || @attendees.length > 1 || params[:proxy_key] != API_PROXY_KEY ) then
      render :json => "{\"status\":false}", :callback => params[:callback]
    else
      render :json => "{\"status\":true,\"exhibitor_favourites\":\"#{exhibitors}\"}", :callback => params[:callback]
    end

  end

  def exhibitor_favouritessync_update

    @attendees = Attendee.where(account_code:params[:account_code],event_id:params[:event_id])

    if ( @attendees.length == 0 || @attendees.length > 1 || params[:proxy_key] != API_PROXY_KEY ) then
      render :json => "{\"status\":false}", :callback => params[:callback]
    else

      #update the exhibitors favourites list
      @attendee = @attendees.first
      ExhibitorAttendee.where('attendee_id=?',@attendee.id).destroy_all()

      company_names = params[:favourited_exhibitors].split(',')

      company_names.each do |company_name|

        exhibitor = Exhibitor.where(event_id:params[:event_id],company_name:company_name).first
				ExhibitorAttendee.where(attendee_id:@attendee.id,company_name:company_name).first_or_initialize().update!(exhibitor_id:exhibitor.id,flag:"web")

      end

      render :json => "{\"status\":true}", :callback => params[:callback]

    end

  end

  def app_message
    @event    = Event.find(session[:event_id])
    attendees = get_client_attendees
    @date_range = (@event.event_start_at.to_date..@event.event_end_at.to_date)
    @attendee_types = AttendeeType.all
    @survey = Survey.includes(:questions).where(event: @event, questions: {question_type_id: 6})
    if attendees.length > 0
      @attendee = attendees.first
    else
      respond_to do |format|
        format.html { redirect_to "/attendees/new_client_attendee" }
      end
    end

  end

  def deliver_app_message
    puts params[:title]
    puts params[:content]
    puts JSON.parse(params[:attendee_data])

    unless params[:title].blank? || params[:content].blank? || JSON.parse(params[:attendee_data]) === "{}"
      attendee          = Attendee.find(params[:attendee_attendee_id])
      recipients        = JSON.parse(params[:attendee_data])
      recipients_string = ""

      recipients.each do |recipient_group_name, type|
        recipients_string += recipient_group_name + ", "
        attendee.cms_send_app_messages(type, recipient_group_name, params[:title], params[:content])
      end
    end

    respond_to do |format|
      if params[:title].blank? || params[:content].blank? || JSON.parse(params[:attendee_data]) === "{}"
        format.html { redirect_to "/attendees/app_message", :alert => "Message title and content cannot be blank. You must have at least one recipient for your message." }
      else
        format.html { redirect_to attendees_url, :notice => "Message successfully sent to #{recipients_string[0...-2]}" }
      end
    end

  end

  def deliver_app_message_v2
    excluded_attendee_ids = params[:data][:excluded_attendee_ids]
    filter_data = params[:data][:filter_data]
    job_id =  SendAppMessageWorker.perform_async(excluded_attendee_ids.to_s,
      filter_data,
      session[:event_id],
      params[:data][:sending_attendee_id],
      params[:data][:title],
      params[:data][:content]
    )
    flash[:notice] = "Message will be sent to all filtered attendees"
    render json: {job_id: job_id}, status: 200
  end

  def filtered_attendee_list
    filter_data = params[:filter_data]
    @attendees = Attendee.where(event_id: session[:event_id])
    if filter_data
      filtered_attendees filter_data
    end
    @total_pages = @attendees.size / 30 + 1
    render partial: 'attendees/filtered_attendees', locals: {attendees: @attendees.limit(30), included_attendee_ids: @attendees.ids, total_pages: @total_pages}
  end

  def search_and_paginate_filtered_attendees
    search_text = params[:data][:search_text]
    excluded_attendee_ids = params[:data][:excluded_attendee_ids]
    filter_data = params[:data][:filter_data]
    @attendees = Attendee.where(event_id: session[:event_id]).where.not(id: excluded_attendee_ids)
    if filter_data
      filtered_attendees filter_data
    end
    @attendees = @attendees.where("attendees.first_name like ? or attendees.last_name like ? or attendees.company like ?",
      "%#{search_text}%", "%#{search_text}%", "%#{search_text}%")
    @total_pages = @attendees.size / 30 + 1
    render partial: 'attendees/filtered_attendees', locals: {attendees: @attendees.paginate(page: params[:data][:page], per_page: 30), included_attendee_ids: @attendees.ids, total_pages: @total_pages}
  end

  def app_message_company_data
    render :json => Attendee.select('distinct company').where("event_id=? AND company IS NOT NULL AND company!=''", session[:event_id]).pluck(:company)
  end

  def app_message_business_units_data
    render :json => Attendee.select('distinct business_unit').where("event_id=? AND business_unit IS NOT NULL AND business_unit!=''", session[:event_id]).pluck(:business_unit)
  end

  def app_message_attendees_data
    render :json => Attendee.where(event_id:session[:event_id]).map { |a| a.first_name + ' ' + a.last_name }
  end

  def app_message_exhibitors_data
    render :json => Exhibitor.where(event_id:session[:event_id]).where.not(company_name: nil).pluck(:company_name).uniq
  end

  def new_client_attendee
    @attendee = Attendee.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @attendee }
    end
  end

  def edit_client_attendee
    @attendee = Attendee.find(params[:id])
  end

  def create_client_attendee
    @attendee = Attendee.new(attendee_params)
    @attendee.event_id = session[:event_id]
    @attendee.attendee_type_id = AttendeeType.where(name:"Client").first.id

    respond_to do |format|
      if @attendee.save
        format.html { redirect_to "/attendees/app_message", notice: 'Client Attendee was successfully created.' }
        format.json { render json: @attendee, status: :created, location: @attendee }
      else
        format.html { render action: "new_client_attendee" }
        format.json { render json: @attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_client_attendee
    @attendee = Attendee.find(params[:id])

    respond_to do |format|
      if @attendee.update!(attendee_params)
        format.html { redirect_to "/attendees/app_message", notice: 'Client Attendee was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit_client_attendee" }
        format.json { render json: @attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  def index
    if (session[:event_id]) then

      @event_id = session[:event_id]
      @event    = Event.select('name').find(@event_id)

      respond_to do |format|
        format.html # index.html.erb
        format.xml {render :xml => @attendees }
        format.json { render json: AttendeesDatatable.new(view_context,@event_id) }
      end

    else
      redirect_to "/home/session_error"
    end

  end

  def show
    @attendee = Attendee.find(params[:id])
    @event_id = session[:event_id]
    # @api_proxy_key = API_PROXY_KEY
    @certificates = CeCertificate.where(event_id: @event_id).to_a

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @attendee }
    end
  end

  def new
    @attendee = Attendee.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @attendee }
    end
  end

  def edit
    @attendee = Attendee.find(params[:id])
  end

  def create
    params[:attendee][:pn_filters] = params[:pn_filters] && params[:pn_filters].length > 0 ? params[:pn_filters].to_s : nil
    params[:attendee][:event_id] = session[:event_id]
    @attendee = Attendee.new(attendee_params)
    @attendee.update_photo(params[:photo_file]) if params[:photo_file]
    @attendee.publish_online(params[:online_url])

    if @attendee.save
      respond_to do |format|
        format.html { redirect_to @attendee, notice: 'Attendee was successfully created.' }
        format.json { render json: @attendee.to_json, status: :created }
      end
    else
      respond_to do |format|
        format.html { render "new" }
        format.json { render json: @attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    processed_filters = PnFilterProcessor.new(session[:event_id])
      .process_filters(
        params[:attendee][:custom_filter_1],
        params[:pn_filters]
      )

    params[:attendee][:pn_filters] =
      unless processed_filters[:updated_filters].blank?
        processed_filters[:updated_filters].to_s
      else
        nil
      end

    @attendee = Attendee.find(params[:id])
    @attendee.update_photo(params[:photo_file]) if params[:photo_file]
    @attendee.publish_online(params[:online_url])

    respond_to do |format|
      if @attendee.update!(attendee_params)
        format.html { redirect_to "/attendees/#{@attendee.id}", notice: 'Attendee was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @attendee = Attendee.find(params[:id])
    attendee_role_id = Role.find_by_name("Attendee").id
    # All the attendees created from registrations (not simple sign-up) will have a user account associatied for devise login
    if !@attendee.user.blank?
      user = @attendee.user
      # Finding the user event and user event role and deleting that.
      users_event     = UsersEvent.where(user_id: user.id, event_id: session[:event_id]).first
      user_event_role = UserEventRole.where(role_id: attendee_role_id, users_event_id: users_event.id).first
      if user_event_role.present?
        user_event_role.delete
      end
      if user.users_roles.length == 1 && user.role_ids.first == attendee_role_id
        user.destroy
      else
        user.users_roles.where(role_id: attendee_role_id).destroy_all
      end
    end
    @attendee.destroy

    respond_to do |format|
      format.html { redirect_to attendees_url }
      format.json { head :ok }
    end
  end

  def destroy_game_and_survey_data_for_attendee
    @attendee = Attendee.find params[:id]
    results = @attendee.destroy_game_and_survey_data
    respond_to do |format|
      format.html {
        redirect_to(
          @attendee,
          notice: results.map {|r| r[0].to_s.titleize + ": " + r[1].to_s }.join('<br>').html_safe
        )
      }
    end
  end

  def delete_all_iattend_data
    u_count = Attendee.where(event_id: session[:event_id]).update_all iattend_sessions: nil

    respond_to do |format|
      format.html { redirect_to( '/dev', notice: "Set #{u_count} attendees iattend_sessions to nil.") }
    end
  end

  def delete_all_recommendations
    s_count = SessionRecommendation.where( event_id: session[:event_id] ).delete_all
    e_count = ExhibitorRecommendation.where( event_id: session[:event_id] ).delete_all

    respond_to do |format|
      format.html { redirect_to( '/dev', notice: "Deleted #{s_count} session recommendations and #{e_count} exhibitor recommendations.") }
    end
  end

  def delete_all_demo_attendees_game_and_survey_data
    results = []
    attendees = Attendee.where is_demo: true, event_id: session[:event_id]
    attendees.each {|a| results << a.destroy_game_and_survey_data }

    # fold all the results into one.
    results = results.each_with_object({}) {|result, memo|
      result.each { |deletion_count|
        memo[deletion_count[0]] = (memo[deletion_count[0]] ||= 0) + deletion_count[1]
      }
      memo
    }
    results[:demo_attendees_affected] = attendees.length.to_s + " " + attendees.map(&:full_name).join(', ')
    respond_to do |format|
      format.html {
        redirect_to(
          '/dev',
          notice: results.map {|r| r[0].to_s.titleize + ": " + r[1].to_s }.join('<br>').html_safe
        )
      }
    end
  end

  def options
  	puts "options method hit"
    if access_allowed?
      puts "access allowed hit"
      set_access_control_headers
      head :ok
    else
      puts "access forbiddon"
      head :forbidden
    end
  end

  def attendee_tags

    @attendee = Attendee.find(params[:id])
    @tagType  = TagType.where(name:params[:tag_type_name])[0]

    #find all the existing tag groups
    @tags_attendee = TagsAttendee
                      .select('attendee_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name')
                      .joins('JOIN tags ON tags_attendees.tag_id=tags.id')
                      .where('attendee_id=? AND tags.tag_type_id=?', @attendee.id, @tagType.id)
    @tag_groups = []

    @tags_attendee.each_with_index do |tag_attendee,i|

      @tag_groups[i] = []

      #add leaf tag
      @tag_groups[i] << tag_attendee.tag_name
      parent_id = tag_attendee.tag_parent_id

      #add ancestor tags, if any
      while (parent_id!=0)
        tag = Tag.where(event_id:session[:event_id],id:parent_id)
        if (tag.length==1) then
          @tag_groups[i] << tag[0].name
          parent_id = tag[0].parent_id
        else
          parent_id=0
        end
      end

      #reverse the order, as we followed the tag tree from leaf to root
      @tag_groups[i].reverse!

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
      format.html { render action:"attendee_tags" }
    end
  end

  def update_attendee_tags
    @attendee     = Attendee.find(params[:id])
    tag_type_name = TagType.find(params[:tag_type_id]).name
		tag_groups    = Tag.assemble_tag_array params

    respond_to do |format|
      if @attendee.update_tags tag_groups, tag_type_name
        format.html { redirect_to("/attendees/#{@attendee.id}/#{tag_type_name}/attendee_tags/", :notice => "#{tag_type_name.capitalize} tags successfully updated.") }
      else
        format.html { redirect_to("/exhibtors/#{@attendee.id}/#{tag_type_name}/attendee_tags/", :notice => "#{tag_type_name.capitalize} tags could not be updated.") }
      end
    end
  end

  def tags_autocomplete
    if params[:term]
      @tags = Tag.where('name LIKE ? AND event_id=?', "%#{params[:term]}%", session[:event_id])
    else
      @tags = Tag.where(event_id:session[:event_id])
    end
    respond_to do |format|
      format.json { render :json => @tags.to_json }
    end
  end

  def bulk_add_attendee_photos
    @event = Event.find session[:event_id]
  end

  def bulk_create_attendee_photos
    @event = Event.find session[:event_id]

    BulkUploadEventFileImage.new(
      event:              @event,
      event_file_type_id: EventFileType.where(name:'attendee_photo')[0].id,
      files:              params[:event_files],
      owner_class:        Attendee,
      owner_assoc:        :photo_event_file_id,
      owner_identifier:   :temp_photo_filename,
      target_path:        Rails.root.join('public', 'event_data', @event.id.to_s, 'attendee_photos'),
      rename_image:       false,
      use_extension_in_identifier: true
    ).call

    respond_to do |format|
      unless @event.errors.full_messages.length > 0
        format.html {
          redirect_to("/attendees/bulk_add_attendee_photos",
          :notice => "#{params[:event_files].inject('') {|m, f| m += "#{f.original_filename} "}} successfully added.")}
      else
        format.html {
          redirect_to("/attendees/bulk_add_attendee_photos",
          :alert => "#{@event.errors.full_messages.inject('') {|m, e| m += "#{e} "}}")}
      end
    end

  end

  def attendee_profile_landing

      proxy_key = params['proxy_key']
      account_code = params['attendee_account_code'].to_s
      event_id = params['event_id']

      @result = {}
      @result["error_messages"] = []

      if (proxy_key == ATTENDEE_PROFILE_PROXY_KEY) then
        attendees = Attendee.where(event_id:event_id, account_code:account_code)
        if (attendees.length == 1)

          @attendee = attendees.first

          redirect_to "/attendees/edit_attendee_profile/#{@attendee.id}"

        elsif (attendees.length == 0)
          @result["error_messages"] << "Error: No attendee exists with account_code #{account_code}"
          puts "no attendee"
          render text:''
        elsif (attendees.length > 1)
          @result["error_messages"] << "Error: Multiple attendees exist with account_code #{account_code}"
          puts "more than one"
          render text:''
        end
      else
        @result["error_messages"] << "Error: Incorrect proxy key"
        puts "Incorrect proxy key"
        render text:''
      end
  end

  def edit_attendee_profile
    @attendee = Attendee.find(params[:id])
    @event_id = @attendee.event_id
    render :layout => 'attendee_profile'
  end


  def update_attendee_profile
    @attendee = Attendee.find(params[:id])
    @event_id = @attendee.event_id
    respond_to do |format|
      if @attendee.update!(attendee_params)
        format.html { render action: "show_attendee_profile", :layout => 'attendee_profile', notice: 'Form was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit_attendee_profile", :layout => 'attendee_profile' }
        format.json { render json: @attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  def show_attendee_profile
    @attendee = Attendee.find(params[:id])
    @event_id = @attendee.event_id
    render :layout => 'attendee_profile'
  end

  def email_attendee_notes
    proxy_key = params['api_proxy_key']
    account_code = params['attendee_account_code']
    event_id = params['event_id']
    email = params['email']

    @result = {}
    @result["status"] = false
    @result["error_messages"] = []
    if (proxy_key == API_PROXY_KEY)

      #lookup attendee
      attendees = Attendee.where(event_id:event_id,account_code:account_code)

      if (attendees.length == 1)

        #set email address
        if attendees[0].update!(notes_email:email,notes_email_pending:1)
          @result["status"]=true

          notes = AttendeeTextUpload.
            select('attendee_text_uploads.*, attendees.email, attendees.business_phone, attendees.mobile_phone').
            where(
              event_id:                     event_id,
              attendee_id:                  attendees[0].id,
              attendee_text_upload_type_id: AttendeeTextUploadType.where(name:"note").first.id ).
            joins('LEFT JOIN attendees ON attendees.id=attendee_text_uploads.target_attendee_id')
          AttendeeMailer.email_notes(email,Event.find(event_id),notes).deliver
          attendees[0].update!(notes_email_pending:0)
        end
      elsif (attendees.length == 0)
        @result["error_messages"] << "Error: No attendee exists with account_code #{account_code}"
      elsif (attendees.length > 1)
        @result["error_messages"] << "Error: Multiple attendees exist with account_code #{account_code}"
      end
    else
      @result["error_messages"] << "Error: Incorrect proxy key."
    end
    render :json => @result.to_json
  end

  def daily_checkup_attendees
    @event = Event.find session[:event_id]
    start_date = @event.event_start_at.to_date
    last_date = @event.event_end_at.to_date > Date.today ? Date.today : @event.event_end_at.to_date
    @dates = (start_date..last_date).to_a
    @surveys = Survey.where("surveys.event_id = ? and surveys.survey_type_id = 7", session[:event_id]).distinct
    # @options = []
    # @surveys.each do |survey|
    #   @response_dates.each do |response_date|
    #     option = ["#{survey.title.truncate(20)} #{response_date.to_date.to_s}", {survey_id: survey.id, response_date: response_date}]
    #     @options.push option
    #   end
    # end
  end

  def get_survey_responses
    survey_id = params[:survey_id]
    response_date = params[:date]
    if params[:attendance_status].eql?('true')
      @survey = Survey.find_by_id(params[:survey_id])
      @attendee_ids = SurveyResponse.joins(:survey)
      .where('survey_responses.event_id = ? and survey_responses.survey_id = ? and surveys.survey_type_id = 7 and date(survey_responses.updated_at) = ?',
      session[:event_id], survey_id, response_date).pluck(:attendee_id)
      @attendees = Attendee.where(id: @attendee_ids)
      .where("first_name like ? or last_name like ? or email like ?", "%#{params[:search_text]}%", "%#{params[:search_text]}%", "%#{params[:search_text]}%")
      @total_pages = @attendees.size / 30
      @attendees = @attendees.paginated_data(page: params[:page], per_page: 30)
      @report_data = []
      @attendees.each do |attendee|
        question_response_pairs = @survey.questions.map do |question|
          response = Response.joins(:survey_response).where("responses.question_id = ? and survey_responses.attendee_id = ? and survey_responses.survey_id = ?", question.id, attendee.id, survey_id).first
          { question: question.question,
            response: response&.answer&.answer
          }
        end
        @report_data.push({ attendee_name: attendee.full_name,
          attendee_email: attendee.email,
          attendee_phone: attendee.mobile_phone,
          response_data: question_response_pairs
        })
      end
      render partial: 'attendee_responses', locals: { report_data: @report_data, total_pages: @total_pages }
    else
      @attendee_ids = SurveyResponse.joins(:survey)
      .where('survey_responses.event_id = ? and survey_responses.survey_id = ? and surveys.survey_type_id = 7 and date(survey_responses.updated_at) = ?', session[:event_id], survey_id, response_date).pluck(:attendee_id)
      @attendees = Attendee.where.not(id: @attendee_ids).where(event_id: session[:event_id])
      .where("first_name like ? or last_name like ? or email like ?", "%#{params[:search_text]}%", "%#{params[:search_text]}%", "%#{params[:search_text]}%")
      .order(:first_name)
      @total_pages = @attendees.size / 30
      @attendees = @attendees.paginated_data(page: params[:page], per_page: 30)
      render partial: 'attendee_incomplete_response', locals: {attendees: @attendees, total_pages: @total_pages}
    end
  end

  def purchased
    @attendee_products = AttendeeProduct.includes(:attendee, :product, :order).where(attendee: {event_id: session[:event_id]})
  end

  def send_calender_invite
    settings = Setting.return_cached_settings_for_registration_portal({ event_id: session[:event_id] })
    attendee = Attendee.find_by(id: params[:id])
    settings.send_calendar_invite && CalendarInviteMailer.invite(session[:event_id], attendee, settings.attach_calendar_invite).deliver_now if attendee
  end

  private

  def get_client_attendees
    type_id = AttendeeType.where(name:"Client").first.id
    return Attendee.where(event_id:session[:event_id],attendee_type_id:type_id)
  end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*' # request.env['HTTP_ORIGIN']
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = '1000'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,x-requested-by,Content-Type'
  end

  def access_allowed?
    return true
    #allowed_sites = [request.env['HTTP_ORIGIN']] #you might query the DB or something, this is just an example
    #return allowed_sites.include?(request.env['HTTP_ORIGIN'])
  end

  def formatted_duration(total_seconds)
    hrs = 0
    mins = 0
    secs = 0
    if total_seconds > 3600
      hrs = (total_seconds / 3600).to_i
      total_seconds = total_seconds % 3600
    end
    if total_seconds > 60
      mins = (total_seconds / 60).to_i
      total_seconds = total_seconds % 60
    end
    if total_seconds > 0
      secs = total_seconds.to_i
    end
    return "#{hrs}:#{mins}:#{secs}"
  end

  def get_local_time(time)
		t_offset = @event.utc_offset
		if (t_offset==nil) then
			t_offset = "+00:00" #default to UTC 0
    end
    return time.localtime(t_offset).strftime("%H:%M:%S")
  end

  helper_method :formatted_duration, :get_local_time

  def attendee_params
    params.require(:attendee).permit(:event_id, :is_demo, :first_name, :last_name, :honor_prefix, :honor_suffix, :title, :company, :biography, :business_unit, :business_phone, :mobile_phone, :country, :state, :city, :email, :notes_email, :notes_email_pending, :temp_photo_filename, :photo_filename, :photo_event_file_id, :account_code, :iattend_sessions, :assignment, :validar_url, :publish, :twitter_url, :facebook_url, :linked_in, :username, :password, :authy_id, :attendee_type_id, :messaging_opt_out, :messaging_notifications_opt_out, :app_listing_opt_out, :game_opt_out, :first_run_toggle, :video_portal_first_run_toggle, :custom_filter_1, :custom_filter_2, :custom_filter_3, :pn_filters, :token, :tags_safeguard, :speaker_biography, :custom_fields_1, :survey_results, :travel_info, :table_assignment, :custom_fields_2, :custom_fields_3, :premium_member, :exhibitor_checkin, :badge_name)
  end

  def filtered_attendees filter_data
    if filter_data[:incomplete_survey_attendees_date] && filter_data[:incomplete_survey_attendees_date].length > 0
      completed_survey_attendee_ids = SurveyResponse.joins(:survey).where(event_id: session[:event_id], local_date: filter_data[:incomplete_survey_attendees_date])
      .where('surveys.survey_type_id = 7').pluck(:attendee_id)
      @attendees = @attendees.where.not(id: completed_survey_attendee_ids)
    end
    if filter_data[:attendee] && filter_data[:attendee].length > 0
      @attendees = @attendees.where("CONCAT(first_name, ' ', last_name) in (#{filter_data[:attendee].map {|el| "'" + el + "'" }.join(",")})")
    end
    if filter_data[:business_unit] && filter_data[:business_unit].length > 0
      @attendees = @attendees.where(business_unit: filter_data[:business_unit])
    end
    if filter_data[:company] && filter_data[:company].length > 0
      @attendees = @attendees.where(company: filter_data[:company])
    end

    if filter_data[:attendee_type] && filter_data[:attendee_type].length > 0
      @attendees = @attendees.where(attendee_type_id: filter_data[:attendee_type])
    end

    if filter_data[:survey]
      question_ids = Question.where(survey_id: filter_data[:survey].to_i,question_type_id: 6).ids
      response = Response.joins(survey_response: :survey).select("survey_responses.attendee_id as attendee").where(survey: {id: filter_data[:survey].to_i}, question_id: question_ids)
      survey_attend_attendee_ids = response.map(&:attendee)
      @attendees = @attendees.where(event_id: event_id).where.not(id: survey_attend_attendee_ids).order(:first_name)
    end
  end

end
