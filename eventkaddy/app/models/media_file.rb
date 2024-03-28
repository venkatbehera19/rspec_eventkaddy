class MediaFile < ApplicationRecord
  include ListItem
  extend ListItem

  belongs_to :session, optional: true
  belongs_to :exhibitor, optional: true
  belongs_to :cloud_storage_type
  belongs_to :event
  belongs_to :event_file


 def update_thumbnail(image_file, title, session_id = nil)
    if session_id
      event_file_type         = EventFileType.find_or_create_by(name:'session_media_thumbnail')
    else
      event_file_type         = EventFileType.where(name:'exhibitor_media_thumbnail').first
    end
    
    file_extension          = File.extname image_file.original_filename
    event_file_type_name    = event_file_type.name
    event_file = event_file_id ? EventFile.find(event_file_id)
                               : EventFile.create(event_id:event_id,event_file_type_id:event_file_type.id)
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, event_file_type_name).to_path,
      new_filename:            "#{title}_#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}",
      event_file_owner:        self,
      event_file_assoc_column: :event_file_id,
      new_height: 320,
      new_width: 320,
      cloud_storage_type:      cloud_storage_type
    ).call
  end

  def update_video(video_file,title,type,media_file)
    file_extension          = File.extname video_file.original_filename
    target_path             = Rails.root.join('public', 'event_data', event_id.to_s, "#{type}_videos").to_path
    new_filename            = "#{title}_#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}"

    if type == "session"
      event_file_type      = EventFileType.find_or_create_by(name:'session_media_thumbnail')
    else
      event_file_type      = EventFileType.where(name:'exhibitor_media_thumbnail').first
    end

    self.cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless self.cloud_storage_type_id.blank?
      self.cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end

    create_thumbnails(event_file_id, type, video_file, new_filename, event_file_type, cloud_storage_type)

    event_file = event_file_id ? EventFile.find(event_file_id)
                               : EventFile.create!(event_id:event_id,event_file_type_id:event_file_type.id, 
                                path: "#{target_path}/#{new_filename}")
    UploadMediaFile.new(
      media_file:              media_file,
      video:                   video_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, "#{type}_videos").to_path,
      new_filename:            "#{title}_#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}",
      cloud_storage_type:      self.cloud_storage_type,
      event_file_id:           event_file.id
    ).call
  end

  def create_thumbnails(event_file_id, type, video_file, new_filename, event_file_type, cloud_storage_type)
    if event_file_id.blank?
      event_file_type_name    = event_file_type.name
      target_path             = Rails.root.join('public', 'event_data', event_id.to_s, event_file_type_name).to_path
      filename                = new_filename.split(".")[0] + ".png"
      full_path               = "#{target_path}/#{filename}"
      FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
      img = system("ffmpeg -ss 00:00:05 -i '#{video_file.path}' -vf scale=320:320  -vframes:v 1 -q:v 2 '#{full_path}'")
      event_file              = event_file_id ? EventFile.find(event_file_id) : EventFile.create!(event_id:event_id,event_file_type_id:event_file_type.id, path: full_path)
      UploadEventFileImage.new(
        event_file:              event_file,
        image:                   full_path,
        target_path:             target_path,
        new_filename:            filename,
        event_file_owner:        self,
        event_file_assoc_column: :event_file_id,
        resize_without_write: true, 
        cloud_storage_type:      cloud_storage_type,
      ).call
      FileUtils.rm(full_path, :force => true)
    end
  end

  def return_authenticated_url(event_id,file_path)
    ReturnAWSUrl.new(event_id,file_path).call
  end

end
    