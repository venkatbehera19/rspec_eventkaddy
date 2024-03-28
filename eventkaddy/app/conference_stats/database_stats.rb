class DatabaseStats
  
  attr_accessor :event_id, :event

  def initialize event_id
    @event_id = event_id
    @event = Event.select("id, name").where(event_id:event_id)
  end

  def attendees_listed 
    count Attendee
  end

  def attendees_logins 
    count AttendeeLogin
  end

  def unique_logins
    count AttendeeLogin.select('DISTINCT attendee_id')
  end

  def login_devices
    AttendeeLogin
      .select('device, COUNT(*) AS count')
      .where(event_id:event_id)
      .group(:device)
      .map {|logins| {device: logins.device || 'Unknown', count:logins.count}}
  end

  def unique_login_devices
    AttendeeLogin
      .select('device, COUNT( DISTINCT attendee_id ) AS count')
      .where(event_id:event_id)
      .group(:device)
      .map {|logins| {device: 'Unique ' + (logins.device || 'Unknown'), count:logins.count}}
  end

  def sessions_listed 
    count Session
  end

  def exhibitors_listed 
    count Exhibitor
  end

  def conference_notes_listed
    count SessionFile
  end

  def push_notifications_sent
    count Notification, status:"active"
  end

  def notes_taken
    type_id = AttendeeTextUploadType.where(name:"note").first.id
    count AttendeeTextUpload, attendee_text_upload_type_id:type_id
  end

  def surveys_completed
    survey_types = SurveyType.all.order(:id)
    survey_types.map do |st|
      {
        type: st.name,
        surveys: Survey.where(event_id: event_id, survey_type_id: st.id)
          .map { |survey| { title: survey.title, survey_responses_count: survey.survey_responses.count } }
      }
    end
    # Survey.where(event_id:event_id).where.not(title: 'Session Feedback')
    #       .order(:survey_type_id)
    #       .map {|s|
    #         {title:s.title, survey_responses_count:s.survey_responses.count}
    #       }
  end

  def messages_sent
    count AppMessage
  end

  def session_feedback
    count Feedback, "speaker_id IS NULL"
  end

  def speaker_feedback
    count Feedback, "speaker_id IS NOT NULL"
  end

  def badges_completed # by attendees who completed n badges
    Event.find_by_sql(["
      SELECT num_of_copies, count(num_of_copies) AS copies_at_count FROM (
        SELECT   event_id, count(attendee_id) AS num_of_copies, attendee_id
        FROM     attendees_app_badges
        WHERE event_id=? AND complete=1
        GROUP BY attendee_id
      ) AS dup_cols GROUP BY num_of_copies", event_id]).map {|aab|
      {badges_completed:aab.num_of_copies, attendee_count:aab.copies_at_count}
    }
  end

  def badges_completed_by_badge_name
    Event.find_by_sql(["
       SELECT event_id, app_badge_id, count(app_badge_id) AS num_of_copies
       FROM attendees_app_badges
       WHERE event_id=? AND complete=1
       GROUP BY app_badge_id
       ", event_id]
    ).map {|aab|
      # guard against missing badges since we don't delete
      # attendees_app_badge data when a badge is removed
      app_badge = AppBadge.where(id:aab.app_badge_id)

      if app_badge.length > 0 
        name = app_badge.first.name
      else
        next
      end
      
      {name:name, attendee_count:aab.num_of_copies}
    }.reject &:nil?
  end

  def top_ten_attendees_by_points
    AttendeesAppBadge.top_ten_by_points event_id
  end

  # don't use this method with user derived arguments
  # (vulnerable to injection due to convenience of interpolation)
  # UPDATE: fixed vulnurability, but this method actually isn't used anywhere
  # at least not when a grep rb html haml erb files. Probably originally
  # intended for use with badges_completed, but
  def duplicates_count table, col
    # Event or any other rails model could be used. find_by_sql is a delegated method
    Event.find_by_sql(["
      SELECT num_of_copies, count(num_of_copies) AS copies_at_count FROM (
        SELECT   event_id, count(?) AS num_of_copies, ?
        FROM     ?
        WHERE event_id=?
        GROUP BY ?
      ) AS dup_cols GROUP BY num_of_copies
    ", col, col, table, event_id, col])
  end

  # counts files in pdf_generators that match the class names in /services/pdf_generators/event_xx/
  def get_generated_certificate_names
    Dir["./app/services/pdf_generators/event_#{event_id}/*"].map {|f| 
      f.sub("./app/services/pdf_generators/event_#{event_id}/generate_", "").sub(".rb", "") 
    }.map {|name|

      # as filename method could be edited to something other than the class,
      # we have a special filename_prefix method that we want to get at using
      # this ugly bit of code
      pdf_klass = "Event#{event_id}::Generate#{name.camelize.gsub(/\s/, '')}".constantize
      if pdf_klass.respond_to? :filename_prefix
        name = pdf_klass.filename_prefix.downcase.gsub(/\s/, "_")
      end

      {
        name: name.titleize, 
        count: Dir["./public/event_data/#{event_id}/generated_pdfs/*"].count {|f| 
          f.downcase.gsub(/\s/, "_").match(name)}
      }
    }
  end

  ## Google Analytics
  def ios_downloads; end
  def android_downloads; end
  def mobile_web_pages_views; end
  def mobile_users; end # still for the website
  def app_users; end
  def push_notifications_received_by_devices; end
  def devices_permitted_to_receive_notifications; end
  def total_devices; end # ios, and android
  def average_time_in_app; end
  def total_app_opens; end
  def influenced_opens_ios; end
  def influenced_opens_android; end
  def banner_ad_views; end # return object with views for each banner
  def home_button_stats; end 
  # returns object with number of times clicked on web, and on device
  # for each home button.

  private

  def count model, stipulation={}
    # regarding count vs length: count makes the DB do the counting, length counts the ruby array.
    # size chooses for you
    model.where(event_id:event_id).where(stipulation).count
  end

end

