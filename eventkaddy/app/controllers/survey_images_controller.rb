class SurveyImagesController < ApplicationController
  before_action :authenticate_user!
  #before_action :verify_as_admin
  layout :set_layout

  def index
    @event = Event.find(session[:event_id].to_i)
    @surveys = Survey.joins(survey_responses: [responses: [question: :question_type]]).where("survey_responses.event_id = #{session[:event_id]} and (responses.response is not null and responses.response != '' ) and question_types.name = 'Image Upload'").uniq.as_json(root: false)
    @socket_url = @event.chat_url

    survey_ids=[]
    @surveys.each do |a|
      a["job_status"] = nil
      survey_ids << a["id"]
    end

    background_jobs = BackgroundJob.where(entity_id: survey_ids,entity_type: "Survey",purpose: "create_zip_file_for_survey_images").select("entity_id","status").as_json(except: [:id])

    background_jobs.each do |background_job|
      survey = @surveys.find {|a| a["id"] == background_job["entity_id"] }
      survey["job_status"] = background_job["status"] unless survey.blank?
    end
  end

  def show
    redirect_back(fallback_location: root_path) if params[:id].blank?
    @survey = Survey.find_by(event_id: session["event_id"], id: params[:id]) 
    raise "Survey Not Found in this event" if @survey.blank?
    filter_value = "all"
    params.has_key?(:sort_type) ? filter_value = params[:sort_type] : nil
    attendee_search = params["attendee"].to_s
    @survey_responses = SurveyResponse.get_survey_image_questions_and_responses session[:event_id], @survey.id, filter_value, attendee_search
    @survey_responses.each do |response|
      file_id = response["response"]
      file = EventFile.find_by(id: file_id.to_i)
      if file
        authenticated_url = file.return_authenticated_url
        response["url"] = authenticated_url["url"]
      else
        response["url"] = ''
      end
    end
    @images_count = @survey_responses.count
    if request.xhr?
      render 'show.js.erb' and return
    else
      render :show and return
    end
  end

  def download
    result = {is_success: false, downloadable: false, error_message: "Something went wrong!"}
    begin
      raise "Missing Parameter Survey" if params[:survey].blank?
      @survey = Survey.find_by(event_id: session[:event_id], id: params[:survey])
      raise "Survey Not Found in this event" if @survey.blank?
      background_job = BackgroundJob.find_by(entity_type:'Survey', entity_id: @survey.id,purpose: "create_zip_file_for_survey_images")
      if background_job.blank?
        background_job = BackgroundJob.create(purpose: "create_zip_file_for_survey_images",status: "started",entity_id: @survey.id, entity_type: "Survey")
        CreateZipFileForSurveyImagesWorker.perform_async(session[:event_id],@survey.id)
        result[:is_success] = true
      else
        if background_job.status=="completed"
          result[:is_success] = true
          result[:downloadable] = true
        elsif background_job.status=="error"
          background_job.delete
          background_job = BackgroundJob.create(purpose: "create_zip_file_for_survey_images",status: "started",entity_id: @survey.id, entity_type: "Survey")
          CreateZipFileForSurveyImagesWorker.perform_async(@event.id,@survey.id)
          result[:is_success] = true
        end
      end
    rescue => e
      result[:error_message] = e.message
    end
    if result[:is_success]
      if result[:downloadable]
        survey_name = (@survey.title).titleize.delete(" ").truncate(20,omission:'')
        zip_file_path = Rails.root.join("survey_images_zips",session[:event_id].to_s,"#{survey_name}_#{@survey.id}_zipfile.zip").to_path
        send_file zip_file_path, filename: zip_file_path.split("/").last, type: "application/zip", disposition: 'attachment'
      else
        render :download_zip_success
      end
    else
      @error_message = result[:error_message]
      render :download_zip_failure
    end
  end

  def reset
    result = {is_success: false, error_message: "Cannot Reset The File,Something went wrong!"}
    begin
      raise "Missing Parameter Survey" if params[:survey].blank?
      @survey = Survey.find_by(event_id: session[:event_id], id: params[:survey])
      raise "Survey Not Found in this event" if @survey.blank?
      background_job = BackgroundJob.find_by(entity_type:'Survey', entity_id: @survey.id,purpose: "create_zip_file_for_survey_images",status:'completed')
      raise "Cannot Reset. BackgroundJob Not Found." if background_job.blank?

      survey_name = (@survey.title).titleize.delete(" ").truncate(20,omission:'')
      zip_file_path = Rails.root.join("survey_images_zips",session[:event_id].to_s,"#{survey_name}_#{@survey.id}_zipfile.zip").to_path
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
      render :reset_survey_images_zip_success
    else
      @message = e.message
      render :reset_survey_images_zip_failure
    end
  end

  def attenee_list_not_completed_survey
    event_id = session[:event_id]
    survey_id = params[:survey_id]
    attendee_search = params[:attendee]
    params[:page] = 1 unless params[:page]
    page = params[:page]
    question_ids = Question.where(survey_id: survey_id.to_i,question_type_id: 6).ids
    response = Response.joins(survey_response: :survey).select("survey_responses.attendee_id as attendee").where(survey: {id: survey_id.to_i}, question_id: question_ids).where.not(response: "").where.not(response: nil)
    survey_attend_attendee_ids = response.map(&:attendee)
    @attendee_not_gave_survey = Attendee.where(event_id: event_id).where.not(id: survey_attend_attendee_ids).order(:first_name)
    @attendee_not_gave_survey = @attendee_not_gave_survey.where("first_name like ? or last_name like ?", "%#{params["attendee"]}%", "%#{params["attendee"]}%") if attendee_search.present? and attendee_search.length > 0
    @total_pages = @attendee_not_gave_survey.count / 30
    @attendee_not_gave_survey = @attendee_not_gave_survey.paginated_data(page: params[:page], per_page: 30)
    render partial: 'attendee_list'
  end

  def unattended_attendee_report
    event_id = session[:event_id]
    event = Event.find_by(id: event_id)
    survey_id = params[:survey_id]
    survey = Survey.find_by(id: survey_id)
    question_ids = Question.where(survey_id: survey_id.to_i,question_type_id: 6).ids
    response = Response.joins(survey_response: :survey).select("survey_responses.attendee_id as attendee").where(survey: {id: survey_id.to_i}, question_id: question_ids).where.not(response: "").where.not(response: nil)
    survey_attend_attendee_ids = response.map(&:attendee)
    @attendee_not_gave_survey = Attendee.where(event_id: event_id).where.not(id: survey_attend_attendee_ids).order(:first_name)
    render xlsx: "unattended_attendee_report", filename: "#{event.name}_#{survey.title}_unattended_attendee_report.xlsx", formats: [:xlsx]
  end

  def attended_attendee_report
    event_id = session[:event_id]
    event = Event.find_by(id: event_id)
    survey_id = params[:survey_id]
    survey = Survey.find_by(id: survey_id)
    question_ids = Question.where(survey_id: survey_id.to_i,question_type_id: 6).ids
    response = Response.joins(survey_response: :survey).select("survey_responses.attendee_id as attendee").where(survey: {id: survey_id.to_i}, question_id: question_ids).where.not(response: "").where.not(response: nil)
    survey_attend_attendee_ids = response.map(&:attendee)
    @attendee_not_gave_survey = Attendee.where(event_id: event_id, id: survey_attend_attendee_ids).order(:first_name)
    render xlsx: "unattended_attendee_report", filename: "#{event.name}_#{survey.title}_attended_attendee_report.xlsx", formats: [:xlsx]
  end

  def delete_survey_images
    errors = "No Images Found To Delete"
    if params["ids"].present?
      message = "Response Deleted"
      responses = Response.where(id: params["ids"])
      begin
        ActiveRecord::Base.transaction do
          responses.each do |response|
            event_file = EventFile.find_by(id: response.response.to_i)
            event_file.destroy if event_file
            response.destroy
          end
        end
      rescue StandardError => e
        message = e.message
      end
      render json: {message: message}, status: 200
    else
      render json: errors
    end
    
  end


  private

  def verify_as_admin
    raise "Your not authorized for this action" unless current_user.role?("SuperAdmin")
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
