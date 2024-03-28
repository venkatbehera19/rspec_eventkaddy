class AttendeeSurveyImagesController < ApplicationController
  before_action :authenticate_user!
  #before_action :verify_as_admin
  layout :set_layout

  def index
    @event = Event.find(session[:event_id].to_i)
    @attendees = Attendee.joins(survey_responses: [responses: [question: :question_type]]).where("survey_responses.event_id = #{session[:event_id]} and question_types.name = 'Image Upload' and (responses.response is not null and responses.response != '' )").select("attendees.id,attendees.first_name,attendees.last_name,attendees.account_code,attendees.email, COUNT(responses.id) as total_images").group("attendees.id").as_json
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

  def show
    redirect_back(fallback_location: root_path) if params[:attendee].blank?
    @attendee = Attendee.find_by(event_id: session[:event_id], account_code: params[:attendee])
    @all_attendee_ids_with_images = Attendee.joins(survey_responses: [responses: [question: :question_type]]).where("survey_responses.event_id = #{session[:event_id]} and question_types.name = 'Image Upload' and responses.response is not null").select("attendees.account_code").pluck(:account_code).uniq
    
    current_attendee_index = @all_attendee_ids_with_images.find_index(@attendee.account_code)

    raise "Attendee Not Found in this event" if(@attendee.blank? || current_attendee_index.nil?)

    filter_value = "all"
    params.has_key?(:sort_type) ? filter_value = params[:sort_type] : nil
    @next_attendee_account_code = nil
    @previous_attendee_account_code = nil
    if current_attendee_index == 0
       @next_attendee_account_code = @all_attendee_ids_with_images[1]
    elsif current_attendee_index == @all_attendee_ids_with_images.length-1
      @next_attendee_account_code = @all_attendee_ids_with_images[0]
      @previous_attendee_account_code = @all_attendee_ids_with_images[current_attendee_index-1]
    else
      @next_attendee_account_code = @all_attendee_ids_with_images[current_attendee_index+1]
      @previous_attendee_account_code = @all_attendee_ids_with_images[current_attendee_index-1]
    end

    @attendee_responses = SurveyResponse.get_attendee_image_questions_and_responses(session[:event_id], @attendee.id, filter_value)
    
    @attendee_responses.each do |response|
      file_id = response["response"]
      file = EventFile.find(file_id.to_i)
      authenticated_url = file.return_authenticated_url
      response["url"] = authenticated_url["url"]
    end

    @images_count = @attendee_responses.count

    if request.xhr?
      render 'show.js.erb' and return
    else
      render :show and return
    end
  end

  def download
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
        zip_file_path = Rails.root.join("attendee_survey_images_zips",session[:event_id].to_s,"#{attendee_name}_#{@attendee.id}_zipfile.zip").to_path
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
      raise "Missing Parameter Attendee" if params[:attendee].blank?
      @attendee = Attendee.find_by(event_id: session[:event_id], account_code: params[:attendee])
      raise "Attendee Not Found in this event" if @attendee.blank?
      background_job = BackgroundJob.find_by(entity_type:'Attendee', entity_id: @attendee.id,purpose: "create_zip_file_for_attendee_survey_images",status:'completed')
      raise "Cannot Reset. BackgroundJob Not Found." if background_job.blank?

      attendee_name = (@attendee.first_name.strip+@attendee.last_name.strip).titleize.delete(" ").truncate(20,omission:'')
      zip_file_path = Rails.root.join("attendee_survey_images_zips",session[:event_id].to_s,"#{attendee_name}_#{@attendee.id}_zipfile.zip").to_path
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

  def verify_image
    render json: {status:false, message:"Response ID is blank"} and return if params[:response_id].blank?
    response = Response.find(params[:response_id])
     if response && response.question.question_type_id==6
      response.verified!
      response.update(verified_at: DateTime.now, verifier_id: current_user.id)
      render json: {status:true, message:"Image Verified", image_status:1} and return
     else
      render json: {status:false, message:"Response Not found/Question Type is incorrect"} and return
     end
  end

  def reject_image
    render json: {status:false, message:"Response ID is blank"} and return if params[:response_id].blank?
    response = Response.find(params[:response_id])
    if response && response.question.question_type_id==6
      response.rejected!
      response.update(verified_at: DateTime.now, verifier_id: current_user.id)
      render json: {status:true, message:"Image Verified", image_status:0} and return
    else
      render json: {status:false, message:"Response Not found/Question Type is incorrect"} and return
    end
  end

  def undo_image_status
    render json: {status:false, message:"Response ID is blank"} and return if params[:response_id].blank?
    response = Response.find(params[:response_id])
    if response && response.question.question_type_id==6
      response.pending!
      response.update(verified_at: DateTime.now, verifier_id: current_user.id)
      render json: {status:true, message:"Image on Pending Status", image_status:2} and return
    else
      render json: {status:false, message:"Response Not found/Question Type is incorrect"} and return
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
