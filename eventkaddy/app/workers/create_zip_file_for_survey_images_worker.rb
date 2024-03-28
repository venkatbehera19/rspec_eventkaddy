class CreateZipFileForSurveyImagesWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0


  def perform(event_id,survey_id)

    def truncate_and_titleize_string input
      input.titleize.delete(' ').truncate(20,omission:'')
    end

    background_job = BackgroundJob.find_by(purpose: "create_zip_file_for_survey_images",status: "started",entity_id: survey_id, entity_type: "Survey")
    background_job.update(external_job_id: self.jid)

    event    = Event.find(event_id)
    survey   = Survey.find(survey_id.to_s)
    begin
      @survey_responses = SurveyResponse.get_survey_image_responses event_id, survey_id
      background_job.update(status: "inProgress")
      dest = Rails.root.join('survey_images_zips',event_id.to_s).to_path
      FileUtils.mkdir_p(dest) unless File.directory?(dest)

      unless @survey_responses.blank?
        temp_folder = Rails.root.join('temp_survey_images',event_id.to_s,survey_id.to_s).to_path
        survey_name = truncate_and_titleize_string(survey.title)
        Zip::ZipFile.open "#{dest}/#{survey_name}_#{survey_id}_zipfile.zip", Zip::ZipFile::CREATE do |zipfile|
          @survey_responses.each do |response|
            file_id = response.event_file_id
            file = EventFile.find(file_id.to_i)
            file_content  = file.file_content
            survey_title  = truncate_and_titleize_string(response.survey_title)
            question_name = truncate_and_titleize_string(response.question_name)
            zip_file_dir  = "#{survey_title}_#{response.survey_id}/#{question_name}_#{response.question_id}"
            zipfile.mkdir(zip_file_dir) if File.directory?(zip_file_dir)
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
      publication = client.publish("/attendee_survey_images", {status: "completed", id: survey.id})
      puts "SUCESS BROADCAST=#{publication}".green
    rescue => e
      background_job.update(status: "error",fail_message: e.message,error_stack: e.backtrace.join("\n"))
      # Web Socket broadcast
      Faye.ensure_reactor_running!
      client = Faye::Client.new(event.chat_url + "/faye");
      publication = client.publish("/attendee_survey_images", {status:"error", message: background_job.fail_message, id: survey.id})
      puts "FAILURE BROADCAST=#{publication}".red
    end
  end
end
