class SendAppMessageWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0

  def perform(*args)
    background_job = BackgroundJob.create(external_job_id: self.jid, entity_id: args[2], entity_type: 'Event', status: 'in_progress', purpose: 'send_cms_message')
    begin
      excluded_attendee_ids = eval(args[0] ? args[0] : '')
      filter_data = eval(args[1] ? args[1] : '')
      event_id = args[2]
      @attendees = Attendee.where(event_id: event_id)
      sending_attendee_id = args[3]
      msg_title = args[4]
      msg_content = args[5]
    
      if excluded_attendee_ids && excluded_attendee_ids.length > 0
        @attendees = @attendees.where.not(id: excluded_attendee_ids)
      end
      if filter_data
        filtered_attendees filter_data, event_id
      end
      offset = Event.find(event_id).get_offset
      if offset == '-07:00'
        time = Time.zone.now.in_time_zone('Mountain Time (US & Canada)')
      else
        time = Time.zone.now.utc.localtime(offset)
      end

      app_message_thread = AppMessageThread.create!(event_id:event_id,title:msg_title,active:1)
      app_message = AppMessage.create!(event_id:event_id,
        app_message_thread_id:app_message_thread.id,
        attendee_id:sending_attendee_id,
        msg_time:time.strftime("%b #{time.day.ordinalize}, %I:%M %P"),
        content:msg_content
      )
      AttendeesAppMessageThread.create!(app_message_thread_id: app_message_thread.id,
        attendee_id:sending_attendee_id
      )
      @attendees.find_in_batches do |batch|
        thread_attendees = batch.map { |attendee| {app_message_thread_id: app_message_thread.id, attendee_id: attendee.id, created_at: Time.now, updated_at: Time.now} }
        AttendeesAppMessageThread.insert_all(thread_attendees)
      end

      background_job.update(status: 'done')
    rescue StandardError => e
      puts e.message
      puts e.backtrace
      background_job.update(status: 'failed', fail_message: e.message, error_stack: e.backtrace.join("\n\t"))
    end
    
  end

  def filtered_attendees filter_data, event_id
    if filter_data["incomplete_survey_attendees_date"] && filter_data["incomplete_survey_attendees_date"].length > 0
      completed_survey_attendee_ids = SurveyResponse.joins(:survey).where(event_id: event_id, local_date: filter_data["incomplete_survey_attendees_date"])
      .where('surveys.survey_type_id = 7').pluck(:attendee_id)
      @attendees = @attendees.where.not(id: completed_survey_attendee_ids)
    end
    if filter_data["attendee"] && filter_data["attendee"].length > 0
      @attendees = @attendees.where("CONCAT(first_name, ' ', last_name) in (#{filter_data["attendee"].map {|el| "'" + el + "'" }.join(",")})")
    end
    if filter_data["business_unit"] && filter_data["business_unit"].length > 0
      @attendees = @attendees.where(business_unit: filter_data["business_unit"])
    end
    if filter_data["company"] && filter_data["company"].length > 0
      @attendees = @attendees.where(company: filter_data["company"])
    end
    if filter_data['attendee_type'] && filter_data['attendee_type'].length > 0
      @attendees = @attendees.where(attendee_type_id: filter_data['attendee_type'])
    end
    if filter_data["survey"] 
      question_ids = Question.where(survey_id: filter_data["survey"].to_i,question_type_id: 6).ids
      response = Response.joins(survey_response: :survey).select("survey_responses.attendee_id as attendee").where(survey: {id: filter_data["survey"].to_i}, question_id: question_ids)
      survey_attend_attendee_ids = response.map(&:attendee)
      @attendees = @attendees.where(event_id: event_id).where.not(id: survey_attend_attendee_ids).order(:first_name)
    end
  end
end
