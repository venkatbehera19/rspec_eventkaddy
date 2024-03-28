
class VideoVisitsReport < AxlsxReport

  attr_reader :event_id, :exhibitor_id, :reporting_db, :primary_db

  def initialize event_id, exhibitor_id, package, job=nil, primary_db, email_not_showed
    @exhibitor_id = exhibitor_id
    @event_id = event_id
    @primary_db = primary_db
    reporting_path = Rails.root.join('config','reporting_database.yml')
    raise "reporting database configuration not found." unless File.exist? reporting_path
    @reporting_db = Mysql2::Client.new( YAML::load(File.open(reporting_path))[Rails.env] )
    super package, job, event_id
    @email_not_showed = email_not_showed

    add_sheet "Video Visits Report", [ heads ].concat( data ), [20, 20, 40, 30, 40, 30, 20, 20]
  end

  def heads
    headings = ['First Name', 'Last Name', 'Company', 'Title', 'Phone Number', 'Email', 'Last Visited', 'Checked in', 'Number of Visits']
    headings.delete_at(4) if @email_not_showed #removes email column based on show status
    headings
  end

  def data
    utc_offset = Event.find(event_id).utc_offset || "+00:00"
    video_views.map {|video_view|
      row = [
        video_view["first_name"], 
        video_view["last_name"], 
        video_view["company"],
        video_view["title"],
        "#{video_view["mobile_phone"]} #{video_view["business_phone"]}", 
        video_view["email"],
        Time.parse("#{video_view["last_visited"].strftime('%Y-%m-%d %H:%M:%S')}Z").localtime(utc_offset).strftime('%D %r').to_s, 
        !!(video_view["exhibitor_checkin"] && (video_view["exhibitor_checkin"].include? @exhibitor_id)), 
        video_view["total_visits"]
      ]
      row.delete_at(4) if @email_not_showed #removes email column based on show status
    }
  end

  def video_views
    result = reporting_db.query(
      "SELECT COUNT(attendee_id) AS total_visits,
        vv.id, 
        vv.attendee_id AS attendee_id,
        vv.event_id, 
        vv.exhibitor_id, 
        vv.exhibitor_code, 
        vv.exhibitor_company,
        vv.updated_at AS last_visited,
        attendees.first_name AS first_name,
        attendees.last_name AS last_name,
        attendees.company AS company,
        attendees.title AS title,
        attendees.email AS email,
        attendees.mobile_phone,
        attendees.business_phone,
        attendees.exhibitor_checkin
        FROM reporting.video_views AS vv
        INNER JOIN #{primary_db}.attendees ON attendees.id=attendee_id
        WHERE vv.exhibitor_id=#{exhibitor_id} 
        AND vv.event_id=#{event_id}
        GROUP BY attendee_id
        ORDER BY first_name").to_a
    result
  end

end
