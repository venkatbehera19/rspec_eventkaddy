# the mixins/finders pattern is something I read a long time ago; we keep
# the existing ones as legacy, but shouldn't make them anymore. My opinion
# now is that "Finder" is already the concept encompassed by an active record
# model, and it makes no sense to have a module that is only useful to one
# class.

module SurveyFinders

  def return_surveys(event_id)
    Survey.find_by_sql [
      'SELECT surveys.id,
              title,
              begins,
              ends,
              survey_types.name AS type_name,
              post_action,
              submit_success_message,
              submit_failure_message,
              disallow_editing,
              publish_to_attendee_survey_results,
              special_location
      FROM surveys
      LEFT JOIN survey_types ON survey_types.id=surveys.survey_type_id
      WHERE event_id=?
      ORDER BY type_name, title', event_id]
    #   .select('surveys.id, title, begins, ends, type_name AS survey_types.name')
    #   .joins('JOIN survey_types ON survey_types.id = surveys.survey_type_id')
    #   .where(event_id:event_id)
    #   .order('type_name, title')
  end

  def return_exhibitor_surveys(event_id, exhibitor_id)
    Survey.find_by_sql [
      'SELECT surveys.id,
              title,
              begins,
              ends,
              survey_types.name AS type_name,
              post_action,
              submit_success_message,
              submit_failure_message,
              disallow_editing,
              publish_to_attendee_survey_results,
              special_location
      FROM surveys
      LEFT JOIN survey_types ON survey_types.id=surveys.survey_type_id
      LEFT JOIN survey_exhibitors ON survey_exhibitors.survey_id=surveys.id
      WHERE surveys.event_id=? && survey_exhibitors.exhibitor_id=?
      ORDER BY type_name, title', event_id, exhibitor_id]
    #   .select('surveys.id, title, begins, ends, type_name AS survey_types.name')
    #   .joins('JOIN survey_types ON survey_types.id = surveys.survey_type_id')
    #   .where(event_id:event_id)
    #   .order('type_name, title')
  end

  ## Survey Wizard Finders

  def wizard_survey(params)
    unless params[:id].blank?
      Survey.include_root_in_json = true
      surveys = Survey.select(
        'id,
        title,
        description,
        begins,
        ends,
        survey_type_id,
        post_action,
        submit_success_message,
        submit_failure_message,
        disallow_editing,
        publish_to_attendee_survey_results,
        special_location').where(id:params[:id])
      surveys.length > 0 ? surveys.first : {status:false,errors:['No survey found with id' + params[:id] + '.']}
    else
      {survey: {id: nil, title: nil, description: nil, begins: nil, ends: nil, survey_type_id:nil}}
    end
  end

  def wizard_survey_sections(params)
    unless params[:survey_id].blank?
      SurveySection.include_root_in_json = true

      survey_sections = SurveySection.select('id, survey_id, survey_sections.order, heading, subheading')
                                     .where(survey_id:params[:survey_id])
                                     .order('survey_sections.order')
      
      survey_sections.length > 0 ? survey_sections : {status:false,errors:['No survey section found with survey id' + params[:survey_id] + '.']}
    else
      {'status' => false, 'errors' => ['No survey sections found.']}
    end
  end

  def wizard_survey_section(params)
    unless params[:id].blank?
      SurveySection.include_root_in_json = true
      survey_sections = SurveySection.select('id, survey_id, survey_sections.order, heading, subheading')
                                .where(id:params[:id])
      survey_sections.length > 0 ? survey_sections.first : {status:false,errors:['No survey section found with id' + params[:id] + '.']}
    else
      {survey_section: {id: nil, survey_id: nil, order: nil, heading: nil, subheading: nil}}
    end
  end

  def wizard_questions(params)
    unless params[:survey_id].blank?
      Question.include_root_in_json = true
      questions = Question.select('id, survey_section_id, survey_id, question_type_id, questions.order, question')
                          .where(survey_id:params[:survey_id])
                          .order('questions.order')
      questions.length > 0 ? questions : {status:false,errors:['No question found with survey id' + params[:survey_id] + '.']}
    else
      {'status' => false, 'errors' => ['No questions found.']}
    end
  end

  def wizard_question(params)
    unless params[:id].blank?
      Question.include_root_in_json = true
      questions = Question.select('id, survey_section_id, survey_id, question_type_id, order, question')
                          .where(id:params[:id])
      questions.length > 0 ? questions.first : {status:false,errors:['No question found with id' + params[:id] + '.']}
    else
      {question: {id: nil, survey_section_id: nil, survey_id: nil, question_type_id: nil, order: nil, question: nil}}
    end
  end

  def wizard_answers(params)
    unless params[:survey_id].blank?
      Answer.include_root_in_json = true
      answers = Answer.find_by_sql [
                "SELECT answers.id, answers.question_id, answers.order, answers.answer, answers.correct, answer_handlers.handler as handler
                FROM (answers
                JOIN questions on answers.question_id=questions.id) LEFT JOIN answer_handlers on answers.answer_handler_id=answer_handlers.id
                where questions.survey_id=?
                ORDER BY answers.order",params[:survey_id].to_i]
      answers.length > 0 ? answers : {status:false,errors:['No answer found for survey id' + params[:survey_id] + '.']}
    else
      {'status' => false, 'errors' => ['No answers found.']}
    end
  end

  def wizard_hints(params)
    unless params[:survey_id].blank?
      Hint.include_root_in_json = true
      hints = Hint.find_by_sql [
                "SELECT hints.id, hints.question_id, hints.order, hints.hint
                FROM hints
                JOIN questions ON questions.survey_id=?
                WHERE hints.question_id=questions.id",params[:survey_id].to_i]
      hints.length > 0 ? hints : {status:false,errors:['No hint found for survey id' + params[:survey_id] + '.']}
    else
      {'status' => false, 'errors' => ['No hints found.']}
    end
  end

end
