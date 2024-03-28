class ScavengerHuntItem < ApplicationRecord

  belongs_to :event
  belongs_to :exhibitor, :optional => true
  belongs_to :event_file, :optional => true
  belongs_to :scavenger_hunt
  belongs_to :scavenger_hunt_item_type
  has_many :attendees_scavenger_hunt_item #could dependent destroy, but maybe we still want to know about attendees participation even if this is removed?
  has_many :attendees, :through => :attendees_scavenger_hunt_item

  def qr_code_type?
    return false unless scavenger_hunt_item_type
    scavenger_hunt_item_type.name == 'QR Code' || scavenger_hunt_item_type.name == 'QR Code or Input'
  end

  def qr_filename
    "#{answer}.png"
  end

  def qr_image_full_path
		Rails.root.join('public', 'event_data', event_id.to_s, 'scavenger_hunt_item_qr_images', qr_filename)
  end

  def qr_image_relative_path
    "/event_data/#{event_id}/scavenger_hunt_item_qr_images/#{qr_filename}"
  end

  def qr_image
    File.exist?(qr_image_full_path) ? qr_image_relative_path : generate_qr_image
  end

  def generate_qr_image

		directory_path = Rails.root.join('public', 'event_data', event_id.to_s, 'scavenger_hunt_item_qr_images')
    FileUtils.mkdir_p(directory_path) unless File.directory?(directory_path)

    RQRCode::QRCode.
      new(answer, :level => :l ).
      to_img.
      resize(600, 600).
      save(qr_image_full_path)
    qr_image_relative_path
  rescue RQRCode::QRCodeRunTimeError
    "QR Code could not be generated due to answer length."
  end

  def path
    event_file.cloud_storage_type_id.blank? ? event_file.path : event_file.return_authenticated_url['url']
  end

  def update_image(image_file)
    event_file_type_id      = EventFileType.where(name:'scavenger_hunt_image').first.id
    file_extension          = File.extname image_file.original_filename

    event_file = event_file_id ? EventFile.find(event_file_id)
                               : EventFile.new(event_id:event_id,event_file_type_id:event_file_type_id)
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end

    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, 'scavenger_hunt_images').to_path,
      new_filename:            "#{name.downcase.gsub(/[^a-zA-Z_0-9]/, '_')}#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}",
      event_file_owner:        self,
      event_file_assoc_column: :event_file_id,
      new_height:              300,
      new_width:               300,
      cloud_storage_type:      cloud_storage_type
    ).call
  end

end
