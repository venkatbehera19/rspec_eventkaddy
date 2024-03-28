class SurveyWizardController < ApplicationController

  after_action :update_survey_json, only: [:save_survey,:save_survey_section,:save_question,:save_answer,:save_hint,:delete_survey_section,:delete_question,:delete_answer,:delete_hint]
  layout :set_layout


  def survey_wizard
    authorize! :survey_wizard, :all
    exhibitor = get_exhibitor
    unless exhibitor.blank?
      #for exhibitor's portal
      surveys = Survey.joins(:survey_exhibitors).where(id:params[:id], event_id:session[:event_id]).where('survey_exhibitors.exhibitor_id=?', exhibitor.id)
      @survey = surveys.length > 0 ? surveys.first : Survey.new
    else
      surveys = Survey.where(id:params[:id], event_id:session[:event_id])
      @survey = surveys.length > 0 ? surveys.first : Survey.new
    end

    render 'surveys/survey_wizard'
  end

  def get_survey
    render :json => Survey.wizard_survey(params)
  end

  def get_survey_sections
    render :json => Survey.wizard_survey_sections(params)
  end

  def get_survey_section
    render :json => Survey.wizard_survey_section(params)
  end

  def get_questions
    render :json => Survey.wizard_questions(params)
  end

  def get_question
    render :json => Survey.wizard_question(params)
  end

  def get_answers
    render :json => Survey.wizard_answers(params)
  end

  def get_hints
    render :json => Survey.wizard_hints(params)
  end

  def save_survey
    params[:event_id] = session[:event_id]
    surveys           = Survey.where(id:params[:id])
    @survey_id = params[:id]

    params.reject { |k| k == 'id' || k == 'controller' || k == 'action' }

    if surveys.length === 0
      survey = Survey.create(survey_params)
      response = {'status' => true, 'id' => survey.id, 'messages' => ['Successfully created survey.']}
      exhibitor = get_exhibitor
      unless exhibitor.blank?
        SurveyExhibitor.where(survey_id:survey.id, exhibitor_id:exhibitor.id, event_id:session[:event_id]).first_or_create
      end
    elsif surveys.length === 1
      surveys.first.update!(survey_params)
      response = {'status' => true, 'id' => surveys.first.id, 'messages' => ['Successfully updated survey.']}
    else
      response = {'status' => false, 'errors' => ['Survey could not be saved.']}
    end

    render :json => response

  end

  def save_survey_section
    params[:event_id] = session[:event_id]
    survey_sections   = SurveySection.where(id:params[:id])

    params.reject! { |k| k == 'id' || k == 'controller' || k == 'action' }

    if survey_sections.length === 0
      survey_section = SurveySection.create(survey_section_params)
      response       = {'status' => true, 'id' => survey_section.id, 'messages' => ['Successfully created survey section.']}
      @survey_id = survey_section.survey_id
    elsif survey_sections.length === 1
      survey_sections.first.update!(survey_section_params)
      response = {'status' => true, 'id' => survey_sections.first.id, 'messages' => ['Successfully updated survey section.']}
      @survey_id = survey_sections.first.survey_id
    else
      response = {'status' => false, 'errors' => ['SurveySection could not be saved.']}
    end

    render :json => response
  end

  def save_question

    params[:event_id] = session[:event_id]
    questions         = Question.where(id:params[:id])

    params.reject! { |k| k == 'id' || k == 'controller' || k == 'action' }

    if questions.length === 0
      question = Question.create(question_params)
      response = {'status' => true, 'id' => question.id, 'messages' => ['Successfully created question.']}
      @survey_id = question.survey_id
    elsif questions.length === 1
      questions.first.update!(question_params)
      response = {'status' => true, 'id' => questions.first.id, 'messages' => ['Successfully updated question.']}
      @survey_id = questions.first.survey_id
    else
      response = {'status' => false, 'errors' => ['Question could not be saved.']}
    end

    render :json => response

  end

  def save_answer

    params[:event_id] = session[:event_id]
    answers           = Answer.where(id:params[:id])

    params.reject! { |k| k == 'id' || k == 'controller' || k == 'action' || k == 'survey_id' }
    handler = nil
    if answers.length === 0
      if params[:handler] && params[:handler].length > 0
        handler = AnswerHandler.new(handler: params[:handler])
        handler.save
      end
      answer = Answer.create(answer_params.merge({answer_handler_id: handler&.id}))
      response = {'status' => true, 'id' => answer.id, 'messages' => ['Successfully created answer.']}
      @survey_id = answer.question.survey_id
    elsif answers.length === 1
      answer = answers.first
      handler = answer.answer_handler || AnswerHandler.new
      if params[:handler] && params[:handler].length > 0
        handler.handler = params[:handler]
        handler.save
      end
      answers.first.update!(answer_params.merge({answer_handler_id: handler.id}))
      response = {'status' => true, 'id' => answers.first.id, 'messages' => ['Successfully updated answer.']}
      @survey_id = answers.first.question.survey_id
    else
      response = {'status' => false, 'errors' => ['Answer could not be saved.']}
    end

    render :json => response
  end

  def save_hint

    params[:event_id] = session[:event_id]
    hints             = Hint.where(id:params[:id])

    params.reject! { |k| k == 'id' || k == 'controller' || k == 'action' || k == 'survey_id' }

    if hints.length === 0
      hint = Hint.create(hint_params)
      response = {'status' => true, 'id' => hint.id, 'messages' => ['Successfully created hint.']}
      @survey_id = hint.question.survey_id
    elsif hints.length === 1
      hints.first.update!(hint_params)
      response = {'status' => true, 'id' => hints.first.id, 'messages' => ['Successfully updated hint.']}
      @survey_id = hints.first.question.survey_id
    else
      response = {'status' => false, 'errors' => ['Hint could not be saved.']}
    end

    render :json => response
  end

  def delete_survey_section
    survey_section = SurveySection.find(params[:id])
    @survey_id = survey_section.survey_id
    if survey_section.destroy
      response = {'status' => true, 'messages' => ['Successfully deleted survey section.']}
    else
      response = {'status' => false, 'messages' => ['An error occured while deleting your survey section.']}
    end

    render :json => response
  end

  def delete_question

    question = Question.find(params[:id])
    @survey_id = question.survey_id

    if question.destroy
      response = {'status' => true, 'messages' => ['Successfully deleted question.']}
    else
      response = {'status' => false, 'messages' => ['An error occured while deleting your question.']}
    end

    render :json => response
  end

  def delete_answer

    answer = Answer.find(params[:id])
    @survey_id = answer.question.survey_id

    if answer.destroy
      response = {'status' => true, 'messages' => ['Successfully deleted question.']}
    else
      response = {'status' => false, 'messages' => ['An error occured while deleting your question.']}
    end

    render :json => response
  end

  def delete_hint

    hint = Hint.find(params[:id])
    @survey_id = hint.question.survey_id

    if hint.destroy
      response = {'status' => true, 'messages' => ['Successfully deleted hint.']}
    else
      response = {'status' => false, 'messages' => ['An error occured while deleting your hint.']}
    end

    render :json => response
  end

  private

  def update_survey_json
    if @survey_id
      result = HashifySurvey.new(@survey_id).call
      if result['status']
        Survey.find(@survey_id).update!(json:result['survey'].to_json)
      end
    end
  end

  def get_exhibitor
    if current_user.role? :exhibitor then
      if current_user.is_a_staff?
        es = ExhibitorStaff.find_by_user_id current_user.id
        return Exhibitor.find es.exhibitor_id
      else
        current_user.first_or_create_exhibitor( session[:event_id] )
      end
    end
  end

  def set_layout
    if current_user.role? :speaker
      'speakerportal_2013'
    elsif current_user.role? :exhibitor
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  def hint_params
    params.permit(:event_id, :question_id, :order, :hint)
  end

  def question_params
    params.permit(:event_id, :survey_section_id, :survey_id, :question_type_id, :order, :question)
  end

  def answer_params
    params.permit(:answer, :correct, :order, :event_id, :question_id)
  end

  def survey_params
    params.permit(:id, :event_id, :survey_type_id, :publish_to_attendee_survey_results, :title, :description, :begins, :ends,
       :post_action, :submit_success_message, :submit_failure_message, :disallow_editing, :special_location, :json)
  end

  def survey_section_params
    params.permit(:heading, :order, :subheading, :survey_id, :event_id)
  end
end
