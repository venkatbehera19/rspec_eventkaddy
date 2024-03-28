class CreateZipFileForAttendeeSurveyImagesWorker
  include Sidekiq::Worker
  queue_as :attendee_survey_image_queue
  sidekiq_options retry: 0


  def perform(event_id,attendee_id)

    def truncate_and_titleize_string input
      input.titleize.delete(' ').truncate(20,omission:'')
    end

    background_job = BackgroundJob.find_by(purpose: "create_zip_file_for_attendee_survey_images",status: "started",entity_id: attendee_id, entity_type: "Attendee")
    background_job.update(external_job_id: self.jid)

    event    = Event.find(event_id)
    attendee = Attendee.find(attendee_id.to_s)
    begin
      @attendee_responses = SurveyResponse.get_attendee_image_responses event_id, attendee_id
      background_job.update(status: "inProgress")

      dest = Rails.root.join('attendee_survey_images_zips',event_id.to_s).to_path
      FileUtils.mkdir_p(dest) unless File.directory?(dest)

      unless @attendee_responses.blank?
        temp_folder = Rails.root.join('temp_attendee_survey_images',event_id.to_s,attendee_id.to_s).to_path
        attendee_name = truncate_and_titleize_string(attendee.first_name.strip+attendee.last_name.strip)
        Zip::ZipFile.open "#{dest}/#{attendee_name}_#{attendee_id}_zipfile.zip", Zip::ZipFile::CREATE do |zipfile|
          @attendee_responses.each do |response|
            file_id = response.event_file_id
            file = EventFile.find(file_id.to_i)
            file_content  = file.file_content
            survey_title  = truncate_and_titleize_string(response.survey_title)
            question_name = truncate_and_titleize_string(response.question_name)
            zip_file_dir  = "#{survey_title}_#{response.survey_id}/#{question_name}_#{response.question_id}"
            zipfile.mkdir(zip_file_dir)
            # write file temporarily
            FileUtils.mkdir_p("#{temp_folder}/#{response.survey_id}/#{response.question_id}") unless File.directory?("#{temp_folder}/#{response.survey_id}/#{response.question_id}")
            File.open("#{temp_folder}/#{response.survey_id}/#{response.question_id}/#{file.name}", 'wb', 0777) {|f|
              f.write(file_content)
            }
            zipfile.add "#{zip_file_dir}/#{file.name}", "#{temp_folder}/#{response.survey_id}/#{response.question_id}/#{file.name}"
          end
        end
        FileUtils.rm_rf(temp_folder)
      else
        # code if there are no images
        # we can raise an error over here!!
      end
      background_job.update(status: "completed")
      # Web Socket broadcast
      Faye.ensure_reactor_running!
      client = Faye::Client.new(event.chat_url + "/faye");
      publication = client.publish("/attendee_survey_images", {status: "completed", account_code: attendee.account_code})
      puts "SUCESS BROADCAST=#{publication}".green
    rescue => e
      background_job.update(status: "error",fail_message: e.message,error_stack: e.backtrace.join("\n"))
      # Web Socket broadcast
      Faye.ensure_reactor_running!
      client = Faye::Client.new(event.chat_url + "/faye");
      publication = client.publish("/attendee_survey_images", {status:"error", message: background_job.fail_message, account_code: attendee.account_code})
      puts "FAILURE BROADCAST=#{publication}".red
    end
  end
end
