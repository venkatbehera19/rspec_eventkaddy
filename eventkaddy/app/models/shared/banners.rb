module Banners
	# s3 updated
	def upload_banner(settings, params, event_id, model_name, event_file_type_name, event_file_owner, event_file_assoc_column)
		if (params[:portal_banner_file]!=nil) then #update/add photo
			uploaded_io 	  = params[:portal_banner_file]
			file_extension  = File.extname uploaded_io.original_filename
			event_file_id 	= settings.send("#{event_file_type_name}_event_file_id")
      event_file_type = EventFileType.where(name: event_file_type_name).first
			new_filename 		= "#{self.event_id}_portal_banner_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_extension}"
			target_path  		= Rails.root.join('public','event_data', self.event_id.to_s,"#{model_name}_portal_banner_photo").to_path
      event_file    	= event_file_id.blank? ? EventFile.new(event_id:event_id,event_file_type_id:event_file_type.id) : EventFile.find(event_file_id)
			cloud_storage_type_id   = Event.find(event_id).cloud_storage_type_id
			cloud_storage_type      = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
			end

      UploadEventFileImage.new(
				event_file:              event_file,
				image:                   uploaded_io,
				target_path:             target_path,
				new_filename:            new_filename,
				event_file_owner: 			 event_file_owner,
				event_file_assoc_column: event_file_assoc_column,
				cloud_storage_type:      cloud_storage_type
			).call
		end
  end
end