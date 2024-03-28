namespace :change_reports_legacy_data do
  desc "This task will populate the change_reports table and upload existing change reports to s3"
  task :populate_and_upload => :environment do
    root_path = Rails.root
    event_ids_folder = Dir.children(root_path.join('public', 'event_data'))
    delta_files_hash_array = event_ids_folder.map do |event_id|
      xlsx_files_path_pattern = root_path.join('public', 'event_data', event_id, 'deltas').to_path + '/*.xlsx'
      {
        event_id: event_id,
        files_array: Dir[xlsx_files_path_pattern].map do |files_path|
          parent_dir = root_path.join('public', 'event_data', event_id, 'deltas')
          {
            full_path: files_path,
            filename: files_path.sub(parent_dir.to_path + '/', ''),
            event_file_path: files_path.sub(root_path.join('public').to_path, ''),
            mime_type: MIME::Types.type_for(files_path).first.content_type,
            size: File.size(files_path)
          }
        end 
      }
    end
    #puts delta_files_hash_array
    event_file_type = EventFileType.where(name: 'event_delta_reports').first_or_create

    delta_files_hash_array.each do |file_hash|
      unless file_hash[:files_array].blank?
        event = Event.find(file_hash[:event_id])

        cloud_storage_type = CloudStorageType.find_by(id: event.cloud_storage_type_id)
        if cloud_storage_type.blank?
          cloud_storage_type = CloudStorageType.find_by(bucket: "videokaddy")
          event.update_attribute(:cloud_storage_type_id, cloud_storage_type.id)
        end

        #puts "#{file_hash[:event_id]} : #{cloud_storage_type.name}"
        
        file_hash[:files_array].each do |file_detail|
          
          event_file = EventFile.new(event_id: file_hash[:event_id], name: file_detail[:filename], size: file_detail[:size], mime_type: file_detail[:mime_type], event_file_type_id: event_file_type.id, path: file_detail[:event_file_path])
          event_file.save!

          UploadEventFile.new({
            event_file: event_file,
            file: File.open(file_detail[:full_path]),
            target_path: root_path.join('public', 'event_data', file_hash[:event_id], 'deltas').to_path,
            new_filename: file_detail[:filename],
            cloud_storage_type: cloud_storage_type,
            content_type: file_detail[:mime_type]
          }).call

          puts "EventFile created and file uploaded to s3 for #{file_detail[:filename]} of event id #{file_hash[:event_id]}"

          ChangeReport.create!( event_id: file_hash[:event_id], upload_action: file_detail[:filename].split('_delta').first, event_file_id: event_file.id, created_at: Time.parse( file_detail[:filename].split('_').last.gsub('.xlsx', '') ) )
          puts "------ change report created ------"
        end
      end
    end
  end
end