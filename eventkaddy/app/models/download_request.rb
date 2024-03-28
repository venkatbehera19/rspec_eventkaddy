class DownloadRequest < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :status, presence: true
  validates :request_type, presence: true

  enum status: { pending: 'pending', success: 'success', failed: 'failed', processing: 'processing' }
  enum request_type: { speaker_file: 'Speaker File', exhibitor_file: 'Exhibitor File', attendee_qr_images: 'Attendee QR Images' }

end
