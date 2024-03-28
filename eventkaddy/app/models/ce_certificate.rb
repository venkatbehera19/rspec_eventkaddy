class CeCertificate < ApplicationRecord
  belongs_to :event, :optional => true
  belongs_to :ce_certificate_type
  belongs_to :event_file, optional: true
  has_many   :survey_ce_certificate

  # attr_accessible :name, :json, :event_id, :event_file_id, :ce_certificate_type_id, :mailer

  
  def update_photo(image_file, type_name)
    # type_name can be "certificate_background" or "certificate_border"
    event_file_type_id = EventFileType.where(name:type_name).first.id

    file_extension     = File.extname image_file.original_filename
    filename           = "#{@event_id}_#{@pdf_title}#{file_extension}"
    filename           = "#{self.event_id}_#{self.name.downcase.gsub(/ /, '_')}#{file_extension}"
    
    existing_file_id   = self.event_file_id
    if !existing_file_id.blank?
      event_file = EventFile.find(existing_file_id)
      target_path = Rails.root.join('public', 'ce-credits', self.event_id.to_s, type_name).to_path
      old_photo_name = filename
      FileUtils.rm("#{target_path}/#{old_photo_name}",:force => true)
    end
    event_file         = existing_file_id ? EventFile.find(existing_file_id) 
                                          : EventFile.create(
                                            event_id:           self.event_id,
                                            name:               filename,
                                            mime_type:          "image/png",
                                            path:               "/ce-credits/#{filename}",
                                            event_file_type_id: event_file_type_id)

    # cloud_storage_type_id = Event.find(self.event_id).cloud_storage_type_id
    # unless cloud_storage_type_id.blank?
    #   cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    # end
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'ce-credits', event_id.to_s, type_name).to_path,
      new_filename:            filename,
      event_file_owner:        self,
      new_height:              1151,
      new_width:               1500,
      event_file_assoc_column: :event_file_id #,
      #cloud_storage_type:      cloud_storage_type
    ).call
  end     

end
