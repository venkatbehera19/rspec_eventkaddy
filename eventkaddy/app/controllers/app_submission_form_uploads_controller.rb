class AppSubmissionFormUploadsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_user_role
  before_action :set_event

  def create
    begin
      file_type               = request.headers["X-Image-Type"]
      form_type               = request.headers["X-Form-Type"]
      uploaded_io             = params[:app_submission_form][file_type]
      event_file_type_id      = EventFileType.where(name: "#{file_type}_img").first.id
      filename                = uploaded_io.original_filename
      file_extension          = File.extname uploaded_io.original_filename
      event_file              = EventFile.where(event_id: @event.id, event_file_type_id: event_file_type_id).first_or_initialize
      target_path 						= Rails.root.join('event_app_form_data', @event.id.to_s,'uploaded_images',form_type,file_type).to_path
      cloud_storage_type      = nil
      UploadEventFileImage.new(
        event_file:              event_file,
        image:                   uploaded_io,
        target_path:             target_path,
        new_filename:            filename,
        event_file_owner: 			 @event,
        cloud_storage_type:      cloud_storage_type,
        required_image_size:     AppSubmissionForm::APP_SUBMISSION_FORM_UPLOAD_DIMENSIONS[form_type][file_type],
        upload_for_mobile_forms: true
      ).call
      render plain: filename.to_s
    rescue => e
      return render json: {message: e.message},status: 400
    end
  end

  def show
    begin
      file_type               = request.headers["X-Image-Type"]
      event_file_type_id      = EventFileType.find_by!(name: "#{file_type}_img").id
      event_file              = EventFile.find_by!(event_id: @event.id, event_file_type_id: event_file_type_id)
      target_path 						= Rails.root.join('event_app_form_data').to_path
      file                    = File.open("#{target_path}#{event_file.path}", 'rb') {|file| file.read }
      raise "File not found" if file.blank?
      send_data file, :type => event_file.mime_type, :disposition => "inline; filename=#{event_file.name}"
    rescue => e
      return render json: {message: e.message},status: 400
    end
  end

  def download_zip
    result = {is_success: false, downloadable: false, error_message: "Something went wrong!"}
    begin
      app_submission_form = AppSubmissionForm.find_by!(id: params[:form_id])
      @form_type  = app_submission_form.app_form_type.name
      @form_id    = app_submission_form.id
      @socket_url = @event.chat_url
      background_job = BackgroundJob.find_by(entity_id: app_submission_form.id,entity_type: "AppSubmissionForm")
      if background_job.blank?
        background_job = BackgroundJob.create(purpose: "create_zip_file_for_app_images",status: "started",entity_id: app_submission_form.id, entity_type: "AppSubmissionForm")
        CreateZipFileForAppImagesWorker.perform_async(@event.id,app_submission_form.id)
        result[:is_success] = true
      else
        if background_job.status=="completed"
          result[:is_success] = true
          result[:downloadable] = true
        elsif background_job.status=="error"
          background_job.delete
          background_job = BackgroundJob.create(purpose: "create_zip_file_for_app_images",status: "started",entity_id: app_submission_form.id, entity_type: "AppSubmissionForm")
          CreateZipFileForAppImagesWorker.perform_async(@event.id,app_submission_form.id)
          result[:is_success] = true
        end
      end
    rescue => e
      result[:error_message] = e.message
    end
    if result[:is_success]
      if result[:downloadable]
        zip_file_path = Rails.root.join('event_app_form_data',"#{@event.id}","form_zip_files","#{@form_type}.zip").to_path
        send_file zip_file_path, filename: zip_file_path.split("/").last, type: "application/zip", disposition: 'attachment'
      else
        render :download_zip_success
      end
    else
      @error_message = result[:error_message]
      render :download_zip_failure
    end
  end

  private

  def set_event
    @event = Event.find(session[:event_id])
  end

  def verify_user_role
    raise "Your not authorized for this action" unless (current_user.role?("SuperAdmin") || current_user.role?("Client"))
  end

end
