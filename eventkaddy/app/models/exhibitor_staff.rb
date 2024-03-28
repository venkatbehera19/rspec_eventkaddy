class ExhibitorStaff < ApplicationRecord
  before_create :set_slug

  belongs_to :event
  belongs_to :exhibitor
  belongs_to :user, :foreign_key => 'user_id'
  belongs_to :event_file_photo, :foreign_key => 'staff_photo_file_id', :class_name => "EventFile", :optional => true
  has_many :slots

  attr_accessor :is_attendee

  def full_name
    return "#{first_name} #{last_name}".strip
  end

  def set_slug
    loop do
      self.slug = SecureRandom.uuid
      break unless ExhibitorStaff.where(slug: self.slug).exists?
    end
  end

  def room_name
    fullname = "#{first_name} #{last_name}".gsub(' ','').underscore
    name_or_id = (fullname.blank?) ?  self.id : fullname
    self.exhibitor.company_name.gsub(' ','').underscore + '-' + name_or_id
  end

  def update_photo(image_file)
    event_file_type_id = EventFileType.where(name:'attendee_photo').first.id
    file_extension     = File.extname image_file.original_filename
    basename           = File.basename image_file.original_filename, file_extension
    # filename           = "#{basename.downcase.gsub(' ', '_')}#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}"
    filename           = "#{self.first_name}_#{self.last_name}_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_extension}"

    event_file = staff_photo_file_id ? EventFile.find(staff_photo_file_id)
                                     : EventFile.new(event_id:event_id, event_file_type_id:event_file_type_id)
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    # removed as this currently toggles 'online version' of photo file
    # update! photo_filename:filename

    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, 'attendee_photos').to_path,
      new_filename:            filename,
      event_file_owner:        self,
      new_height:              400,
      new_width:               300,
      event_file_assoc_column: :staff_photo_file_id,
      cloud_storage_type:      cloud_storage_type
    ).call
  end

  def generate_and_save_simple_password
    o        = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten # the alphabete
    password = (0...6).map { o[rand(o.length)] }.join

    User.first_or_create_for_exhibitor self, password
    password
  end
end
