class AppImageSize < ApplicationRecord

  has_many :app_images

  has_many :device_app_image_sizes

  def app_image_size_description
     "Width: #{image_width} & Height: #{image_height}"
  end

end
