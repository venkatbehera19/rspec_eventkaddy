class IncompleteDailyCheckupAttendees
  def initialize event_id, workbook = nil, job=nil, survey_type_id = 7, desired_date=nil
    @event_id = event_id
    @workbook = workbook
    @job = job
    @survey_type_id = survey_type_id
    @workbook.styles do |style|
      @black_cell = style.add_style :bg_color => "00", :fg_color => "FF", :sz => 14, :alignment => { wrap_text: true, :horizontal=> :left }
      @bold_cell  = style.add_style :sz => 16
    end
    @desired_date = desired_date
    generate_sheets
  end

  def heads
    ["Registration ID", "Name", "Email", "Phone Number", "Custom Fields 1", "Custom Fields 2"]
  end

  def generate_sheets
    if @job
      @job.update!( status: "Processing Rows", total_rows: (@job.total_rows || total_rows))
      @job.write_to_file
    end
    sheet_names.each do |date|
      @survey_submitted_attendee_ids = SurveyResponse.joins(:survey)
      .where("survey_responses.event_id = ? and surveys.survey_type_id = ? and date(survey_responses.updated_at) = ?",
      @event_id, @survey_type_id, date).pluck(:attendee_id)
      @not_submitted_attendees = Attendee.where.not(id: @survey_submitted_attendee_ids).where(event_id: @event_id)
      @workbook.add_worksheet(name: date.to_s) do |sheet|
        add_basic_info sheet, date
        sheet.add_row heads, style: @black_cell

        @not_submitted_attendees.each do |attendee|
          sheet.add_row [attendee.account_code, attendee.full_name, attendee.email, attendee.mobile_phone, attendee.custom_fields_1, attendee.custom_fields_2]
          @job.plus_one_row if @job
        end
      end
    end
  end

  def add_basic_info sheet, date
    sheet.add_row ["Incomplete Daily Checkup Survey Attendees #{date.to_s}"],style: @black_cell, height: 30   
  end

  def total_rows
    count = 0
    sheet_names.each do |date|
      @survey_submitted_attendee_ids = SurveyResponse.joins(:survey)
      .where("survey_responses.event_id = ? and surveys.survey_type_id = ? and date(survey_responses.updated_at) = ?",
      @event_id, @survey_type_id, date).pluck(:attendee_id)
      @not_submitted_attendees = Attendee.where.not(id: @survey_submitted_attendee_ids).where(event_id: @event_id)
      count += @not_submitted_attendees.size
    end
    count
  end

  def sheet_names
    return [@desired_date.to_date] unless @desired_date.blank?
    @event = Event.find @event_id
    start_date = @event.event_start_at.to_date
    last_date = @event.event_end_at.to_date > Date.today ? Date.today : @event.event_end_at.to_date
    (start_date..last_date).to_a
  end
end