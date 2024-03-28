class ReturnSurveyObject

  def initialize(survey_id, options = {})
    @survey_id    = survey_id
    @result       = {"status" => false, "error_messages" => []}
    @event_id     = options.fetch(:event_id, false)
    @account_code = options.fetch(:account_code, false)
    @session_id   = options[:session_id] === 'null' ? nil : options.fetch(:session_id, nil)
  end

  def call
    build_survey_object
    result
  end

  private

  attr_reader :survey_id, :event_id, :account_code, :result, :session_id

  def add_error_message(msg)
    result["error_messages"] << msg
  end

  def get_survey
    surveys = Survey.select('id, event_id, title, description, begins, ends').where(id:survey_id)
    if surveys.length > 0
      surveys.first.as_json['survey']
    else
      add_error_message "Error: No survey found with given survey_id."; false;
    end
  end

  def get_sections
    sections = []
    SurveySection.select('id, survey_sections.order, heading, subheading')
                 .where(survey_id:survey_id)
                 .each do |s|
      sections << s.as_json['survey_section']
    end
    sections
  end

  def get_questions(section_ids)
    questions = []
    Question.select('id, survey_section_id, question_type_id, questions.order, question')
            .where(survey_section_id:section_ids)
            .each do |q|
      questions << q.as_json['question']
    end
    questions
  end

  def get_answers(question_ids)
    answers = []
    Answer.select('id, question_id, answers.order, answer, correct')
          .where(question_id:question_ids)
          .each do |a|
      answers << a.as_json['answer']
    end
    answers
  end

  def get_survey_response
    attendee_id = Attendee.where(event_id:event_id, account_code:account_code).first.id
    SurveyResponse.select('id').where(event_id:event_id, session_id:session_id, survey_id:survey_id, attendee_id:attendee_id).first_or_create.as_json['survey_response']
  end

  def get_responses
    responses = []
    Response.select('id, question_id, answer_id, response, rating')
            .where(survey_response_id:result['survey_response']['id'])
            .each do |r|
      responses << r.as_json['response']
    end
    responses
  end

  def append_survey(survey)
    result['survey'] = survey
    result['survey']['session_id'] = session_id
  end

  def append_sections
    result['survey']['sections'] = get_sections
  end

  def append_questions
    questions = get_questions(return_section_ids)
    result['survey']['sections'].each do |s|
      s['questions'] = questions.select { |q| q['survey_section_id'] == s['id'] }
    end
  end

  def append_answers
    answers = get_answers(return_question_ids)
    result['survey']['sections'].each do |s|
      s['questions'].each do |q|
        q['answers'] = answers.select { |a| a['question_id'] == q['id'] }
      end
    end
  end

  def append_survey_response
    result['survey_response'] = get_survey_response
  end

  def append_responses
    result['survey_response']['responses'] = get_responses
  end

  def return_section_ids
    result['survey']['sections'].map { |s| s['id'] }
  end

  def return_question_ids
    ids = []
    result['survey']['sections'].each { |s| s['questions'].each { |q| ids << q['id'] } }
    ids
  end

  def build_survey_object

    survey = get_survey
    return unless survey

    append_survey(survey)
    append_sections
    append_questions
    append_answers

    if account_code && event_id
      append_survey_response
      append_responses
    end
    result['status'] = true
  end
end
