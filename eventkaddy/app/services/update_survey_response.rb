class UpdateSurveyResponse

  def initialize(survey_response, responses, gps_location, time_taken)
    @survey_response = survey_response
    @responses       = responses.is_a?(Array) ? responses : responses.values
    @result          = {"status" => false, "error_messages" => []}
    @gps_location    = gps_location == 'null' ? nil : gps_location
    @time_taken      = time_taken == 'null' ? nil : time_taken
  end

  def call
    update_survey_response_and_responses; result;
  end

  private

  attr_reader :survey_response, :responses, :result, :gps_location, :time_taken

  def update_responses
    responses.each do |r|
      Response.where(event_id:survey_response.event_id, survey_response_id:survey_response.id, question_id:r['question_id'])
              .first_or_create
              .update!(answer_id:r['answer_id'], response:r['response'], rating:r['rating'])
    end
  end

  def fix_null_strings
    responses.each { |r| r.each { |k, v| r[k] = nil if v == 'null' } }
  end

  def update_survey_response_and_responses
    fix_null_strings
    survey_response.update! gps_location:gps_location, time_taken:time_taken
    update_responses
    result['status'] = true
  end
end