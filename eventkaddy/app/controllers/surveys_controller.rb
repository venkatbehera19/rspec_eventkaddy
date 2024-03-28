class SurveysController < ApplicationController

  load_and_authorize_resource :except => [:questions_order,:update_questions_order]
  layout :set_layout
  include ExhibitorPortalsHelper

  def copy_surveys_form
    @surveys = Survey.
      select('surveys.*, events.name AS event_name').
      joins(:event).
      where('events.org_id = ?', Event.find(event_id).org_id)
  end

  def post_copy_surveys_form
    Survey.where( id: params[:survey_ids] ).each {|s| s.copy_to_event event_id }
    redirect_to('/surveys', :notice => 'Copied surveys.')
  end

  def survey_images
    @event = Event.find(session[:event_id].to_i)
    @attendees = Attendee.joins(survey_responses: [{responses: {question: :question_type} }]).where("survey_responses.event_id = #{session[:event_id]} and question_types.name = 'Image Upload' and responses.response is not null").select("attendees.id,attendees.first_name,attendees.last_name,attendees.account_code,attendees.email, COUNT(responses.id) as total_images").group("attendees.id").as_json
    @socket_url = @event.chat_url

    attendee_ids=[]
    @attendees.each do |a|
      a["job_status"] = nil
      attendee_ids << a["id"]
    end

    background_jobs = BackgroundJob.where(entity_id: attendee_ids,entity_type: "Attendee",purpose: "create_zip_file_for_attendee_survey_images").select("entity_id","status").as_json(except: [:id])

    background_jobs.each do |background_job|
      attendee = @attendees.find {|a| a["id"] == background_job["entity_id"] }
      attendee["job_status"] = background_job["status"] unless attendee.blank?
    end
  end

  def attendee_survey_images
    redirect_back(fallback_location: root_path) if params[:attendee].blank?
    @attendee = Attendee.find_by(event_id: session[:event_id], account_code: params[:attendee])
    raise "Attendee Not Found in this event" if @attendee.blank?
    @attendee_responses = SurveyResponse.get_attendee_image_questions_and_responses session[:event_id], @attendee.id
    @attendee_responses.each do |response|
      file_id = response["response"]
      file = EventFile.find(file_id.to_i)
      authenticated_url = file.return_authenticated_url
      response["url"] = authenticated_url["url"]
    end
  end

  def download_attendee_survey_images
    result = {is_success: false, downloadable: false, error_message: "Something went wrong!"}
    begin
      raise "Missing Parameter Attendee" if params[:attendee].blank?
      @attendee = Attendee.find_by(event_id: session[:event_id], account_code: params[:attendee])
      raise "Attendee Not Found in this event" if @attendee.blank?
      background_job = BackgroundJob.find_by(entity_type:'Attendee', entity_id: @attendee.id,purpose: "create_zip_file_for_attendee_survey_images")
      if background_job.blank?
        background_job = BackgroundJob.create(purpose: "create_zip_file_for_attendee_survey_images",status: "started",entity_id: @attendee.id, entity_type: "Attendee")
        CreateZipFileForAttendeeSurveyImagesWorker.perform_async(session[:event_id],@attendee.id)
        result[:is_success] = true
      else
        if background_job.status=="completed"
          result[:is_success] = true
          result[:downloadable] = true
        elsif background_job.status=="error"
          background_job.delete
          background_job = BackgroundJob.create(purpose: "create_zip_file_for_attendee_survey_images",status: "started",entity_id: @attendee.id, entity_type: "Attendee")
          CreateZipFileForAttendeeSurveyImagesWorker.perform_async(@event.id,@attendee.id)
          result[:is_success] = true
        end
      end
    rescue => e
      result[:error_message] = e.message
    end
    if result[:is_success]
      if result[:downloadable]
        attendee_name = (@attendee.first_name.strip+@attendee.last_name.strip).titleize.delete(" ").truncate(20,omission:'')
        zip_file_path = Rails.root.join("attendee_survey_images",session[:event_id].to_s,"#{attendee_name}_#{@attendee.id}_zipfile.zip").to_path
        send_file zip_file_path, filename: zip_file_path.split("/").last, type: "application/zip", disposition: 'attachment'
      else
        render :download_zip_success
      end
    else
      @error_message = result[:error_message]
      render :download_zip_failure
    end
  end

  def reset_attendee_survey_images
    result = {is_success: false, error_message: "Cannot Reset The File,Something went wrong!"}
    begin
      raise "Missing Parameter Attendee" if params[:attendee].blank?
      @attendee = Attendee.find_by(event_id: session[:event_id], account_code: params[:attendee])
      raise "Attendee Not Found in this event" if @attendee.blank?
      background_job = BackgroundJob.find_by(entity_type:'Attendee', entity_id: @attendee.id,purpose: "create_zip_file_for_attendee_survey_images",status:'completed')
      raise "Cannot Reset. BackgroundJob Not Found." if background_job.blank?

      attendee_name = (@attendee.first_name.strip+@attendee.last_name.strip).titleize.delete(" ").truncate(20,omission:'')
      zip_file_path = Rails.root.join("attendee_survey_images",session[:event_id].to_s,"#{attendee_name}_#{@attendee.id}_zipfile.zip").to_path
      raise "Cannot Reset. Zip File Not Found." unless File.exists?(zip_file_path)
      if File.exists?(zip_file_path) && !background_job.blank?
        background_job.delete
        File.delete(zip_file_path)
        result[:is_success] = true
      end
    rescue => e
      result[:error_message] = e.message
    end
    if result[:is_success] == true
      render :reset_attendee_images_zip_success
    else
      @message = e.message
      render :reset_attendee_images_zip_failure
    end
  end

  def index
    exhibitor = get_exhibitor
    unless exhibitor.blank?
      #used in exhibitor's portal
      check_for_payment
      @surveys = Survey.return_exhibitor_surveys(session[:event_id], exhibitor.id)
    else
      @surveys = Survey.return_surveys(session[:event_id])
    end
  end

  def show
    @survey = Survey.find params[:id]
    exhibitor = get_exhibitor
    @survey_data   = JSON.parse(@survey.json) || false
    demo_attendee = Attendee.where(event_id:session[:event_id], first_name:"Survey Test", last_name:"User", is_demo:true).first_or_create
    session[:demo_attendee_id] = demo_attendee.id
    if @survey_data && @survey_data !=false
      if !exhibitor.blank?
        @survey_response = SurveyResponse.where(event_id:session[:event_id], attendee_id:demo_attendee.id, attendee_account_code:demo_attendee.account_code, survey_id:@survey_data['id'], exhibitor_id:exhibitor['id']).first_or_create
      else
        @survey_response = SurveyResponse.where(event_id:session[:event_id], attendee_id:demo_attendee.id, attendee_account_code:demo_attendee.account_code, survey_id:@survey_data['id']).first_or_create
      end
    end
  end

  def destroy
    Survey.find(params[:id]).destroy
    redirect_to('/surveys', :notice => 'Survey was successfully destroyed.')
  end

  def associations
    @survey   = Survey.find params[:id]
    @selected = SurveySession.where(survey_id:params[:id]).pluck(:session_id)
    @sessions = Session.select('id, event_id, title, session_code').where(event_id:session[:event_id])
  end

  def update_associations
    sessions = params[:session_ids]
    @survey  = Survey.find(params[:survey][:id])

    @survey.update_associations(params)

    respond_to do |format|
      format.html { redirect_to "/surveys/associations/#{@survey.id}", :notice => 'Sessions successfully associated with survey.' }
    end
  end

  # This is a bit confusing, but right now this is about lead exhibitors
  # In the future, if we had a survey for attendees to fill out about exhibitors they
  # visited, we would use the same table, but based on the survey_type_id, treat that
  # data differently
  def exhibitor_associations
    @survey   = Survey.find params[:id]
    @selected = SurveyExhibitor.where(survey_id:params[:id]).pluck(:exhibitor_id)
    @exhibitors = Exhibitor.select('id, event_id, company_name, exhibitor_code').where(event_id:session[:event_id])
  end

  def update_exhibitor_associations
    exhibitors = params[:exhibitor_ids]
    @survey  = Survey.find(params[:survey][:id])

    @survey.update_exhibitor_associations(params)

    respond_to do |format|
      format.html { redirect_to "/surveys/exhibitor_associations/#{@survey.id}", :notice => 'Exhibitors successfully associated with survey.' }
    end
  end

  def ce_certificate_associations
    @survey   = Survey.find params[:id]
    @selected = SurveyCeCertificate.where(survey_id:params[:id]).pluck(:ce_certificate_id)
    @ce_certificates = CeCertificate.select('id, event_id, name').where(event_id:session[:event_id])
  end

  def update_ce_certificate_associations
    ce_certificates = params[:ce_certificate_id]
    @survey  = Survey.find(params[:survey][:id])

    @survey.update_ce_certificate_associations(params)

    respond_to do |format|
      format.html { redirect_to "/surveys/ce_certificate_associations/#{@survey.id}", :notice => 'CE-Certificates successfully associated with survey.' }
    end
  end

  def questions_order
    @survey_section = SurveySection.find params[:survey_section_id]
    @survey         = Survey.find @survey_section.survey_id
    @questions      = @survey_section.questions.order('questions.order')
  end

  def update_questions_order
    @survey_section = SurveySection.find params[:survey_section][:id]
    @survey_section.updateQuestionPositions(params[:json]) unless params[:json].blank?

    respond_to do |format|
      format.html { redirect_to "/surveys/questions_order/#{@survey_section.id}", :notice => 'Successfully reordered questions.' }
    end
  end

  def get_response_for_question (question_id, survey_response_id)
    #find the response for the question.
    @response = Response.select("id, event_id, survey_response_id, question_id, answer_id, response, rating").from("responses").where(survey_response_id: survey_response_id , question_id: question_id, event_id: session[:event_id]).first
    if !@response
        @response = Response.new
        @response.survey_response_id = survey_response_id
        @response.question_id = question_id
        @response.event_id = session[:event_id]
    end
    if !@response.rating
      @response.rating = 0
    end
    return @response
  end
  helper_method :get_response_for_question

  def upload_survey_response
    Survey.process_survey params, session[:event_id], session[:demo_attendee_id]
    redirect_to '/exhibitor_portals/surveys', notice: 'You have submitted a test survey.'
  end

  private

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

end
