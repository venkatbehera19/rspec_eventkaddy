class CustomAdjustment; end # dumb thing rails thinks it needs

class CustomAdjustmentsController < ApplicationController
  load_and_authorize_resource

  def session_file_urls_to_secure_field
    spawn_script 'session_file_urls_to_secure_custom_fields_2.rb', "\"#{session[:event_id]}\""

    respond_to do |format|
      format.html { redirect_to("/dev", :notice => 'custom_fields_2 updated.') }
    end
  end

  def add_track_subtracks_to_sessions
    spawn_script 'add_track_subtracks_to_sessions.rb', "\"#{session[:event_id]}\""

    respond_to do |format|
      format.html { redirect_to("/dev", :notice => 'track_subtrack updated.') }
    end
  end

  def add_speaker_names_to_sessions
    spawn_script 'add_speaker_names_to_session_custom_fields.rb', "\"#{session[:event_id]}\""

    respond_to do |format|
      format.html { redirect_to("/dev", :notice => 'custom_fields updated.') }
    end
  end

  def add_speaker_names_to_sessions_new
    spawn_script 'add_speaker_names_to_session_speaker_names.rb', "\"#{session[:event_id]}\""

    respond_to do |format|
      format.html { redirect_to("/dev", :notice => 'speaker_name updated.') }
    end
  end

  def remove_all_session_files
    spawn_script 'remove_all_session_files.rb', "\"#{session[:event_id]}\""

    respond_to do |format|
      format.html { redirect_to("/dev", :notice => 'session_files destroyed and session_file_urls nulled.') }
    end
  end

  def remove_all_speakers_without_sessions_and_associations
    spawn_script 'remove_all_speakers_without_sessions_data_for_event.rb', "\"#{session[:event_id]}\""

    respond_to do |format|
      format.html { redirect_to("/dev", :notice => 'speakers and their associations destroyed.') }
    end
  end

  def remove_all_sessions_without_video_urls_and_abandoned_speakers
    spawn_script 'remove_all_sessions_without_video_urls_and_abandoned_speakers.rb', "\"#{session[:event_id]}\""

    respond_to do |format|
      format.html { redirect_to("/dev", :notice => 'sessions without video urls and abandoned speakers and their associations destroyed.') }
    end
  end

  def remove_all_speakers_and_associations
    spawn_script 'remove_all_speaker_data_for_event.rb', "\"#{session[:event_id]}\""

    respond_to do |format|
      format.html { redirect_to("/dev", :notice => 'speakers and their associations destroyed.') }
    end
  end

  def add_automated_notification_filters_to_attendees
    spawn_script 'add_automated_notification_filters_to_attendees.rb', "\"#{session[:event_id]}\""

    respond_to do |format|
      format.html {
        redirect_to(
          "/dev",
          :notice => 'attendees\' notification filters updated.'
        ) 
      }
    end
  end

  def update_attendee_passwords_for_event
    spawn_script 'update_attendee_passwords_for_event.rb', "\"#{session[:event_id]}\""
    respond_to do |format|
      format.html { redirect_to("/dev", :notice => 'Attendee passwords updated for event.') }
    end
  end

  def get_video_url_for_one_session
    spawn_script 'get_video_url_for_one_session.rb', "\"#{params[:session_id]}\""

    respond_to do |format|
      format.html { redirect_to("/sessions/#{params[:session_id]}", :notice => 'Searching for the video url. If found, it will be populated in the Embedded Video URL field on page refresh.') }
    end
  end

  def encode_video_for_one_session
    spawn_script 'encode_video_for_one_session.rb', "\"#{params[:session_id]}\""
    respond_to do |format|
      format.html { redirect_to("/sessions/#{params[:session_id]}", :notice => "Encoding the video. Please wait a few minutes then press the 'Search for Encoded Video' button.") }
    end
  end

  def search_for_encoded_video
    spawn_script 'search_for_encoded_video.rb', "\"#{params[:session_id]}\""
    respond_to do |format|
      format.html { redirect_to("/sessions/#{params[:session_id]}", :notice => "Searching for the encoded video. If found, it will be populated in the Encoded Videos field on page refresh.") }
    end
  end

  def create_thumbnail_for_one_session
    spawn_script 'create_thumbnail_for_one_session.rb', "\"#{params[:session_id]}\""
    respond_to do |format|
      format.html { redirect_to("/sessions/#{params[:session_id]}", :notice => 'Creating the thumbnail. If successful it will show in the Thumbnail field on page refresh.') }
    end
  end

  def add_meta_data_to_tags
    existing_jobs = BackgroundJob.where(entity_type: 'Event', entity_id: session[:event_id], purpose: 'add_session_meta_data', status: 'in_progress')
    unless existing_jobs.blank?
      flash[:alert] = "Job for the same is already running"
      render json: {alert:  'refresh'}, status: 200
      return
    end
    @job_id = AddMetaDataToTagsWorker.perform_async(session[:event_id])
    render json: {job_id: @job_id}, status: 200
  end

  def meta_data_job_status
    job = BackgroundJob.where(entity_type: 'Event', entity_id: session[:event_id], purpose: 'add_session_meta_data').select('status, fail_message, cast(updated_at as DATE) as update_dt').last
    render json: {data: job}, status: 200
  end


  private

  def spawn_script script_name, args_string
    cmd = Rails.root.join('ek_scripts','custom-adjustment-scripts',"#{script_name.to_s} #{args_string.to_s}")
    pid = Process.spawn("ROO_TMP='/tmp' ruby #{cmd} 2>&1")
    Process.detach pid
  end

end
