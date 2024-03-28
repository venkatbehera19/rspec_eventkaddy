class ExhibitorProduct < ApplicationRecord

	include ImageHaver
	extend ImageHaver
	require 'rqrcode_png'

  # attr_accessible :description, :event_id, :exhibitor_id, :name, :product_image_id, :product_url, :qr_code_id, :youtube_url

  has_one    :qr_code, :dependent => :destroy
  belongs_to :exhibitor
  belongs_to :event
  belongs_to :event_file_product_image, :foreign_key => 'product_image_id', :class_name => "EventFile"
  has_many :attendees_exhibitor_product#, :dependent => :destroy

  validate :url_check

  def url_check
  	unless product_url.blank? || product_url =~ /\A#{URI::regexp(['http', 'https'])}\z/
  		errors.add("Product URL", "must begin with http:// or https://")
  	end
  	unless youtube_url.blank? || youtube_url =~ /\A#{URI::regexp(['http', 'https'])}\z/
	  	errors.add("YouTube URL", "must begin with http:// or https://")
  	end
  end

	def updateProductImage(params)
		def return_associated_event_file
			if self.event_file_product_image then self.event_file_product_image	else self.event_file_product_image = EventFile.new();	end
		end

		## Assignments
		image_file                    = params[:photo_file]
		event_file                    = return_associated_event_file
		event_file.event_file_type_id = returnImageEventFileTypeId 'product_image'
		event_file.event_id           = event_id
		file_ext                      = return_jpg_or_png_file_extension_else_nil(image_file)

		return unless file_ext == '.jpg' || file_ext == '.png'

		new_filename                  = "#{self.exhibitor_id}_#{self.name}_photo_#{self.product_image_id}_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"
		directory_path                = Rails.root.join('public','event_data', self.event_id.to_s,'exhibitor_product_photos')
		# resize_width                  = 150
		# resize_height                 = 150

		## Methods
		updateImage(event_file, image_file, directory_path, new_filename)
		# resizeImage(event_file, resize_width, resize_height)
	end

	def generate_qr_image
		def return_associated_event_file
			if self.qr_code
				self.qr_code.event_file
			else
				self.qr_code            = QrCode.create(event_id:event_id, exhibitor_product_id: self.id)
				self.qr_code.event_file = EventFile.new()
			end
		end

		event_file                    = return_associated_event_file
		event_file.event_file_type_id = returnImageEventFileTypeId 'qr_code'
		event_file.event_id           = event_id

		qr_link        = "https://avmaspeakers.eventkaddy.net/exhibitor_products/#{id}"
		new_filename   = "#{name}_qr_image_#{id}.png"
		directory_path = Rails.root.join('public', 'event_data', event_id.to_s, 'exhibitor_qr_images')

		unless File.directory?(directory_path)
			FileUtils.mkdir_p(directory_path)
		end

		qr_code        = RQRCode::QRCode.new(qr_link, :size => 20, :level => :h )
		image_file     = qr_code.to_img
		image_file.resize(600, 600).save("#{directory_path}/#{new_filename}")
		event_file.path = "#{directory_path.to_s.slice(directory_path.to_s.index("/event_data")..-1)}/#{new_filename}"
		event_file.name = new_filename
		event_file.save
		self.qr_code.event_file_id = event_file.id
		self.qr_code.save
		self.update!(qr_code_id:self.qr_code.id)
	end

end
