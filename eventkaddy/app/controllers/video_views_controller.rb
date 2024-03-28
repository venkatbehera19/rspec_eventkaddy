class VideoViewsController < ApplicationController
  # load_and_authorize_resource
  layout :set_layout

  def initialize
    super
    reporting_path = Rails.root.join('config','reporting_database.yml')
    raise "reporting database configuration not found." unless File.exist? reporting_path
    @@reporting_db = Mysql2::Client.new( YAML::load(File.open(reporting_path))[Rails.env] )
  end
  
  def index
    @sessions        = Session.select('id, session_code, title')
                              .where("sessions.session_code IS NOT NULL AND sessions.event_id=#{session[:event_id]}")
    iattend_sessions = Attendee.select('iattend_sessions')
                              .where("attendees.iattend_sessions IS NOT NULL AND attendees.event_id=#{session[:event_id]}")
    @sessions_hash = {}

    @primary_db = primary_db

    @sessions.each do |session|
      !session.session_code.blank? && (@sessions_hash[session.session_code] = session.as_json.merge(checkin_count: 0, page_view_count: 0, video_view_count: 0))
    end

    iattend_sessions.each do |iattend|
      iattend_array = iattend.iattend_sessions.split(',')
      iattend_array.uniq.each do |ele|
        @sessions_hash[ele] && @sessions_hash[ele][:checkin_count] += 1
      end
    end

    page_views = @@reporting_db.query(
      "SELECT count(session_code) AS session_code_count,
      id,
      event_id,
      attendee_id,
      session_code
    FROM reporting.video_views
    WHERE event_id=#{session[:event_id]}
    GROUP BY session_code")

    page_views.each do |pv|
      @sessions_hash[pv["session_code"]] && @sessions_hash[pv["session_code"]][:page_view_count] = pv["session_code_count"]
    end

       video_views = VideoView.find_by_sql(
      "SELECT count(vv.session_id) AS session_id_count,
        vv.event_id,
        vv.attendee_id,
        s.session_code AS session_code
      FROM #{@primary_db}.video_views AS vv
      LEFT JOIN #{@primary_db}.sessions AS s ON s.id=vv.session_id
      WHERE vv.event_id=#{session[:event_id]}
      GROUP BY vv.session_id")

    # video_views = VideoView.find_by_sql(
    #   "SELECT count(vv.session_id) AS session_id_count,
    #     vv.event_id,
    #     vv.attendee_id,
    #     s.session_code AS session_code
    #   FROM #{@primary_db}.video_views AS vv
    #   LEFT JOIN #{@primary_db}.sessions AS s ON s.id=vv.session_id
    #   WHERE vv.event_id=#{session[:event_id]}
    #   AND vv.session_code is NOT NULL
    #   GROUP BY vv.session_id")
    video_views.each do |vv|
      @sessions_hash[vv["session_code"]] && @sessions_hash[vv["session_code"]][:video_view_count] = vv["session_id_count"]
    end
  end

  def ce_checkedin_attendees
    @session_code           = params[:session_code]
    @session_title          = Session.where(session_code:params[:session_code], event_id: session[:event_id]).first.title
    @attendees              = Attendee.where("attendees.event_id=#{session[:event_id]} AND attendees.iattend_sessions IS NOT NULL")
    @ce_checkedin_attendees = @attendees.select {|at| at.iattend_sessions.include? @session_code}
  end

  def page_viewed_attendees
    @session_code           = params[:session_code]
    @session_title          = Session.where(session_code:params[:session_code], event_id:session[:event_id]).first.title
    @page_viewed_attendees  = @@reporting_db.query(
                                "SELECT count(video_views.attendee_id) AS number_of_visits,
                                  video_views.event_id,
                                  video_views.attendee_id AS attendee_id,
                                  video_views.session_code AS session_code,
                                  attendees.first_name AS first_name,
                                  attendees.last_name AS last_name,
                                  attendees.company AS company,
 								attendees.title AS title,
                                  attendees.email AS email,
                                  attendees.mobile_phone AS mobile_phone,
                                  attendees.business_phone AS business_phone
                                FROM reporting.video_views
                                LEFT OUTER JOIN #{primary_db}.attendees ON attendees.id=video_views.attendee_id
                                WHERE video_views.session_code='#{@session_code}' 
                                AND video_views.event_id=#{session[:event_id]}
                                GROUP BY video_views.attendee_id
                                ORDER BY first_name, last_name")
  end

  def video_viewed_attendees
    @session_code     = params[:session_code]
    @session          = Session.where(session_code: @session_code, event_id: session[:event_id]).first
    @session_title    = @session.title
    @video_views      = VideoView.find_by_sql(
                          "SELECT video_views.id AS id,
                            video_views.attendee_id AS attendee_id, 
                            video_views.session_id, 
                            attendees.first_name AS first_name,
                            attendees.last_name AS last_name,
                            attendees.company AS company,
 						   attendees.title AS title,
                            attendees.email AS email,
                            attendees.mobile_phone AS mobile_phone,
                            attendees.business_phone AS business_phone,
                            attendees.exhibitor_checkin AS exhibitor_checkin,
                            attendees.created_at AS created_at,
                            attendees.updated_at AS updated_at,
                            video_views.event_id,
                            video_views.view_total
                          FROM #{primary_db}.video_views
                          LEFT JOIN #{primary_db}.attendees ON attendees.id=video_views.attendee_id
                          WHERE video_views.session_id=#{@session.id}
                          AND video_views.event_id=#{session[:event_id]}")
  end
 
  def show_pages_views
    @attendee_id     = params[:id]
    @session_code    = params[:session_code]
    @attendee        = Attendee.find @attendee_id
    @video_views     = @@reporting_db.query(
      "SELECT video_views.attendee_id AS attendee_id,
        video_views.session_id, 
        video_views.event_id,
        video_views.created_at AS created_at
      FROM reporting.video_views
      WHERE video_views.attendee_id=#{@attendee_id} AND
      video_views.session_code='#{@session_code}' AND
      video_views.event_id=#{session[:event_id]}")
  end

  def show_video_views
    @attendee_id     = params[:id]
    @session_id      = params[:sid]
    @session_code    = params[:scode]
    @attendee        = Attendee.find @attendee_id
    @video_views     = VideoView.find_by_sql(
      "SELECT *
      FROM #{primary_db}.video_views
      WHERE video_views.attendee_id=#{@attendee_id}
      AND video_views.session_id='#{@session_id}'
      AND video_views.event_id=#{session[:event_id]}").first
  end

  def history
    @video_view      = VideoView.find params[:id]
    @session         = Session.find_by_session_code params[:session_code]
    @attendee        = Attendee.find params[:attendee_id]
    @speakers        = Speaker.joins(:sessions_speakers)
                              .where('sessions_speakers.session_id' =>  @video_view.session_id)
                              .select("speakers.first_name, speakers.last_name")
  end

  def index_report
    @reporting_db   = @@reporting_db
    @primary_db     = primary_db
    @event_id       = session[:event_id]
    @event_name     = Event.find(@event_id).name
    render xlsx: "index_report", filename: "#{@event_name}_video_views_report.xlsx" 
  end

  def ce_checkedin_attendees_report
    @session_code           = params[:session_code]
    @attendees              = Attendee.where("attendees.event_id=#{session[:event_id]} AND attendees.iattend_sessions IS NOT NULL").order(:first_name, :last_name)
    @ce_checkedin_attendees = @attendees.select {|at| at.iattend_sessions.include? @session_code}
    @event_id               = session[:event_id]
    @event_name             = Event.find(@event_id).name
    @session_title          = Session.where(session_code:params[:session_code], event_id: session[:event_id]).first.title
    render xlsx: "ce_checkedin_attendees_report", filename: "#{@event_name}_#{@session_code}_ce_checkedin_attendees_report.xlsx" 
  end

  def page_viewed_attendees_report
    @session_code           = params[:session_code]
    @session_title          = Session.where(session_code:params[:session_code], event_id: session[:event_id]).first.title
    @event_id               = session[:event_id]
    @page_viewed_attendees  = @@reporting_db.query(
                                "SELECT count(video_views.attendee_id) AS number_of_visits,
                                  video_views.event_id,
                                  video_views.attendee_id AS attendee_id,
                                  video_views.session_code AS session_code,
								                  video_views.created_at AS created_at,
								                  video_views.updated_at AS updated_at,
                                  attendees.first_name AS first_name,
                                  attendees.last_name AS last_name,
                                  attendees.company AS company,
 								attendees.title AS title,
                                  attendees.email AS email,
                                  attendees.mobile_phone AS mobile_phone,
                                  attendees.business_phone AS business_phone
                                FROM reporting.video_views
                                LEFT OUTER JOIN #{primary_db}.attendees ON attendees.id=video_views.attendee_id
                                WHERE video_views.session_code='#{@session_code}' 
                                AND video_views.event_id=#{@event_id}
                                GROUP BY video_views.attendee_id
                                ORDER BY first_name, last_name")
    @event_name = Event.find(@event_id).name
    #render xlsx: "page_viewed_attendees_report", filename: "#{@event_name}_page_viewed_attendees_report.xlsx" 
    render xlsx: "page_viewed_attendees_report", filename: "#{@event_name}_#{@session_code}_page_viewed_attendees_report.xlsx" 
  end

  def video_viewed_attendees_report
    @session_code     = params[:session_code]
    @event_id         = session[:event_id]
    @session          = Session.where(session_code: @session_code, event_id: @event_id).first
    @session_title    = @session.title
    @video_views      = VideoView.find_by_sql(
                          "SELECT video_views.id AS id,
                            video_views.attendee_id AS attendee_id, 
                            video_views.session_id, 
                            attendees.first_name AS first_name,
                            attendees.last_name AS last_name,
                            attendees.company AS company,
 						   attendees.title AS title,
                            attendees.email AS email,
                            attendees.mobile_phone AS mobile_phone,
                            attendees.business_phone AS business_phone,
                            attendees.exhibitor_checkin AS exhibitor_checkin,
                            attendees.created_at AS created_at,
                            attendees.updated_at AS updated_at,
                            video_views.event_id,
                            video_views.view_total
                          FROM #{primary_db}.video_views
                          LEFT JOIN #{primary_db}.attendees ON attendees.id=video_views.attendee_id
                          WHERE video_views.session_id=#{@session.id}
                          AND video_views.event_id=#{@event_id}
                          ORDER BY first_name, last_name")
    @event_name = Event.find(@event_id).name
  #  render xlsx: "video_viewed_attendees_report", filename: "#{@event_name}_video_viewed_attendees_report.xlsx" 
    render xlsx: "video_viewed_attendees_report", filename: "#{@event_name}_#{@session_code}_video_viewed_attendees_report.xlsx" 
  end

  private

  def set_layout
    if current_user.role? :exhibitor then
      'exhibitorportal'
    else
      'subevent_2013'
    end
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

  helper_method :formatted_duration

  def getLocalTime(time)
    @event = Event.find(session[:event_id])
    t_offset = @event.utc_offset
    if (t_offset==nil) then
      t_offset = "+00:00" #default to UTC 0
    end
    return time.localtime(t_offset).strftime("%H:%M:%S")
  end
  
  helper_method :getLocalTime

  # private

  # def video_view_params
  #   params.require(:video_view).permit(:event_id, :session_id, :attendee_id, :exhibitor_id, :event_year, :session_code, :account_code, :start_time, :date, :view_ranges, :view_total, :duration, :paused_at, :time_watched, :video_length, :view_details, :custom_fields_1, :custom_fields_2, :custom_fields_3)
  # end

end
