class VideoPortalImage < ApplicationRecord

  belongs_to :event_file, :dependent => :destroy, :optional => true

  def update_image(image_file, link)
    event_file_type_id      = EventFileType.where(name:'video_portal_image').first.id
    video_portal_image_type = VideoPortalImageType.find video_portal_image_type_id
    file_extension          = File.extname image_file.original_filename

    event_file = event_file_id ? EventFile.find(event_file_id)
                               : EventFile.new(event_id:event_id,event_file_type_id:event_file_type_id)

    update!(name:video_portal_image_type.name, link:link)
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end    
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, 'video_portal_images').to_path,
      new_filename:            "#{video_portal_image_type.name.downcase.gsub(' ', '_')}#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}",
      event_file_owner:        self,
      event_file_assoc_column: :event_file_id,
      cloud_storage_type:      cloud_storage_type
    ).call
  end

end
