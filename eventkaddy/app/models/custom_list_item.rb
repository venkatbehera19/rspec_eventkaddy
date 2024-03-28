class CustomListItem < ApplicationRecord

	include ListItem
	extend ListItem

  # attr_accessible :content, :custom_list_id, :event_id, :position, :title

  belongs_to :custom_list

# validates :position, presence: true

  validates :title, presence: true

	# s3 updated
	def uploadIcon(params,event_id)

		if (params[:image_file]!=nil) then
			uploaded_io 						= params[:image_file]
			event_file_type_id 			= EventFileType.where(name:"home_button_icon").first.id
			file_extension          = File.extname uploaded_io.original_filename
			event_file 							= event_file_id ? EventFile.find(event_file_id)
                                : EventFile.new(event_id:event_id, event_file_type_id:event_file_type_id)
			target_path 						= Rails.root.join('public','event_data', event_id.to_s,'home_button_group_images').to_path
			cloud_storage_type_id   = Event.find(event_id).cloud_storage_type_id
			cloud_storage_type      = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
			end

			UploadEventFileImage.new(
				event_file:              event_file,
				image:                   uploaded_io,
				target_path:             target_path,
				new_filename:            uploaded_io.original_filename,
				event_file_owner: 			 self,
				event_file_assoc_column: :event_file_id,
				new_height:              65,
				new_width:               63,
				cloud_storage_type:      cloud_storage_type
			).call
		end
	end

end
