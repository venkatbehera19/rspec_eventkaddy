class VideoVisitsController < ApplicationController
  layout :set_layout
  include ExhibitorPortalsHelper

  def initialize
    super
    reporting_path = Rails.root.join('config','reporting_database.yml')
    raise "reporting database configuration not found." unless File.exist? reporting_path
    @@reporting_db = Mysql2::Client.new( YAML::load(File.open(reporting_path))[Rails.env] )
  end

  def index
    @exhibitor = get_exhibitor
    @exhibitor && check_for_payment
    if !@exhibitor.blank?
      puts @exhibitor.id
      setting_type_id = SettingType.find_by_name "cms_settings"
      setting         = Setting.where(event_id: session[:event_id], setting_type_id: setting_type_id).first
      @setting         = setting.json
      @video_views = @@reporting_db.query(
        "SELECT COUNT(vv.attendee_id) AS total_visits,
          vv.id,
          vv.event_id,
          vv.attendee_id,
          vv.exhibitor_id,
          vv.exhibitor_code,
          vv.exhibitor_company,
          attendees.first_name AS first_name,
          attendees.last_name AS last_name,
          attendees.company AS company,
          attendees.title AS title,
          attendees.email AS email,
          attendees.mobile_phone,
          attendees.business_phone,
          attendees.title AS title,
          attendees.created_at AS created_at,
          attendees.updated_at AS updated_at,
          attendees.exhibitor_checkin
          FROM reporting.video_views AS vv
          INNER JOIN #{primary_db}.attendees ON attendees.id=vv.attendee_id
          WHERE vv.exhibitor_id=#{@exhibitor.id}
          AND vv.event_id=#{session[:event_id]}
          GROUP BY vv.attendee_id
          ORDER BY first_name").to_a
    end
  end

  def show
    @exhibitor        = get_exhibitor
    @exhibitor_id     = @exhibitor.id
    @attendee_id      = params[:attendee_id]
    @attendee         = Attendee.find @attendee_id
    @event            = Event.find(session[:event_id])
    @total_visits     = params[:total_visits]
    setting_type_id = SettingType.find_by_name "cms_settings"
    setting         = Setting.where(event_id: session[:event_id], setting_type_id: setting_type_id).first
    @setting         = setting.json

    @video_views      = @@reporting_db.query(
      "SELECT created_at, event_id
        FROM reporting.video_views
        WHERE exhibitor_id=#{@exhibitor.id}
        AND event_id=#{session[:event_id]}
        AND attendee_id=#{@attendee_id}
        ORDER BY created_at").to_a
    response          = Response.find_by_sql(
                          "SELECT id FROM responses WHERE responses.survey_response_id IN
                          (SELECT id FROM survey_responses WHERE survey_responses.attendee_id = #{@attendee_id}
                            AND survey_responses.exhibitor_id = #{@exhibitor_id})")
    @completed_survey = !(response.blank?)
  end

  private

  def get_exhibitor
    if current_user.role? :exhibitor then
      if current_user.is_a_staff?
        es = ExhibitorStaff.find_by_user_id current_user.id
        return Exhibitor.find es.exhibitor_id
      else
        current_user.first_or_create_exhibitor( session[:event_id] )
      end
    elsif !session[:exhibitor_id_portal].blank?
      Exhibitor.find(session[:exhibitor_id_portal])
    end
  end

  def set_layout
    if current_user.role? :exhibitor then
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  def getLocalTime(time)
		t_offset = @event.utc_offset
		if (t_offset==nil) then
			t_offset = "+00:00" #default to UTC 0
    end
    return time.localtime(t_offset).strftime("%H:%M:%S")
  end

  helper_method :getLocalTime
end
