class EventFile < ApplicationRecord

	require 'RMagick'
	include Magick

	include ActiveModel::ForbiddenAttributesProtection

	belongs_to :event_file_type

	belongs_to :event
	belongs_to :cloud_storage_type, :optional => true

	has_one :session_file_version
	has_many :room_layouts
	has_one :exhibitor_file
	has_one :scavenger_hunt_item
  has_many :media_files

	# before_destroy :deleteFile
	after_destroy :remove_file_from_s3

	validates :path, presence: true, unless: :is_exhibitor_portal_file

	has_one :qr_code
	attr_accessor :exhibitor_id

	#upload a pdf, save as event_file with relevant type
	# s3 required
	def uploadPDF(params)

		if params[:signature] then
			@event_file_type = EventFileType.where(name:'speaker_pdf_upload').first
			self.event_file_type_id=@event_file_type.id
		else
			@event_file_type = EventFileType.where(name:'speaker_pdf_no_sign').first
			self.event_file_type_id=@event_file_type.id
		end
		#self.size =
		#self.mime_type =

		if (params[:pdf_file]!=nil) then #update/add photo

			uploaded_io = params[:pdf_file]

			#upload the pdf file
			m = uploaded_io.original_filename.match(/(.*)(.doc|.docx|.ods|.pdf|.txt|.text|.pez)$/i)
			if (m!=nil) then
				file_prefix = m[1]
				file_ext    = m[2]
			else
				return
			end

			new_filename = "#{file_prefix}_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			#create directory structure if necessary
			dirname = File.dirname(Rails.root.join('public','event_data', self.event_id.to_s,'speaker_pdfs',new_filename))
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end

			File.open(Rails.root.join('public','event_data', self.event_id.to_s,'speaker_pdfs',new_filename), 'wb') 			do |file|
				file.write(uploaded_io.read)
			end

			self.path = "/event_data/#{self.event_id.to_s}/speaker_pdfs/#{new_filename}"

		end

	end

	def uploadPdfUpdated(params, pdf_type)
		if params[:signature]
			@event_file_type        = EventFileType.where(name: "#{pdf_type}_pdf_upload").first
			self.event_file_type_id = @event_file_type.id
		else
			@event_file_type        = EventFileType.where(name: "#{pdf_type}_pdf_no_sign").first
			self.event_file_type_id = @event_file_type.id
		end

		if( params[:pdf_file] != nil)
			uploaded_io = params[:pdf_file]

			# upload the pdf file
			m = uploaded_io.original_filename.match(/(.*)(.doc|.docx|.ods|.pdf|.txt|.text|.pez)$/i)

			if m != nil
				file_prefix = m[1]
				file_ext    = m[2]
			else
				return
			end

			new_filename = "#{file_prefix}_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			#create directory structure if necessary
			dirname = File.dirname(Rails.root.join('public','event_data', self.event_id.to_s,"#{pdf_type}_pdfs",new_filename))
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end

			File.open(Rails.root.join('public','event_data', self.event_id.to_s,"#{pdf_type}_pdfs",new_filename), 'wb') 			do |file|
				file.write(uploaded_io.read)
			end

			self.path = "/event_data/#{self.event_id.to_s}/#{pdf_type}_pdfs/#{new_filename}"
		end
	end

	def upload_file(params, user_type)
		@event_file_type = EventFileType.where(name: "#{user_type}_portal_file").first
		self.event_file_type_id=@event_file_type.id
		if( params[:file] != nil )
			uploaded_io = params[:file]

			# uploaded file with extensions
			m = uploaded_io.original_filename.match(/(.*)(.doc|.docx|.ods|.pdf|.txt|.text|.pez|.png|.jpg|.gif|.heic|.eps|.ai|.dwg|.mp4|.mov|.xlsx|.xlsb|.xltx|.ppt|.pptx|.pptm|.csv)$/i)

			if m != nil
				file_prefix = m[1]
				file_ext    = m[2]
			else
				return
			end

			new_filename = "#{file_prefix}_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			#create directory structure if necessary
			dirname = File.dirname(Rails.root.join('public','event_data', self.event_id.to_s,"#{user_type}_portal_file",new_filename))

			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end

			File.open(Rails.root.join('public','event_data', self.event_id.to_s,"#{user_type}_portal_file",new_filename), 'wb') 			do |file|
				file.write(uploaded_io.read)
			end

			self.path = "/event_data/#{self.event_id.to_s}/#{user_type}_portal_file/#{new_filename}"

		end
	end

	def updatePhoto(params)

		@event_file_type = EventFileType.where(name:'event_message_image').first
		self.event_file_type_id=@event_file_type.id


		if (params[:event_file]!=nil) then #update/add photo

			uploaded_io = params[:event_file]
			self.name=uploaded_io.original_filename
			#upload the speaker photo
			if (uploaded_io.original_filename.match(/jpeg|jpg/i)) then
				file_ext = '.jpg'
			elsif (uploaded_io.original_filename.match(/png/i)) then
				file_ext = '.png'
			else
				return
			end

			new_filename = "#{self.event.name.gsub(/\s/,'_')}_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			#create directory structure if necessary
			dirname = File.dirname(Rails.root.join('public','event_data', self.event_id.to_s,'message_photos',new_filename))
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end

			File.open(Rails.root.join('public','event_data', self.event_id.to_s,'message_photos',new_filename), 'wb',0777) 			do |file|
				file.write(uploaded_io.read)
			end

			self.path="/event_data/#{self.event_id.to_s}/message_photos/#{new_filename}"


		end

	end

	def exhibitorImage(params)

		@event_file_type = EventFileType.where(name:"exhibitor_message_image").first
		self.event_file_type_id=@event_file_type.id


		if (params[:event_file]!=nil) then #update/add photo

			uploaded_io = params[:event_file]
			self.name=uploaded_io.original_filename
			#upload the speaker photo
			if (uploaded_io.original_filename.match(/jpeg|jpg/i)) then
				file_ext = '.jpg'
			elsif (uploaded_io.original_filename.match(/png/i)) then
				file_ext = '.png'
			else
				return
			end

			new_filename = "#{self.event.name.gsub(/\s/,'_')}_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			#create directory structure if necessary
			dirname = File.dirname(Rails.root.join('public','event_data', self.event_id.to_s,'exhibitor_message_photos',new_filename))
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end

			File.open(Rails.root.join('public','event_data', self.event_id.to_s,'exhibitor_message_photos',new_filename), 'wb',0777) 			do |file|
				file.write(uploaded_io.read)
			end

			self.path="/event_data/#{self.event_id.to_s}/exhibitor_message_photos/#{new_filename}"
			self.save()

			#Create association
      exhibitor_file_type_id = ExhibitorFileType.where(name:"message_image").first.id
			ExhibitorFile.where(event_id: self.event_id, exhibitor_id: self.exhibitor_id, event_file_id: self.id, title: new_filename, exhibitor_file_type_id:exhibitor_file_type_id).first_or_create

		end

	end

	# s3 required
	def entryImage(params, file_type)

		@event_file_type        = EventFileType.find_by_name(file_type)
		self.event_file_type_id = @event_file_type.id


		if (params[:event_file]!=nil) then #update/add photo

			uploaded_io = params[:event_file]
			self.name   = uploaded_io.original_filename

			#upload the speaker photo
			if (uploaded_io.original_filename.match(/jpeg|jpg/i)) then
				file_ext = '.jpg'
			elsif (uploaded_io.original_filename.match(/png/i)) then
				file_ext = '.png'
			else
				return
			end

			new_filename = "#{self.event.name.gsub(/\s/,'_')}_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			#create directory structure if necessary
			dirname = File.dirname(Rails.root.join('public','event_data', self.event_id.to_s,"#{file_type}s",new_filename))
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end

			File.open(Rails.root.join('public','event_data', self.event_id.to_s,"#{file_type}s",new_filename), 'wb',0777) 			do |file|
				file.write(uploaded_io.read)
			end

			self.path = "/event_data/#{self.event_id.to_s}/#{file_type}s/#{new_filename}"

		end

	end

	def addBanner(params,event_id,type_id)
		#add banner
    if (params[:event_banner_file]!=nil) then
      #upload the image
			uploaded_io = params[:event_banner_file]
			type        = EventFileType.find(type_id).name
			dirname     = File.dirname(Rails.root.join('public','event_data', event_id.to_s,'event_banners',type,uploaded_io.original_filename))
      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
      end

      File.open(Rails.root.join('public','event_data', event_id.to_s,'event_banners',type,uploaded_io.original_filename), 'wb',0777)        do |file|
        file.write(uploaded_io.read)
      end

      img = Magick::Image::read(Rails.root.join('public','event_data', event_id.to_s,'event_banners',type,uploaded_io.original_filename)).first

      #file table ref
      self.path      = "/event_data/#{event_id.to_s}/event_banners/#{type}/#{uploaded_io.original_filename}"
      self.mime_type = img.format
      self.size      = img.filesize
      self.event_id  = event_id
    end
	end

	# def deleteFile

	# 	def is_photo_gallery_camera_file?
	# 		type_id = EventFileType.where(name:"pg-camera").first.id
	# 		return event_file_type_id === type_id
	# 	end

	# 	def is_photo_gallery_photobooth_file?
	# 		type_id = EventFileType.where(name:"pg-photobooth").first.id
	# 		return event_file_type_id === type_id
	# 	end

	# 	if is_photo_gallery_photobooth_file?
	# 		thumb_path = self.path.gsub('gallery_photos/','gallery_photo_thumbnails/').gsub('.jpg','_small.jpg')
	# 		File.delete(Rails.root.join('public'+thumb_path)) if File.exist?('public'+thumb_path)
	# 	elsif is_photo_gallery_camera_file?
	# 		thumb_path = self.path.gsub(name,"THUMBS/#{name}")
	# 		File.delete(Rails.root.join('public'+thumb_path)) if File.exist?('public'+thumb_path)
	# 	end

	# 	if is_photo_gallery_photobooth_file? || is_photo_gallery_camera_file?

	# 		## remove php site sister images

	# 		php_path1 = "/home/deploy/photo_gallery_site/web/camera/#{name}"
	# 		php_path2 = "/home/deploy/photo_gallery_site/web/camera/thumbs/#{name}"
	# 		php_path3 = "/home/deploy/photo_gallery_site/web/photobooth//#{name}"
	# 		php_path4 = "/home/deploy/photo_gallery_site/web/photobooth/thumbs/#{name}"

	# 		File.delete(php_path1) if File.exist?(php_path1)
	# 		File.delete(php_path2) if File.exist?(php_path2)
	# 		File.delete(php_path3) if File.exist?(php_path3)
	# 		File.delete(php_path4) if File.exist?(php_path4)

	# 	end

	# 	File.delete(Rails.root.join('public'+self.path)) if File.exist?('public'+self.path)
	# end

	def mark_deleted
		self.update!(deleted:true)
	end

	def return_authenticated_url
    ReturnAWSUrl.new(self.event_id,self.path).call
  end

	def return_public_url
		ReturnAWSUrl.new(self.event_id, self.path, true).call
	end

	def file_content
		ReturnAWSUrl.new(self.event_id, self.path).read_file
	end

	# It is used for case when event has diffrent
	# cloud storage type and event file has diffrent
	# cloud storage type
	def file_content_diff_cst
		ReturnAWSUrl.new(self.event_id, self.path).read_diff_cst_file(self.cloud_storage_type)
	end

	def remove_file_from_s3
		ReturnAWSUrl.new(self.event_id, self.path).delete_file
	end

	def is_exhibitor_portal_file
		self.event_file_type.name == 'exhibitor_portal_file'
	end
end
