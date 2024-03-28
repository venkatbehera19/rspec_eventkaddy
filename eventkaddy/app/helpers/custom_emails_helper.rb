module CustomEmailsHelper

  def recipients_options(user_object, chosen_recipient = nil)
    options=''
    if user_object == "Attendees"
      users = Attendee.select('id, first_name, last_name, email').where('event_id=? AND first_name is not null',session[:event_id]).order('first_name').each do |user|
        options << "<option value='#{user.id}' #{'selected' if user == chosen_recipient}>#{user.full_name}</option>"
      end

    elsif user_object == "Speakers"
      users = Speaker.select('id, honor_prefix, honor_suffix, first_name, last_name, email').where('event_id=? AND first_name is not null',session[:event_id]).order('first_name').each do |user|
        options << "<option value='#{user.id}' #{'selected' if user == chosen_recipient}>#{user.full_name}</option>"
      end

    elsif user_object == "Exhibitors"
      users = Exhibitor.select('id, company_name, email').where('event_id=? AND company_name is not null',session[:event_id]).order('company_name').each do |user|
        options << "<option value='#{user.id}' #{'selected' if user == chosen_recipient}>#{user.company_name}</option>"
      end

    elsif user_object == "Attendees_with_surveys"
      global_poll = Survey.where(event_id:session[:event_id], survey_type_id:1).first
      return nil if global_poll.blank?
      users = Attendee.select('distinct attendees.id, first_name, last_name, email').joins('INNER JOIN survey_responses ON attendees.id = survey_responses.attendee_id AND attendees.event_id=survey_responses.event_id').where('attendees.event_id=? AND first_name is not null',session[:event_id]).order(:first_name)
      users.each do |user|
        options << "<option value='#{user.id}' #{'selected' if user == chosen_recipient}>#{user.full_name}</option>"
      end

    elsif user_object == "Attendees_without_surveys"
      global_poll = Survey.where(event_id:session[:event_id], survey_type_id:1).first
      return nil if global_poll.blank?
      attendees_with_surveys = Attendee.joins('INNER JOIN survey_responses ON attendees.id = survey_responses.attendee_id AND attendees.event_id=survey_responses.event_id').where('attendees.event_id=? AND first_name is not null',session[:event_id]).select('distinct attendees.id')
      attendees_ids = attendees_with_surveys.pluck(:id).to_a
      users = Attendee.select('id, first_name, last_name, email').where('event_id=? AND id NOT IN (?) AND first_name is not null',session[:event_id], attendees_ids)
      users.each do |user|
        options << "<option value='#{user.id}' #{'selected' if user == chosen_recipient}>#{user.full_name}</option>"
      end
    elsif user_object == "AttendeeWhoCheckedInWithoutSurveys"
      global_poll = Survey.where(event_id:session[:event_id], survey_type_id:1).first
      return nil if global_poll.blank?

      @page_viewed_attendees  = reporting_db.query(
                                  "SELECT video_views.attendee_id AS attendee_id
                                  FROM reporting.video_views
                                  LEFT OUTER JOIN #{primary_db}.attendees ON attendees.id=video_views.attendee_id
                                  WHERE video_views.event_id=#{session[:event_id]}
                                  GROUP BY video_views.attendee_id
                                  ORDER BY first_name, last_name")
      attendee_who_viewed_session = @page_viewed_attendees.map{|attendee| attendee['attendee_id']}
      attendees_with_surveys = Attendee.joins('INNER JOIN survey_responses ON attendees.id = survey_responses.attendee_id AND attendees.event_id=survey_responses.event_id').where('attendees.id IN (?) AND first_name is not null',attendee_who_viewed_session).select('distinct attendees.id')
      attendee_who_didnt_submitted_survey = attendee_who_viewed_session - attendees_with_surveys.ids
      users = Attendee.where(id: attendee_who_didnt_submitted_survey, event_id: session[:event_id])
      users.each do |user|
        options << "<option value='#{user.id}' #{'selected' if user == chosen_recipient}>#{user.full_name}</option>"
      end
    else 
      return nil
    end

    options.html_safe
  end

end