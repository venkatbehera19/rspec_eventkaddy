class EventTicket < ApplicationRecord
  belongs_to :event
  belongs_to :session, :optional => true
  has_many   :attendee_tickets, dependent: :destroy
  belongs_to :event_file, :foreign_key => 'background_image_id', optional: true

  validates :date, presence: true
  validates :title, presence: true
  validates :start_time, :end_time, presence: true
  validate  :end_time_cannot_be_before_start_time
  after_destroy :destroy_event_file

  def end_time_cannot_be_before_start_time
    if end_time.present? && end_time < start_time
      errors.add(:end_time, "can't be in the past")
    end
  end

  def upload_background_image(image_file)
    target_path             = Rails.root.join('public','event_data', self.event_id.to_s,'event_ticket').to_path
    event_file_type_id      = EventFileType.find_or_create_by(name: "event_ticket").id
    event_file              = EventFile.new(event_id:self.event_id, event_file_type_id:event_file_type_id)
    cloud_storage_type_id   = Event.find(self.event_id).cloud_storage_type_id
    cloud_storage_type      = nil
    unless cloud_storage_type_id.blank?
      cloud_storage_type    = CloudStorageType.find(cloud_storage_type_id)
    end
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             target_path,
      new_filename:            image_file.original_filename,
      cloud_storage_type:      cloud_storage_type
    ).call
    self.update_attribute("background_image_id", event_file.id)
  end

  def destroy_event_file
    self.event_file.destroy
  end

end
