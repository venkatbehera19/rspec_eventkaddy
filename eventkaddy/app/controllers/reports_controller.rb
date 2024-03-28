class ReportsController < ApplicationController

  # program grid should be public, so don't check authorization
  before_action :authorization_check, except: [:avma_program_grid, :exhibitor_surveys_report, :exhibitor_uncompleted_surveys_report, :video_visits_report]
  def cordova_report
    @event    = Event.find session[:event_id]
    @event_id = @event.id
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_app_report.xlsx"
    job_or_template_report 'Download App Report', '/reports/cordova_report'
  end

  def exhibitor_leads_report
    @event    = Event.find session[:event_id]
    @event_id = @event.id
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_exhibitor_leads_report.xlsx"
    job_or_template_report 'Download Exhibitor Lead Report', '/reports/exhibitor_leads_report'

  end

  def exhibitors_scan_report
     @event    = Event.find session[:event_id]
     @event_id = @event.id
     @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_exhibitors_scan_report.xlsx"
     job_or_template_report 'Download Exhibitor Scan Report', '/reports/exhibitors_scan_report'
   end

  def exhibitor_surveys_report
    authorize! :exhibitor_surveys_report, :all
    @event          = Event.find session[:event_id]
    @event_id       = @event.id
    @exhibitor_id   = params[:exhibitor_id]
    @exhibitor     = Exhibitor.find @exhibitor_id
    @filename       = "#{@event.name.downcase.gsub(/\s/,"_")}_#{@exhibitor.company_name}_exhibitor_surveys_report.xlsx"
    #@filename       = "#{@event.name.downcase.gsub(/\s/,"_")}_exhibitor_surveys_report.xlsx"
    job_or_template_report 'Download Exhibitor Surveys Report', '/reports/exhibitor_surveys_report'

  end

  def video_visits_report
    authorize! :video_visits_report, :all
    @event          = Event.find session[:event_id]
    @primary_db     = primary_db
    @event_id       = @event.id
    @email_not_showed   = Setting.where(event_id: session[:event_id], 
      setting_type_id: SettingType.find_by_name('cms_settings').id).first.json['hide_exhibitor_portal_attendee_email']
    @exhibitor_id   = params[:exhibitor_id]
    @filename       = "#{@event.name.downcase.gsub(/\s/,"_")}_video_visits_report.xlsx"
    job_or_template_report 'Download Video Visits Report', '/reports/video_visits_report', {primary_db: @primary_db }
  end

  def exhibitor_uncompleted_surveys_report
    authorize! :exhibitor_uncompleted_surveys_report, :all
    @event          = Event.find session[:event_id]
    @event_id       = @event.id
    @exhibitor_id   = params[:exhibitor_id]
    @exhibitor      = Exhibitor.find(@exhibitor_id)
    @filename       = "#{@exhibitor.company_name.downcase.gsub(/\s/,"_")}_uncompleted_surveys_report.xlsx"
    job_or_template_report 'Download Uncompleted Exhibitor Surveys Report', '/reports/exhibitor_uncompleted_surveys_report'
  end

  # per attendee show the sessions they have attended
  def iattend_scans_by_attendee_report
    @event    = Event.find session[:event_id]
    @event_id = @event.id
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_iattend_scans_by_attendee_report.xlsx"
    job_or_template_report 'Download iAttend Scans By Attendee Report', '/reports/iattend_scans_by_attendee_report'
  end

  # without concatonated columns
  def iattend_scans_by_attendee_report_v2
    @event    = Event.find session[:event_id]
    @event_id = @event.id
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_iattend_scans_by_attendee_report_v2.xlsx"
    job_or_template_report 'Download iAttend Scans By Attendee Report Version 2', '/reports/iattend_scans_by_attendee_report_v2'
  end

  def iattend_scans_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_iattend_scans_report.xlsx"
    job_or_template_report 'Download iAttend Scans Report', '/reports/iattend_scans_report'
  end

  def download_attendees
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_attendee_data.xlsx"
    job_or_template_report 'Download Attendees', '/events/download_attendees'
  end

  def download_speakers
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_speaker_data.xlsx"
    job_or_template_report 'Download Speakers', '/events/download_speakers'
  end

  def download_exhibitors
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_exhibitor_data.xlsx"
    job_or_template_report 'Download Exhibitors', '/events/download_exhibitors'
  end

  def full_leaderboard_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_full_leaderboard_report.xlsx"
    job_or_template_report 'Download Full Leaderboard Report', '/events/full_leaderboard_report'
  end

  def attendee_per_row_game_stats_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_attendee_per_row_game_stats_report.xlsx"
    job_or_template_report 'Download Attendee Per Row Game Stats Report', '/events/attendee_per_row_game_stats_report'
  end

  def game_stats_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_game_stats_report.xlsx"
    job_or_template_report 'Download Game Stats Report', '/reports/game_stats_report'
  end

  def session_files_summary_conference_note
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_session_files_summary.xlsx"
    job_or_template_report 'Download Session Files Summary', '/session_files/spreadsheet_summary', {type_name: params[:type] || 'conference note' }
  end

  def exhibitor_products_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_exhibitor_products_report.xlsx"
    job_or_template_report 'Download Exhibitor Products Report', '/exhibitor_products/exhibitor_products_report'
  end

  def download_logins
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_app_login_data.xlsx"
    job_or_template_report 'Download App Logins Report', '/events/download_logins'
  end

  def download_reporting_logins
    @event    = Event.find session[:event_id]
    @primary_db = primary_db
    @event_id = @event.id
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_virtual_platform_login_data.xlsx"
    job_or_template_report 'Download Virtual Platform Logins Report', '/events/download_reporting_logins', {primary_db: @primary_db }
  end

  def attendee_report
    @event    = Event.find session[:event_id]
    @primary_db = primary_db
    @title    = "Attendee Report"
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_attendee_report.xlsx"
    job_or_simple_report 'Download Attendee Report', 'attendee_report_data'
  end

  def self.attendee_report_data event_id, job=false
    query_stage job
    data = Attendee.where(event_id: event_id)
    processing_stage job, data
		data.map {|attendee|

			sessions_favourited   = ''
			exhibitors_favourited = ''

			if attendee.sessions.length > 0
				attendee.sessions.each_with_index do |session,i|
					unless (i+1)===attendee.sessions.length
						sessions_favourited += "#{session.session_code},"
					else
						sessions_favourited += "#{session.session_code}"
					end
				end
			end

			if attendee.exhibitors.length > 0
				attendee.exhibitors.each_with_index do |exhibitor,i|
					unless (i+1)===attendee.exhibitors.length
						exhibitors_favourited += "#{exhibitor.company_name},"
					else
						exhibitors_favourited += "#{exhibitor.company_name}"
					end
				end
			end

			attendeename = "#{attendee.honor_prefix} #{attendee.first_name} #{attendee.last_name} #{attendee.honor_suffix}"

      iteration_stage job, [attendeename, attendee.title, attendee.iattend_sessions,sessions_favourited,exhibitors_favourited]
    }.unshift(['Attendee Name', 'Attendee Title', 'Sessions Attended','Favourited Sessions','Favourited Exhibitors'])
  end

  def attendee_profile_report
    @event    = Event.find session[:event_id]
    @title    = "Attendee Profile Report"
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_attendee_profile_report.xlsx"
    job_or_simple_report 'Download Attendee Profile Report', 'attendee_profile_report_data'
  end

  #produced for AVMA 2018
  def self.attendee_profile_report_data event_id, job=false
    query_stage job
    data = Attendee.where(event_id: event_id)
    processing_stage job, data
    data.map {|attendee|

      ce_state_value = ''
      first_time_attendee = ''
      time_veterinary_medicine = ''
      avma_dues = ''
      
      if attendee.custom_fields_1 != nil 
        profile_fields = JSON.parse(attendee.custom_fields_1)

        profile_fields.each do |p|
          case p["title"]
          when "ce_state_value"
            ce_state_value = p["value"]
          when "first_time_attendee"
            first_time_attendee = p["value"]
          when "time_veterinary_medicine"
            time_veterinary_medicine = p["value"]
          when "avma_dues"
            avma_dues = p["value"]
          end
        end
      end

      iteration_stage job, [attendee.first_name,attendee.last_name,attendee.email,attendee.notes_email,attendee.state,attendee.account_code,attendee.custom_filter_1,attendee.custom_filter_2,ce_state_value,first_time_attendee,time_veterinary_medicine,avma_dues]
    }.unshift(['First Name','Last Name','Email','Notes Email','State','Account Code', 'Attendee Type', 'Registration Type','CE State Value', 'First Time Attendee?', 'Time Spent in Veterinary Medicine', 'AVMA Dues Opinion'])
  end

  def exhibitors_report
    @event    = Event.find session[:event_id]
    @title    = "Exhibitors Report"
    @filename =  "#{@event.name.downcase.gsub(/\s/,"_")}_exhibitors_report.xlsx"
    job_or_simple_report 'Download Exhibitors Report', 'exhibitors_report_data'
  end

  def self.exhibitors_report_data event_id, job=false
    query_stage job
    data = Exhibitor.where(event_id:event_id)
    processing_stage job, data
		data.map {|e|
			user_email     = e.user ? e.user.email : ''
      exhibitor_logo = e.event_file ? "#{e.event.master_url}#{e.event_file.path}" : ''

      iteration_stage job, [e.company_name,e.contact_name,user_email,e.email,e.description,exhibitor_logo,e.address_line1,e.address_line2,e.city,e.zip,e.state,e.country,e.phone,e.fax,e.url_web,e.url_twitter,e.url_facebook,e.url_linkedin,e.url_rss,e.message,e.is_sponsor,e.toll_free]
    }.unshift( ['Company Name','Contact Name','User Email','Exhibitor Email','Description','Logo','Address Line 1','Address Line 2','City','ZIP','State','Country','Phone','Fax','URL Web','URL Twitter','URL Facebook','URL LinkedIn','URL RSS','Message','Is Sponsor','Toll Free'])
  end

  def speaker_report
    @event    = Event.find session[:event_id]
    @title    = "Speakers Summary"
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_speaker_report.xlsx"
    job_or_simple_report 'Download Speaker Report', 'speaker_report_data'
  end

  def self.speaker_report_data event_id, job=false
    query_stage job

    data = Speaker.where(event_id:event_id)
    processing_stage job, data
		data.map {|s|

			speaker_files  = ''
			speaker_photo  = ''
			session_codes  = ''


			s.speaker_files.each do |file|
				if file.event_file!=nil && s.event.master_url!=nil
					speaker_files += "#{s.event.master_url}/speaker_portals/downloads/#{file.id} | "
				end
			end

			if s.event_file_photo!=nil && s.event.master_url!=nil
				speaker_photo += "#{s.event.master_url}"+s.event_file_photo.path+""
			end

  		s.sessions.each_with_index do |session, i|
  			unless (i+1)===s.sessions.length
					session_codes += "#{session.session_code}, "
  			else
					session_codes += "#{session.session_code}"
  			end
  		end


      if (!(s.speaker_travel_detail.nil?) && !(s.speaker_payment_detail.nil?))
	  			iteration_stage job, [s.id,s.honor_prefix,s.first_name,s.middle_initial,s.last_name,s.honor_suffix,session_codes,s.email,s.fd_tax_id,s.fd_pay_to,s.fd_street_address,s.fd_city,s.fd_state,s.fd_zip,s.speaker_payment_detail.pay_to_line1,s.speaker_payment_detail.pay_to_line2,s.speaker_payment_detail.direct_bill_travel,s.speaker_payment_detail.direct_bill_housing,s.speaker_payment_detail.eligible_housing_nights,s.speaker_payment_detail.payment_type,s.speaker_payment_detail.eligible_payment_rate,s.speaker_payment_detail.total_honorarium,s.speaker_payment_detail.total_per_diem,s.speaker_travel_detail.approved_arrival_date,s.speaker_travel_detail.approved_departure_date,s.speaker_travel_detail.actual_arrival_date,s.speaker_travel_detail.actual_departure_date,s.speaker_travel_detail.hotel_name,s.speaker_travel_detail.hotel_confirmation_number,s.speaker_travel_detail.hotel_cost,s.speaker_travel_detail.hotel_reimbursement,s.speaker_travel_detail.airfare_cost,s.speaker_travel_detail.airfare_reimbursement,s.speaker_travel_detail.mileage,s.speaker_travel_detail.comments,s.company,s.address1,s.address2,s.address3,s.city,s.state,s.zip,s.country,s.work_phone,s.fax,s.mobile_phone,s.home_phone,s.biography,speaker_files,speaker_photo,s.updated_at]

	  		elsif !(s.speaker_travel_detail.nil?)
          iteration_stage job, [s.id,s.honor_prefix,s.first_name,s.middle_initial,s.last_name,s.honor_suffix,session_codes,s.email,s.fd_tax_id,s.fd_pay_to,s.fd_street_address,s.fd_city,s.fd_state,s.fd_zip,"Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available",s.speaker_travel_detail.approved_arrival_date,s.speaker_travel_detail.approved_departure_date,s.speaker_travel_detail.actual_arrival_date,s.speaker_travel_detail.actual_departure_date,s.speaker_travel_detail.hotel_name,s.speaker_travel_detail.hotel_confirmation_number,s.speaker_travel_detail.hotel_cost,s.speaker_travel_detail.hotel_reimbursement,s.speaker_travel_detail.airfare_cost,s.speaker_travel_detail.airfare_reimbursement,s.speaker_travel_detail.mileage,s.speaker_travel_detail.comments,s.company,s.address1,s.address2,s.address3,s.city,s.state,s.zip,s.country,s.work_phone,s.fax,s.mobile_phone,s.home_phone,s.biography,speaker_files,speaker_photo,s.updated_at]

       	elsif !(s.speaker_payment_detail.nil?)
	  			iteration_stage job, [s.id,s.honor_prefix,s.first_name,s.middle_initial,s.last_name,s.honor_suffix,session_codes,s.email,s.fd_tax_id,s.fd_pay_to,s.fd_street_address,s.fd_city,s.fd_state,s.fd_zip,s.speaker_payment_detail.pay_to_line1,s.speaker_payment_detail.pay_to_line2,s.speaker_payment_detail.direct_bill_travel,s.speaker_payment_detail.direct_bill_housing,s.speaker_payment_detail.eligible_housing_nights,s.speaker_payment_detail.payment_type,s.speaker_payment_detail.eligible_payment_rate,s.speaker_payment_detail.total_honorarium,s.speaker_payment_detail.total_per_diem,"Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available",s.company,s.address1,s.address2,s.address3,s.city,s.state,s.zip,s.country,s.work_phone,s.fax,s.mobile_phone,s.home_phone,s.biography,speaker_files,speaker_photo,s.updated_at]

	  		else
	  			iteration_stage job, [s.id,s.honor_prefix,s.first_name,s.middle_initial,s.last_name,s.honor_suffix,session_codes,s.email,s.fd_tax_id,s.fd_pay_to,s.fd_street_address,s.fd_city,s.fd_state,s.fd_zip,"Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available","Not available",s.company,s.address1,s.address2,s.address3,s.city,s.state,s.zip,s.country,s.work_phone,s.fax,s.mobile_phone,s.home_phone,s.biography,speaker_files,speaker_photo,s.updated_at]
	  		end
    }.unshift(['Speaker_ID', 'Title','First Name','Initial', 'Last Name', 'Degree W. Diploma Status', 'Session Codes', 'Email', 'Tax ID', 'FD Pay To', 'FD Street Address', 'FD City', 'FD State', 'FD Zip', 'Pay to Line', 'Pay to Line 2', 'Direct Bill Travel', 'Direct Bill Housing', 'Eligible Housing Nights', 'Payment Type', 'Eligible Payment Rate', 'Total Honorarium', 'Total Per Diem', 'Approved Arrival Date', 'Approved Departure Date', 'Actual Arrival Date', 'Actual Departure Date', 'Hotel Name', 'Hotel Confirmation Number', 'Hotel Cost', 'Hotel Reimbursement', 'Airfare Cost', 'Airfare Reimbursement', 'Mileage', 'Comments', 'Organization', 'Address 1', 'Address 2', 'Address 3', 'City', 'State', 'Zip', 'Country', 'Work', 'Fax', 'Mobile', 'Home', 'Biography', 'Speaker Files', 'Speaker Photo Path', 'Updated At'])
  end

  def sessions_av_report
    @event    = Event.find session[:event_id]
    @title    = "AV Request Report"
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_av_report.xlsx"
    job_or_simple_report 'Download Sessions AV Report', 'sessions_av_report_data'
  end

  def self.sessions_av_report_data event_id, job=false
    query_stage job

    sessions = Session.where(event_id: event_id)

    processing_stage job, sessions

		sessions.map {|session|

      # this should probably also be replaced with a method call to the model.
      # But for now since I have no test data to conveniently work with, I'll
      # leave it
			item         = ''
			item_notes   = ''
			date_updated = ''

  		session.session_av_requirements.each_with_index do |requirement, i|
  			unless (i+1)===session.session_av_requirements.length
					item         += "#{requirement.av_list_item.name} |"
					item_notes   += "#{requirement.additional_notes} |"
					date_updated += "#{requirement.updated_at} |"
  			else
					item         += "#{requirement.av_list_item.name}"
					item_notes   += "#{requirement.additional_notes}"
					date_updated += "#{requirement.updated_at}"
  			end
  		end

      iteration_stage job, [session.session_code,session.title,session.date,session.start_at_formatted,session.end_at_formatted,session.room_name,session.all_speaker_names,session.all_speaker_emails,item,item_notes,date_updated]
    }.unshift(['Session Code', 'Title', 'Date', 'Start', 'End', 'Room','Speakers','Speaker Emails','Additional Item & AV','Item & AV Notes','Updated At'])
  end

  def download_qa
    @event    = Event.find session[:event_id]
    @title    = "Questions And Answers Data"
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_qa_data.xlsx"
    job_or_simple_report 'Download Questions and Answers Data Report', 'download_qa_data'
  end

  def self.download_qa_data event_id, job=false
    query_stage job

    type_id = AttendeeTextUploadType.where(name:"q&a").first.id
    text_uploads = AttendeeTextUpload.
      select('attendee_text_uploads.id,
              attendee_text_uploads.attendee_id,
              attendee_text_uploads.text AS question,
              attendee_text_uploads.answer AS answer,
              attendee_text_uploads.created_at AS asked_at,
              attendee_text_upload_type_id,
              CONCAT( attendees.first_name, " ", attendees.last_name ) AS asked_by,
              sessions.start_at AS start_at,
              sessions.end_at AS end_at,
              sessions.date AS date,
              sessions.session_code AS session_code,
              sessions.title AS session_title,
              sessions.id AS session_id').
      joins('LEFT OUTER JOIN attendees ON attendee_text_uploads.attendee_id=attendees.id').
      joins('JOIN sessions ON attendee_text_uploads.session_id=sessions.id').
      where(event_id: event_id, attendee_text_upload_type_id: type_id)
      .map { |text_upload|
        [
          text_upload[:session_code],
          text_upload[:session_title],
          text_upload[:date],
          text_upload.start_at ? text_upload.start_at.to_s.split(' ')[1] : nil,
          text_upload.end_at ? text_upload.end_at.to_s.split(' ')[1] : nil ,
          Session.find( text_upload.session_id ).all_speaker_names,
          text_upload[:question],
          text_upload[:answer],
          text_upload[:asked_by],
          text_upload[:asked_at]
        ]
      }
    
    text_uploads.map {|t|
      iteration_stage(
        job, t
      )
    }.unshift([ 'Session Code', 'Session Title', 'Date', 'Start At', 'End At', 'Speakers', 'Question', 'Answer', 'Asked By', 'Asked At' ])
  end

  def feedbacks_summary
    @event    = Event.find session[:event_id]
    @title    = "Feedbacks Summary"
    @filename = "#{Event.find(session[:event_id]).name.downcase.gsub(/\s/,"_")}_feedback_summary.xlsx"
    job_or_simple_report 'Download Feedbacks Summary Report', 'feedbacks_summary_data'
  end

  def self.feedbacks_summary_data event_id, job=false
    if job
      job.update!(status:'Fetching Rows From Database')
      job.write_to_file
    end
    feedbacks = Feedback.
      select('feedbacks.*, sessions.title AS session_title, sessions.session_code AS session_code, sessions.id AS session_id, speakers.first_name AS speaker_first_name, speakers.last_name AS speaker_last_name, attendees.first_name AS attendee_first_name, attendees.last_name AS attendee_last_name').
      joins('JOIN sessions ON sessions.id=feedbacks.session_id LEFT JOIN speakers ON speakers.id=feedbacks.speaker_id LEFT JOIN attendees ON attendees.id=feedbacks.attendee_id').
      where("feedbacks.event_id=? AND feedbacks.created_at>='2015-04-19 00:00:00'", event_id).
      order('session_title')

    if job
      job.update!(total_rows: feedbacks.length, status:'Processing Rows')
      job.write_to_file
    end

	  feedbacks.map {|feedback|
      type          = feedback.speaker_id ? 'Delivery Rating' : 'Content Rating'
      rating        = feedback.rating != -1 ? feedback.rating : ''
      speaker_name  = type == 'Delivery Rating' ?  "#{feedback.speaker_first_name} #{feedback.speaker_last_name}" : Session.find(feedback.session_id).all_speaker_names
      attendee_name = "#{feedback.attendee_first_name} #{feedback.attendee_last_name}"
      row = [ feedback.session_code, attendee_name, feedback.session_title, speaker_name, type, rating, feedback.comment ]
      job.plus_one_row if job
      row
    }.unshift(['Session Code', 'Attendee Name', 'Session Title', 'Speaker Name', 'Rating Type', 'Rating', 'Comment'])
  end

  def sessions_and_speakers_feedback
    @event    = Event.find session[:event_id]
    @title    = "Feedback Results"
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_sessions_and_speakers_feedback.xlsx"
    job_or_simple_report 'Download Feedback Report', 'sessions_and_speakers_feedback_data'
  end

  def self.sessions_and_speakers_feedback_data event_id, job=false
    if job
      job.update!(status:'Fetching Rows From Database')
      job.write_to_file
    end
    speakers = Speaker.array_of_speakers_with_ratings_per_session event_id
    sessions = Session.array_of_sessions_with_ratings event_id

    job.update!(total_rows: speakers.length, status:'Processing Rows') if job

    speakers.map {|speaker|

      session = sessions.select {|session| session['id'] == speaker['session_id']}[0]

      session_rating = session['rating'].blank? ? 'Unrated' : sprintf('%.2f', session['rating'])
      speaker_rating = speaker['rating'].blank? ? 'Unrated' : sprintf('%.2f', speaker['rating'])
      overall_rating = session['overall_rating'].blank? ? '' : sprintf('%.2f', session['overall_rating'])

      row = [
        session['session_code'], session['title'],
        speaker['first_name'], speaker['last_name'], speaker['email'],
        speaker_rating, session_rating, overall_rating
      ]
      job.plus_one_row if job
      row
    }.unshift([ 'Session Code', 'Session Title', 'Speaker First Name', 'Speaker Last Name', 'Speaker Email', 'Delivery Score', 'Content Score', 'Overall Score'])
  end

  def sessions_report
    @event    = Event.find session[:event_id]
    @title    = "Feedback Results"
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_sessions_report.xlsx"
    job_or_simple_report 'Download Sessions Report', 'sessions_report_data'
  end

  def self.sessions_report_data event_id, job=false
    if job
      job.update!(status:'Fetching Rows From Database')
      job.write_to_file
    end

    # TODO: if we reboot the trackowners portal, this would have to be updated,
    # which is a little complicated because the query is quite involved and
    # uses find_by_sql, so it's not as easy to just tack trackowner.sessions to
    # the start of it
    sessions = Session.sessions_report_data(event_id)
    session_fav_counts = SessionsAttendee.favourite_counts_by_session_code event_id

    job.update!(total_rows: sessions.length, status:'Processing Rows') if job

    sessions.map {|s|
      row = [
        s.session_code, s.title, s.speaker_names, s.speaker_companies, s.speaker_emails, s.description,
        (s.date && s.date.strftime('%F') || ''), return_time_value( s.start_at ), return_time_value( s.end_at ),
        s.location_name, s.av_requirement_names, s.av_requirement_notes,
        s.tags_string, s.audience_tags_string,
        s.program_type_name, s.credit_hours, s.exhibitor_names, s.price, s.capacity,
        session_fav_counts.delete( s.session_code.to_s ) || 0,
        s.updated_at
      ]
      job.plus_one_row if job
      row
    }.unshift([ 'Session Code', 'Title', 'Speakers', 'Speaker Organizations', 'Speaker Emails', 'Description', 'Date', 'Start Time', 'End Time', 'Room', 'Item', 'AV Notes', 'Session Tags', 'Audience Tags', 'Program Type', 'Credit Hours', 'Sponsor', 'Price', 'Capacity', 'Attendee Favourites', 'Updated At' ])
  end

  def basic_session_favourite_info
      # SessionsAttendee.
      #   select('session_code, COUNT( session_id ) AS fav_count').
      #   where(session_id: Session.where(event_id: params[:event_id], date: params[:date]).pluck(:id)).
      #   group(:session_code).
      #   order("fav_count DESC").
      #   map {|s| [ s.session_code, s.fav_count ] }


    codes = SessionsAttendee.
      select('CONCAT( sessions_attendees.session_code, "<br>", location_mappings.name, "<br>", sessions.title, "<br><br>") AS name').
      joins('LEFT OUTER JOIN sessions ON sessions.id=session_id').
      joins('LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id').
      where(session_id: Session.where(event_id: params[:event_id], date: params[:date]).pluck(:id)).
      map {|s| s.name}

    render :text => simple_table_page(
        codes.uniq.map{|code| [ code, codes.count(code) ] }.sort {|x,y| y[1] <=> x[1] }
    )
  end

  def all_badges_completed_leaderboard_report
    @event         = Event.find session[:event_id]
    @title         = "Leaderboard Report"
    @filename      = "#{@event.name.downcase.gsub(/\s/,"_")}_all_badges_leaderboard_report.xlsx"
    @column_widths = [20, 20, 80]
    job_or_simple_report 'Download All Badges Leaderboard Report', 'all_badges_completed_leaderboard_report_data'
  end

  def self.all_badges_completed_leaderboard_report_data event_id, job=false
    data = AttendeesAppBadge.leaderboard_by_all_badges_completed_time( event_id )
    job.update!(total_rows: data.length, status:'Processing Rows') if job

    data.map {|a|
      job.plus_one_row if job
      ["#{ a.account_code } ", a.name, a.most_recent_update.strftime('%F %T')]
    }.unshift( ["Account Code", "Name", "Most Recent Updated Badge (Time Completed All Badges)"])
  end

  def exhibitor_attendee_report
    @event    = Event.find session[:event_id]
    @title    = "Exhibitor-Attendee Summary"
    @filename = "#{@event.name}_exhibitor_attendee_report.xlsx"
    job_or_simple_report 'Download Exhibitor Attendees Report', 'exhibitor_attendee_report_data'
  end

  def self.exhibitor_attendee_report_data event_id, job=false
    query_stage job

    data = Exhibitor.select('*, attendees.account_code, attendees.first_name, attendees.last_name, attendees.username, attendees.title').
      joins('LEFT JOIN booth_owners ON booth_owners.exhibitor_id = exhibitors.id').
      joins('LEFT JOIN attendees ON attendees.id = booth_owners.attendee_id').
      where('exhibitors.event_id=? AND attendees.username IS NOT NULL', event_id).
      order('company_name DESC')

    processing_stage job, data

    data.map {|e|
      iteration_stage job, [e.exhibitor_code, e.company_name, e.contact_name, e.account_code, e.first_name, e.last_name, e.username]
    }.unshift(
      ["Exhibitor Code", "Exhibitor Company Name", "Exhibitor Contact Name", "Attendee Account Code", "Attendee First Name", "Attendee Last Name", "Attendee Username", "Attendee Title"]
    )
  end

  def avma_program_grid
    @event = Event.find params[:event_id]
    @title =  "Program Grid"
    headers = ["SESSION CODE", "SPONSOR", "SESSION TITLE", "AUDIENCE", "DATE", "START TIME", "END TIME", "ROOM NUMBER", "Type", "Topic", "Subtopic", "CE CREDITS", "SPEAKERS"]
    @column_widths = headers.map {|h| 20}
    @column_widths[2] = 80
    @data = Session.
      select('session_code, sessions.title, date, start_at, end_at, track_subtrack, credit_hours, GROUP_CONCAT( exhibitors.company_name ) AS sponsors_output, location_mappings.name AS location_mapping_name, GROUP_CONCAT( DISTINCT tags.name) AS audience_tags, GROUP_CONCAT( DISTINCT CONCAT(speakers.first_name, " ", speakers.last_name) ) AS speaker_names').
      joins('LEFT JOIN sessions_sponsors ON sessions_sponsors.session_id = sessions.id').
      joins('LEFT JOIN exhibitors ON sessions_sponsors.sponsor_id = exhibitors.id').
      joins('LEFT JOIN location_mappings ON location_mappings.id = sessions.location_mapping_id').
      joins('LEFT JOIN tags_sessions ON tags_sessions.session_id = sessions.id').
      joins('LEFT JOIN tags ON tags.id = tags_sessions.tag_id AND tags.tag_type_id=3').
      joins('LEFT JOIN sessions_speakers ON sessions_speakers.session_id = sessions.id').
      joins('LEFT JOIN speakers ON speakers.id = sessions_speakers.speaker_id').
      where(event_id:params[:event_id]).
      where('sessions.unpublished = 0 OR sessions.unpublished IS NULL'). # != 1 doesn't work, unsure why
      order(:session_code). # avma has groups of related sessions
      group('sessions.id').
      map {|s|

        # could have just used [].fetch here to avoid the nil checks
        # and provide a suitable default value. Didn't think of it
        # at the time
        track_subtrack = s.track_subtrack && s.track_subtrack.split('||') || []
        topic          = track_subtrack[0]
        subtopic       = track_subtrack[1] && track_subtrack[1].split('<br>')[0]

        [" #{ s.session_code }",
         s.sponsors_output,
         s.title,
         s.audience_tags,
         s.date,
         s.start_at && Time.at(s.start_at.to_f + 0).strftime('%T'),
         s.end_at && Time.at(s.end_at.to_f + 0).strftime('%T'),
         s.location_mapping_name,
         # not sure what they wanted to type, this is my best guess from
         # example
         s.credit_hours.to_i > 0 ? "CE" : "", # type
         topic,
         subtopic,
         s.credit_hours,
         s.speaker_names
        ]
      }.unshift( headers )
    render xlsx: "simple_xlsx_table", filename: "#{@event.name}_program_grid.xlsx", formats: [:xlsx]
  end

  def exhibitor_user_summary_report
    @event    = Event.find session[:event_id]
    @title    = "Exhibitor Summary"
    @filename = "#{@event.name}_exhibitor_user_summary_report.xlsx"
    job_or_simple_report 'Download Exhibitor Attendees Report', 'exhibitor_attendee_report_data'
  end

  def self.exhibitor_user_summary_report_data event_id, job=false
    query_stage job

    role_id = Role.where(name:'Exhibitor').first.id
    data = User.select('users.id, users.email, sign_in_count, last_sign_in_at, users.created_at').
      joins('LEFT JOIN users_events ON users_events.user_id = users.id').
      joins('LEFT JOIN users_roles ON users_roles.user_id = users.id').
      where('users_events.event_id=?', event_id).
      where('users_roles.role_id=?', role_id).
      order('sign_in_count DESC')

    processing_stage job, data

    data.map {|u|
      iteration_stage job, [u.email, u.sign_in_count, u.last_sign_in_at, u.users_events.count, u.created_at]
    }.unshift( ["Email", "Sign In Count", "Last Sign In At", "# of Events Participated In", "Account Created"])
  end

  def event_177_scan_report
    @event = Event.find session[:event_id]
    render xlsx: "event_177_scan_report", filename: "#{@event.name}_know_your_connections_report.xlsx", formats: [:xlsx]
  end

  #export session data for error checking
  def sessions_review
  	@sessions = Session.select('sessions.*').where('sessions.event_id=?',session[:event_id])

  	respond_to do |format|
  		format.xlsx {	render :action => :sessions_review, disposition: "attachment", filename: "sessions_review.xlsx"	}
  	end
  end

  def video_portal_report
    @event_id = session[:event_id]
    @event_name = Event.find(@event_id).name
    render xlsx: "video_portal_report", filename: "#{@event_name}_video_portal_report.xlsx", formats: [:xlsx]
  end

  def global_survey_report
    @event = Event.find session[:event_id]
    render xlsx: "global_survey_report", filename: "#{@event.name}_survey_report.xlsx", formats: [:xlsx]
  end

  def daily_health_check_report
    @event = Event.find session[:event_id]
    render xlsx: "daily_health_check_survey_report", filename: "#{@event.name}_daily_health_survey_report.xlsx", formats: [:xlsx]
  end

  def daily_health_check_unsubmitted_attendees_report
    @event = Event.find(session[:event_id])
    @filename = "#{@event.name}_daily_health_check_incomplete_attendees_report.xlsx"
    @health_check_done_attendee_ids = SurveyResponse.joins(:survey)
    .where("survey_responses.event_id = ? and surveys.survey_type_id = 7", session[:event_id]).pluck(:attendee_id)
    #@unsubmitted_attendees = Attendee.where("id not in (?) and event_id = ?", @health_check_done_attendee_ids, session[:event_id])
    #@job = Job.find params[:job_id]
    job_or_template_report 'Generate Daily Health Check Incomplete Report', 'reports/daily_health_check_incomplete_attendees', {health_check_done_attendee_ids: @health_check_done_attendee_ids}
    #render xlsx: "daily_health_check_incomplete_attendees", filename: "#{@event.name}_daily_health_check_incomplete_attendees_report.xlsx"
  end

  def incomplete_daily_health_check_attendees_per_day
    @background_job = nil
    @desired_date = params[:date]
    @health_check_done_attendee_ids = SurveyResponse.joins(:survey)
    .where("survey_responses.event_id = ? and surveys.survey_type_id = 7 and survey_responses.local_date = ?",
      session[:event_id], params[:date]).pluck(:attendee_id)
    @unsubmitted_attendees = Attendee.where("id not in (?) and event_id = ?",
    @health_check_done_attendee_ids.length > 0 ? @health_check_done_attendee_ids : "", session[:event_id])
    @event = Event.find(session[:event_id])
    @event_id = @event.id
    render xlsx: "daily_health_check_incomplete_attendees", filename: "#{@event.name}_#{params[:date]}_daily_health_check_incomplete_report.xlsx"
  end

  def attendee_survey_report
    @event = Event.find session[:event_id]
    render xlsx: "attendee_survey_report", filename: "#{@event.name}_survey_report.xlsx", formats: [:xlsx]
  end

  def video_portal_survey_report
    @event_id = session[:event_id]
    render xlsx: "video_portal_survey_report", filename: "#{Event.find(session[:event_id]).name.downcase.gsub(/\s/,"_")}_video_portal_survey_report.xlsx" , formats: [:xlsx]
  end

  def session_survey_report
    @session = Session.find params[:session_id]
    render xlsx: "session_survey_report", filename: "#{@session.session_code}_#{@session.title[0..10]}.xlsx", formats: [:xlsx]
  end

  def generate_session_survey_reports

    Rails::logger.debug "begin generating sesssion surveys"
    Rails.cache.clear

    cmd = Rails.root.join('ek_scripts','reports',"generate_session_survey_reports_v2.rb \"#{session[:event_id]}\"  \"#{params[:job_id]}\"")

    pid = Process.spawn("ROO_TMP='/tmp' ruby #{cmd} 2>&1")

    Job.find(params[:job_id]).update!(pid:pid)
    Process.detach pid

    respond_to do |format|
      format.html { redirect_to("/events/configure/#{session[:event_id]}", :notice => 'File was successfully imported.') }
    end
  end

  def general_survey_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_general_survey_report.xlsx"
    job_or_template_report 'Download General Surveys Report', '/reports/general_survey_report'
  end

  def general_survey_report_simple
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_general_survey_report_simple.xlsx"
    job_or_template_report 'Download General Surveys Report (Simple)', '/reports/general_survey_report_simple'
  end

  def quiz_survey_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_quiz_survey_report.xlsx"
    job_or_template_report 'Download Quiz Surveys Report', '/reports/quiz_survey_report'
  end

  def attendee_scans_summary_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_attendee_scans_summary_report.xlsx"
    job_or_template_report 'Download Attendee Scans Summary Report', '/reports/attendee_scans_summary_report'
  end

  def attendee_scans_full_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_attendee_scans_full_report.xlsx"
    job_or_template_report 'Download Attendee Scans Full Report', '/reports/attendee_scans_full_report'
  end

  # introduced for fiserv, basically a page of tickets which can be cut out
  # containing each attendee who completed a minimum number of surveys, for a
  # raffle
  def attendees_who_completed_surveys_report
    respond_to do |format|
      format.html {
        redirect_to AttendeesWhoCompletedSurveysPdf.new( event_id: session[:event_id] ).create_pdf
      }
    end
  end

  def exhibitor_all_attendee_lead_report
     @exhibitor = Exhibitor.find params["exhibitor_id"]
     @event    = Event.find session[:event_id]
     render xlsx: "exhibitor_all_attendee_lead_report", filename: "#{@exhibitor.company_name}_all_attendee_lead_report.xlsx", formats: [:xlsx]
   end

  def flare_photos_report
    @event    = Event.find session[:event_id]
    @filename = "#{@event.name.downcase.gsub(/\s/,"_")}_flare_photos_report.xlsx"
    job_or_template_report 'Download Flare Photos Report', '/reports/flare_photos_report'
  end

  def download_members
    @event    = Event.find session[:event_id]
    @organization = @event.organization
    @filename = "#{@organization.name.downcase.gsub(/\s/,"_")}_member_data.xlsx"
    job_or_template_report 'Download Member', '/events/download_members'
  end

  private

  def run_job_in_background cmd, job_id
    puts cmd.inspect.red
    pid = Process.spawn("ROO_TMP='/tmp' ruby #{cmd} 2>&1")
    Job.find(job_id).update!(pid:pid)
    Process.detach pid
    render json: {:status => true, job_id: job_id}
  end

  def simple_table_page ary # 2d ary
    '<table>' + ary.map{|a| "<tr><td><b>#{a[0]}</b></td> <td>#{a[1]}</td></tr>" }.join + '</table>'
  end

  def self.return_time_value(val)
    if !val.is_a?(String)
      result = Time.at(val.to_i).gmtime
      result = result + (1) if result.sec == 59
      result.strftime('%R:%S')
    else
      # Time.parse(val).gmtime.strftime('%T')
      # gmtime would cause the time to be translated from
      # the computer's local time, to greenwich mean time.
      # okay on production, but not okay locally
      # In the condition above, it might be okay because the
      # integer represents seconds since 1970, and cannot be
      # malformed, unlike parse, which automatically assumes
      # the local time zone
      # Time.parse(val).strftime('%T')
      ActiveSupport::TimeZone.new('UTC').parse(val).strftime('%T')
    end
  end

  def job_or_simple_report label, data_method
    unless params[:job_id]
      @data = self.class.send data_method, @event.id
      render xlsx: "simple_xlsx_table", filename: @filename, formats: [:xlsx]
    else
      run_job_in_background(
        %@ek_scripts/job_scripts/job_script.rb "#{session[:event_id]}" "#{params[:job_id]}" "#{@filename}" "#{@title}" "#{label}" "#{data_method}"@,
        params[:job_id]
      )
    end
  end

  # template will have access to @event_id, but should do all other queries within the template.
  # template path must start with "/" or render xlsx: will not work.
  def job_or_template_report label, template_path, instance_variables={}
    if !params[:job_id].blank?
      # single quote on instance variables is important here, or escaping of json becomes very confusing
      run_job_in_background(
        %@ek_scripts/job_scripts/job_template_to_string.rb "#{session[:event_id]}" "#{params[:job_id]}" "#{@filename}" "#{label}" "#{template_path}" '#{instance_variables.to_json(root: false).gsub(/\\/, '\\\\\\')}'@,
        params[:job_id]
      )
    else
      instance_variables.each do |key, val|
        instance_variable_set "@#{key}", val
      end
      @event_id = @event.id
      render xlsx: template_path, filename: @filename
    end
  end

  def self.query_stage job
    if job
      job.update!(status:'Fetching Rows From Database')
      job.write_to_file
    end
  end

  def self.processing_stage job, data
    if job
      job.update!(total_rows: data.length, status:'Processing Rows')
      job.write_to_file
    end
  end

  def self.iteration_stage job, row
    job.plus_one_row if job
    row
  end

  def authorization_check
    authorize! :client, :all
  rescue # don't know how else to do this
    authorize! :trackowner, :all # this may be too permissive, but for now it's probably okay.
  end

end
