class StatisticsController < ApplicationController
  # load_and_authorize_resource
  layout 'subevent_2013'

  def tags
    if session[:event_id] && current_user
      TagType.all.each do |t|
        case t.name
        when 'session'
          @session_tag_type_id = t.id
        when 'exhibitor'
          @exhibitor_tag_type_id = t.id
        when 'session-audience'
          @audience_tag_type_id = t.id
        when 'attendee'
          @attendee_tag_type_id = t.id
        end
      end

      @session_tags = Tag.select('id, name, level, leaf, parent_id').
        where(event_id:session[:event_id], tag_type_id:@session_tag_type_id)

      @exhibitor_tags = Tag.select('id, name, level, leaf, parent_id').
        where(event_id:session[:event_id], tag_type_id:@exhibitor_tag_type_id)

      @audience_tags = Tag.select('id, name, level, leaf, parent_id').
        where(event_id:session[:event_id], tag_type_id:@audience_tag_type_id)

      @attendee_tags = Tag.select('id, name, level, leaf, parent_id').
        where(event_id:session[:event_id], tag_type_id:@attendee_tag_type_id)
    else
      render :text => 'You must be signed in to an event to view this page.'
    end
  end

  def dup_hash(ary)
    ary.inject(Hash.new(0)) { |h,e| h[e] += 1; h }.select { |k,v| v > 1 }.inject({}) { |r, e| r[e.first] = e.last; r }
  end

  def return_top_ten_favourited_sessions
    attendee_ids     = Attendee.where(event_id:@event.id).pluck(:id)
    session_ids      = SessionsAttendee.where(attendee_id:attendee_ids).where('session_id IS NOT NULL').pluck(:session_id)
    dup_counts       = dup_hash(session_ids).sort_by{|k,v| v}.reverse
    dup_counts.length < 9 ? max = dup_counts.length - 1 : max = 9
    return [] if dup_counts.size == 0
    top_ten_sessions = []
    for i in 0..max
      session = Session.find(dup_counts[i][0])
      top_ten_sessions << {id:session.id, session_code:session.session_code, title:session.title, count:dup_counts[i][1]}
    end
    top_ten_sessions
  end

  def return_top_ten_favourited_exhibitors
    exhibitor_ids      = Exhibitor.where(event_id:@event.id).pluck(:id)
    exhibitor_ids      = ExhibitorAttendee.where(exhibitor_id:exhibitor_ids).where('exhibitor_id IS NOT NULL').pluck(:exhibitor_id)
    dup_counts         = dup_hash(exhibitor_ids).sort_by{|k,v| v}.reverse
    dup_counts.length < 9 ? max = dup_counts.length : max = 9
    return [] if dup_counts.size == 0
    top_ten_exhibitors = []
    for i in 0..max
      exhibitor = Exhibitor.find(dup_counts[i][0])
      top_ten_exhibitors << {id:exhibitor.id, exhibitor_code:exhibitor.exhibitor_code, company_name:exhibitor.company_name, count:dup_counts[i][1]}
    end
    top_ten_exhibitors
  end

  def return_number_of_favourited_sessions
    attendee_ids = Attendee.where(event_id:@event.id).pluck(:id)
    SessionsAttendee.where(attendee_id:attendee_ids).size
  end

  def return_number_of_attended_sessions
    number_of_attended_sessions = 0
    attendees = Attendee.where(event_id:@event.id).each do |attendee|
      number_of_attended_sessions += attendee.iattend_sessions.split(',').size unless attendee.iattend_sessions.blank?
    end
    number_of_attended_sessions
  end

  def return_number_of_favourited_exhibitors
    exhibitor_ids = Exhibitor.where(event_id:@event.id).pluck(:id)
    ExhibitorAttendee.where(exhibitor_id:exhibitor_ids).size
  end

  def return_number_of_notes
    type_id = AttendeeTextUploadType.where(name:'note').first.id
    AttendeeTextUpload.where(event_id:@event.id,attendee_text_upload_type_id:type_id).size
  end

  def return_exhibitor_game_participants_count
    url              = URI.parse("https://exhibitorgame1.eventkaddy.net/statistics/active_players_count/#{@event.id}")
    req              = Net::HTTP::Get.new(url.to_s)
    http             = Net::HTTP.new(url.host, url.port)
    http.use_ssl     = true
    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res              = http.start {|http| http.request(req) }
    res.body
  end

  def stats
    @event         = Event.find(session[:event_id])
    @first_session = Session.where('event_id=? AND session_cancelled IS NOT NULL', @event.id).order('date ASC').first
    @last_session  = Session.where('event_id=? AND session_cancelled IS NOT NULL', @event.id).order('date DESC').first

    # Attendee
    @attendees_count                 = Attendee.where(event_id:@event.id).size
    @number_of_favourited_sessions   = return_number_of_favourited_sessions
    @number_of_attended_sessions     = return_number_of_attended_sessions
    @number_of_favourited_exhibitors = return_number_of_favourited_exhibitors
    @number_of_notes                 = return_number_of_notes
    @number_of_message_threads       = AppMessageThread.where(event_id:@event.id).size
    @number_of_messages              = AppMessage.where(event_id:@event.id).size
    @session_feedback_count          = Feedback.where('event_id=? AND speaker_id IS NULL', @event.id).size
    @speaker_feedback_count          = Feedback.where('event_id=? AND speaker_id IS NOT NULL', @event.id).size
    @attendance_certificate_count    = Dir["public/event_data/#{@event.id.to_s}/generated_pdfs/*"].size
    @exhibitor_game_participants     = return_exhibitor_game_participants_count

    # Session

    @sessions_count                  = Session.where(event_id:@event.id).size
    @sessions_cancelled_count        = Session.where(event_id:@event.id,session_cancelled:true).size
    @sessions_leftover               = @sessions_count - @sessions_cancelled_count
    @top_ten_sessions                = return_top_ten_favourited_sessions

    # Exhibitor

    @exhibitors_count                = Exhibitor.where(event_id:@event.id).size
    @top_ten_exhibitors              = return_top_ten_favourited_exhibitors



  end

  def session_by_room
    type_id = LocationMappingType.where(type_name:'Room').first.id
    @rooms  = LocationMapping.find_by_sql [
      'SELECT location_mappings.id,
      name,
      sessions.id AS s_id,
      sessions.title AS s_title
      FROM
      location_mappings
      LEFT JOIN sessions ON location_mappings.id=sessions.location_mapping_id
      WHERE
      location_mappings.event_id=?
      AND
      mapping_type=?',session[:event_id],type_id]
    # .joins('sessions ON location_mappings.id=sessions.location_mapping_id')
    # .where(event_id:session[:event_id],mapping_type:type_id)
  end

end
