class HashifySurvey
  def initialize(survey_id)
    @survey_id    = survey_id
    @result       = {"status" => false, "error_messages" => []}
  end

  def call
    build_survey_object
    result
  end

  private

  attr_reader :survey_id, :result

  def add_error_message(msg)
    result["error_messages"] << msg
  end

  def get_survey
    surveys = Survey.select(
      'id,
      event_id,
      title,
      description,
      begins,
      ends,
      survey_type_id,
      post_action,
      submit_success_message,
      submit_failure_message,
      disallow_editing,
      special_location').where(id:survey_id)
    surveys.length > 0 ? surveys.first.as_json(root: false)
                       : (add_error_message("Error: No survey found with given survey_id."); false;)
  end

  def get_sections
    sections = []
    SurveySection.select('id, survey_sections.order, heading, subheading').where(survey_id:survey_id).each {|s| sections << s.as_json(root: false) }
    sections
  end

  def get_questions(section_ids)
    questions = []
    Question.select('id, survey_section_id, question_type_id, questions.order, question')
            .where(survey_section_id:section_ids)
            .each {|q|
              questions << q.as_json(root: false)}
    questions
  end

  def get_answers(question_ids)
    answers = []
    Answer.select('id, question_id, answers.order, answer, correct, answer_handler_id')
          .where(question_id:question_ids)
          .each {|a|
            answers << a.as_json(root: false).merge({handler: a.answer_handler&.handler})}
    answers
  end

  def append_survey(survey)
    result['survey'] = survey
  end

  def append_sections
    result['survey']['sections'] = get_sections
  end

  def append_questions
    questions = get_questions(return_section_ids)
    result['survey']['sections'].each {|s|
      s['questions'] = questions.select {|q|
        q['survey_section_id'] == s['id'] }}
  end

  def append_answers
    answers = get_answers(return_question_ids)
    result['survey']['sections'].each {|s|
      s['questions'].each {|q|
        q['answers'] = answers.select {|a|
          a['question_id'] == q['id'] }}}
  end

  def return_section_ids
    result['survey']['sections'].map {|s|
      s['id']}
  end

  def return_question_ids
    ids = []
    result['survey']['sections'].each {|s|
      s['questions'].each {|q|
        ids << q['id']}}
    ids
  end

  def build_survey_object
    survey = get_survey
    return unless survey

    append_survey(survey)
    append_sections
    append_questions
    append_answers

    result['status'] = true
  end
end
