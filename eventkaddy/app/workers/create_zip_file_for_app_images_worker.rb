require 'archive/zip'
class CreateZipFileForAppImagesWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0

  def perform(event_id,form_id)
    background_job = BackgroundJob.find_by(purpose: "create_zip_file_for_app_images",status: "started",entity_id: form_id, entity_type: "AppSubmissionForm")
    background_job.update(external_job_id: self.jid)
    begin
      form  = AppSubmissionForm.find_by!(id: form_id)
      event = Event.find_by!(id: event_id)
      background_job.update(status: "inProgress")
      # create zip files folder
      zip_files_path = Rails.root.join('event_app_form_data',event_id.to_s,"form_zip_files").to_path
      unless File.directory?(zip_files_path)
        FileUtils.mkdir_p(zip_files_path)
      end

      if form.app_form_type.name == "ios"
        # create all the variations of icons
        AppImageScripts::CreateIosIcons.new.create_ios_icons event_id
        # delete existing zip if it exist
        FileUtils.rm_rf("#{zip_files_path}/ios.zip")
        # Archive content and create zip file  
        Archive::Zip.archive("#{zip_files_path}/ios.zip", Rails.root.join('event_app_form_data', event.id.to_s,"transformed_images","icon","ios_icons").to_path)
      else
        # create all the variations of images
        AppImageScripts::CreateAndroidIcons.new.create_android_icons event_id
        AppImageScripts::CreateAndroidSplashScreens.new.create_android_splash_screens event_id
        # delete existing zip if it exist
        FileUtils.rm_rf("#{zip_files_path}/android.zip")
        # Archive content and create zip file  
        Archive::Zip.archive("#{zip_files_path}/android.zip", [Rails.root.join("event_app_form_data",event.id.to_s,"transformed_images","icon","android_icons").to_path, Rails.root.join("event_app_form_data",event.id.to_s,"transformed_images","screen","android_screens").to_path])
      end

      background_job.update(status: "completed")
      # Web Socket broadcast
      Faye.ensure_reactor_running!
      client = Faye::Client.new(event.chat_url + "/faye");
      publication = client.publish("/app_submission_forms/#{form_id}", "status" => "completed")
      publication.callback do
    	puts 'Message received by server!'
      end

     publication.errback do |error|
      puts 'There was a problem: ' + error.message
    end
    rescue => e
      background_job.update(status: "error",fail_message: e.message,error_stack: e.backtrace.join("\n"))
      # Web Socket broadcast
      Faye.ensure_reactor_running!
      client = Faye::Client.new(event.chat_url + "/faye");
      publication = client.publish("/app_submission_forms/#{form_id}", {"status" => "error","message"=> background_job.fail_message})
    end
  end
end
