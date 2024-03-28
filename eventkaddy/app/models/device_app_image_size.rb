class DeviceAppImageSize < ApplicationRecord
  # attr_accessible :id, :app_image_size_id, :app_image_type_id, :device_type_id

  belongs_to :app_image_size
  belongs_to :app_image_type
  belongs_to :device_type
end
