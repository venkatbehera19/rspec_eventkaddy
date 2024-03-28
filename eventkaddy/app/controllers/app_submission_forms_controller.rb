class AppSubmissionFormsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_user_role
  before_action :find_event
  layout 'subevent_2013'

  def index
    params[:form_type].blank? ? @form_type="ios" : @form_type=params[:form_type]
    @socket_url = @event.chat_url
    create_instance_variables_for_ios
    create_instance_variables_for_android
  end

  def create
    app_submission_form  = nil
    creation_notice      = nil
    @form_type           = nil
    @show_ios_images_on_fail     = false
    @show_android_images_on_fail = false
    form_params = app_submission_form_params.except(:ios_app_icon,:android_app_icon,:android_portrait_splash_screen,:android_landscape_splash_screen)
    if app_submission_form_params[:app_form_type_id].to_i == ANDROID_ID
      @form_type = "android"
      @app_submission_form_android = AppSubmissionForm.new(form_params.merge(event_id: session[:event_id]))
      app_submission_form = @app_submission_form_android
      creation_notice = "Android App submission form was successfully created."
    else
      @form_type = "ios"
      @app_submission_form_ios = AppSubmissionForm.new(form_params.merge(event_id: session[:event_id]))
      app_submission_form = @app_submission_form_ios
      creation_notice = "IOS App submission form was successfully created."
    end

    if app_submission_form.save
      background_job = BackgroundJob.create(purpose: "create_zip_file_for_app_images",status: "started",entity_id: app_submission_form.id, entity_type: "AppSubmissionForm")
      CreateZipFileForAppImagesWorker.perform_async(session[:event_id],app_submission_form.id)
      redirect_to app_submission_forms_path(form_type: @form_type), notice: creation_notice and return
    else
      @socket_url = Event.find_by(id: session[:event_id]).chat_url
      if @form_type == "ios"
        @app_submission_form_ios = app_submission_form
        @is_ios_new_record       = true
        @job_status_ios          = nil
        @show_ios_images_on_fail = true
        create_instance_variables_for_android
      else
        @app_submission_form_android = app_submission_form
        @is_android_new_record       = true
        @job_status_android          = nil
        @show_android_images_on_fail = true
        create_instance_variables_for_ios
      end
      render :index, status: :unprocessable_entity and return
    end
  end

  # PATCH/PUT /app_submission_forms/1 or /app_submission_forms/1.json
  def update
    app_submission_form = nil
    update_notice       = nil
    @form_type           = nil
    if app_submission_form_params[:app_form_type_id].to_i == ANDROID_ID
      @form_type = "android"
      @app_submission_form_android = AppSubmissionForm.find(params[:id])
      app_submission_form = @app_submission_form_android
      @app_submission_form_android.restart_job_if_new_android_image(app_submission_form_params[:android_app_icon],app_submission_form_params[:android_portrait_splash_screen],app_submission_form_params[:android_landscape_splash_screen])
      update_notice       = "Android App submission form was successfully updated."
    else
      @form_type = "ios"
      @app_submission_form_ios     = AppSubmissionForm.find(params[:id])
      app_submission_form = @app_submission_form_ios
      @app_submission_form_ios.restart_job_if_new_ios_image(app_submission_form_params[:ios_app_icon])
      update_notice        = "IOS App submission form was successfully updated."
    end
    form_params = app_submission_form_params.except(:ios_app_icon,:android_app_icon,:android_portrait_splash_screen,:android_landscape_splash_screen)
    if app_submission_form.update(form_params)
      redirect_to app_submission_forms_path(form_type: @form_type), notice: update_notice and return
    else
      @socket_url = Event.find_by(id: session[:event_id]).chat_url
      if @form_type == "ios"
        create_instance_variables_for_existing_ios_form
        create_instance_variables_for_android
      else
        create_instance_variables_for_existing_android_form
        create_instance_variables_for_ios
      end
      render :index, status: :unprocessable_entity and return
    end
    
  end

  private

    def find_event
      @event = Event.find(session[:event_id])
    end

    # Only allow a list of trusted parameters through.
    def app_submission_form_params
      params.require(:app_submission_form).permit(:app_name, :subtitle, :description, :keywords, :app_form_type_id,:ios_app_icon,:android_app_icon,:android_portrait_splash_screen,:android_landscape_splash_screen)
    end

    def verify_user_role
    raise "Your not authorized for this action" unless (current_user.role?("SuperAdmin") || current_user.role?("Client"))
  end

    def create_instance_variables_for_ios
      @app_submission_form_ios = AppSubmissionForm.where(event_id: session[:event_id],app_form_type: AppFormType.ios).first_or_initialize
      @job_status_ios = nil
      if @app_submission_form_ios.new_record?
        @is_ios_new_record = true
      else
        create_instance_variables_for_existing_ios_form
      end
    end

    def create_instance_variables_for_existing_ios_form
      @is_ios_new_record = false
      background_job_ios = BackgroundJob.find_by(entity_type: @app_submission_form_ios.class, entity_id: @app_submission_form_ios.id)
      @form_id_ios = @app_submission_form_ios.id
      if !background_job_ios.blank?
        @job_status_ios    = background_job_ios.status
        @error_message_ios = background_job_ios.fail_message
      end
    end

    def create_instance_variables_for_android
      @app_submission_form_android = AppSubmissionForm.where(event_id: session[:event_id], app_form_type: AppFormType.android).first_or_initialize
      @job_status_android = nil
      if @app_submission_form_android.new_record?
        @is_android_new_record = true
      else
        create_instance_variables_for_existing_android_form
      end
    end

    def create_instance_variables_for_existing_android_form
      @is_android_new_record = false
      background_job_android = BackgroundJob.find_by(entity_type: @app_submission_form_android.class, entity_id: @app_submission_form_android.id)
      @form_id_android = @app_submission_form_android.id
      if !background_job_android.blank?
        @job_status_android    = background_job_android.status
        @error_message_android = background_job_android.fail_message
      end
    end

end
