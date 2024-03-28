class EventSetting < ApplicationRecord

	include Magick

  # attr_accessible :av_requirements_content, :event_id, :hide_bio, :hide_cv, :portal_logo_event_file_id,:portal_banner_event_file_id, :sessions_editable, :support_email_address, :travel_and_lodging, :welcome_screen_content, :speaker_details_editable, :session_notes_content, :exhibitor_welcome, :speaker_files, :av_requests, :session_files

	belongs_to :event

	belongs_to :event_file_portal_logo, :foreign_key => 'portal_logo_event_file_id', :class_name => "EventFile", :optional => true

	belongs_to :event_file_portal_banner, :foreign_key => 'portal_banner_event_file_id', :class_name => "EventFile", :optional => true

	def updateLogo(params)

		if (params[:portal_logo_file]!=nil) then #update/add photo

			uploaded_io = params[:portal_logo_file]

			if (uploaded_io.original_filename.match(/jpeg|jpg/i)) then
				file_ext = '.jpg'
			elsif (uploaded_io.original_filename.match(/png/i)) then
				file_ext = '.png'
			else
				return
			end

			new_filename = "#{self.event_id}_portal_logo_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			#create directory structure if necessary
			dirname = File.dirname(Rails.root.join('public','event_data', self.event_id.to_s,'portal_logo_photo',new_filename))
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end

			File.open(Rails.root.join('public','event_data', self.event_id.to_s,'portal_logo_photo',new_filename), 'wb',0777) 			do |file|
				file.write(uploaded_io.read)
			end

			if (self.event_file_portal_logo==nil) then
				self.event_file_portal_logo = EventFile.new()
			end

			@event_file_type = EventFileType.where(name:'event_logo').first
			self.event_file_portal_logo.event_file_type_id=@event_file_type.id

			self.event_file_portal_logo.event_id=self.event_id
			self.event_file_portal_logo.name=new_filename
			self.event_file_portal_logo.path="/event_data/#{self.event_id.to_s}/portal_logo_photo/#{new_filename}"
			self.event_file_portal_logo.save()

			self.portal_logo_event_file_id = self.event_file_portal_logo.id
			self.save()

			#resize image
			img = Image.read(Rails.root.join('public').to_s + self.event_file_portal_logo.path).first
  	  		img.change_geometry('150x150') { |cols, rows, img|
  	  			img.resize!(cols,rows)
  	  		}
  	  		img.write(Rails.root.join('public').to_s + self.event_file_portal_logo.path)

		end

		if (params[:portal_banner_file]!=nil) then #update/add photo

			uploaded_io = params[:portal_banner_file]

			#upload the speaker photo
			if (uploaded_io.original_filename.match(/jpeg|jpg/i)) then
				file_ext = '.jpg'
			elsif (uploaded_io.original_filename.match(/png/i)) then
				file_ext = '.png'
			else
				return
			end

			new_filename = "#{self.event_id}_portal_banner_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			#create directory structure if necessary
			dirname = File.dirname(Rails.root.join('public','event_data', self.event_id.to_s,'portal_banner_photo',new_filename))
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end

			File.open(Rails.root.join('public','event_data', self.event_id.to_s,'portal_banner_photo',new_filename), 'wb',0777) 			do |file|
				file.write(uploaded_io.read)
			end

			if (self.event_file_portal_banner==nil) then
				self.event_file_portal_banner = EventFile.new()
			end

			@event_file_type = EventFileType.where(name:'event_logo').first
			self.event_file_portal_banner.event_file_type_id=@event_file_type.id

			self.event_file_portal_banner.event_id=self.event_id
			self.event_file_portal_banner.name=new_filename
			self.event_file_portal_banner.path="/event_data/#{self.event_id.to_s}/portal_banner_photo/#{new_filename}"
			self.event_file_portal_banner.save()

			self.portal_banner_event_file_id = self.event_file_portal_banner.id
			self.save()

		end

	end

end
