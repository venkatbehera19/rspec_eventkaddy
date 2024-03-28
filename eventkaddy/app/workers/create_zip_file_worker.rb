require 'archive/zip'

class CreateZipFileWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
  sidekiq_options unique: :until_executed, unique_args: ->(args) { [args.first] }

  def perform download_request_id
    download_request =  DownloadRequest.find_by_id(download_request_id)
    download_request.update(job_id: self.jid)

    event = Event.find download_request.event_id
    cloud_storage_type_id   = event.cloud_storage_type_id

    begin
      download_request.update(status: :processing)
      request_file_type = download_request.request_type
      zip_success = false

      if request_file_type == 'speaker_file'

        # speaker_file_type = SpeakerFileType.where(name: 'signed document')
        speaker_photo_event_file_type_id  = EventFileType.where(name:'speaker_photo').first.id
        attendee_photo_event_file_type_id = EventFileType.where( name: 'attendee_photo' ).first.id
        # speaker_files     = SpeakerFile.where(
        #   event_id: download_request.event_id,
        #   speaker_file_type_id: speaker_file_type.first.id
        # )
        speaker_photos    = EventFile.where(
          event_id: event.id,
          event_file_type_id: [speaker_photo_event_file_type_id, attendee_photo_event_file_type_id ]
        ).where.not(cloud_storage_type_id: nil)

        temp_folder = Rails.root.join('exhibitor_zips', event.id.to_s, 'temp_folder').to_path
        zip_filename = "#{download_request.user_id}_speaker_files.zip"

        zip_folder = Rails.root.join('public', 'event_data', event.id.to_s, 'zip')
        zip_filepath = zip_folder.join(zip_filename).to_path

        FileUtils.mkdir_p(zip_folder)  unless File.directory?(zip_folder)
        FileUtils.mkdir_p(temp_folder) unless File.directory?(temp_folder)
        # check that zip file is pesent or not , if present delete it.
        File.delete(zip_filepath) if File.exist?(zip_filepath)

        begin
          zip_success = Zip::ZipFile.open(zip_filepath, Zip::ZipFile::CREATE) do |zip_file|
            # speaker_files.each do |speaker_file|
            #   file = speaker_file.event_file
            #   file_content = file.file_content

            #   if file_content

            #     FileUtils.mkdir_p("#{temp_folder}/speaker_files") unless File.directory?("#{temp_folder}/speaker_files")

            #     File.open("#{temp_folder}/speaker_files/#{file.name}", 'wb') do |f|
            #       f.write(file_content)
            #     end

            #     zip_file.add("speaker_files/#{file.name}", "#{temp_folder}/speaker_files/#{file.name}")
            #   end

            # end

            # uploading speaker photos
            speaker_photos.each do |speaker_photo|
              file_content = speaker_photo.file_content_diff_cst
              if file_content

                FileUtils.mkdir_p("#{temp_folder}/speaker_photos") unless File.directory?("#{temp_folder}/speaker_photos")

                File.open("#{temp_folder}/speaker_photos/#{speaker_photo.name}", 'wb') do |f|
                  f.write(file_content)
                end

                zip_file.add("speaker_photos/#{speaker_photo.name}", "#{temp_folder}/speaker_photos/#{speaker_photo.name}")
              end
            end

          end
        rescue StandardError => e
          download_request.update( status: "failed", error_message: e.message )
        ensure
          FileUtils.remove_dir(temp_folder) if File.directory?(temp_folder)
        end

        if File.exist?(zip_filepath)
          cloud_storage_type      = nil
          unless cloud_storage_type_id.blank?
            cloud_storage_type    = CloudStorageType.find(cloud_storage_type_id)
          end

          document = zip_filepath
          file_size = File.size(document)
          if document != nil && file_size < 150000000 && file_size > 0

            base_filename = File.basename(zip_filepath)
            timestamp = Time.now.strftime("%Y%m%d%H%M%S")
            new_filename = "#{timestamp}_#{base_filename}"

            target_path  = Rails.root.join('public','event_data', event.id.to_s, 'zip_files')

            UploadZipFile.new(
              zip_file_path: zip_filepath,
              target_path: target_path,
              new_filename: new_filename,
              cloud_storage_type: cloud_storage_type,
              download_request: download_request
            ).call

            File.delete(zip_filepath)

          end

        end

      elsif request_file_type == 'exhibitor_file'
        exhibitor_file_type = ExhibitorFileType.where(name: 'exhibitor_document').first
        exhibitor_files     = ExhibitorFile.where(
          event_id: event.id,
          exhibitor_file_type_id: exhibitor_file_type.id
        ).where.not(original_document_id: nil)

        temp_folder = Rails.root.join('exhibitor_zips', event.id.to_s, 'temp_folder').to_path
        zip_filename = "#{download_request.user_id}_exhibitor_files.zip"

        zip_folder = Rails.root.join('public', 'event_data', event.id.to_s, 'zip')
        zip_filepath = zip_folder.join(zip_filename).to_path

        if exhibitor_files.present?

          FileUtils.mkdir_p(zip_folder)  unless File.directory?(zip_folder)
          FileUtils.mkdir_p(temp_folder) unless File.directory?(temp_folder)

          # check that zip file is pesent or not , if present delete it.
          File.delete(zip_filepath) if File.exist?(zip_filepath)

          begin

            zip_success = Zip::ZipFile.open(zip_filepath, Zip::ZipFile::CREATE) do |zip_file|
              exhibitor_files.each do |exhibitor_file|
                if exhibitor_file.event_file.present?
                  file = exhibitor_file.event_file
                  file_content = file.file_content_diff_cst

                  if file_content

                    FileUtils.mkdir_p("#{temp_folder}/exhibitor_files") unless File.directory?("#{temp_folder}/exhibitor_files")

                    File.open("#{temp_folder}/exhibitor_files/#{file.name}", 'wb') do |f|
                      f.write(file_content)
                    end

                    zip_file.add("exhibitor_files/#{file.name}", "#{temp_folder}/exhibitor_files/#{file.name}")
                  end

                end
              end
            end
          rescue StandardError => e
            download_request.update( status: "failed", error_message: e.message )
          ensure
            FileUtils.remove_dir(temp_folder) if File.directory?(temp_folder)
          end

          if File.exist?(zip_filepath)
            cloud_storage_type      = nil
            unless cloud_storage_type_id.blank?
              cloud_storage_type    = CloudStorageType.find(cloud_storage_type_id)
            end

            document = zip_filepath
            file_size = File.size(document)
            if document != nil && file_size < 150000000 && file_size > 0

              base_filename = File.basename(zip_filepath)
              timestamp = Time.now.strftime("%Y%m%d%H%M%S")
              new_filename = "#{timestamp}_#{base_filename}"

              target_path  = Rails.root.join('public','event_data', event.id.to_s, 'zip_files')

              UploadZipFile.new(
                zip_file_path: zip_filepath,
                target_path: target_path,
                new_filename: new_filename,
                cloud_storage_type: cloud_storage_type,
                download_request: download_request
              ).call

              File.delete(zip_filepath)

            end

          end
        end
      elsif request_file_type == 'attendee_qr_images'
        attendees = Attendee.where(event_id: event.id)
        attendees.each do |attendee|
          attendee.qr_image
        end
        zip_success = true
      end

      if zip_success
        download_request.update(status: "success", error_message: "zip file uploaded")
      else
        download_request.update(status: "failed", error_message: "Unable to zip")
      end

    rescue StandardError => e
      download_request.update( status: "failed", error_message: e.message )
    end
  end

end
