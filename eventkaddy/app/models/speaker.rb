class Speaker < ApplicationRecord
	include ActiveModel::ForbiddenAttributesProtection

  require 'open-uri'
	include ImageHaver
	extend ImageHaver

	#RE-ENABLE EMAIL VALIDATION WHEN FEATURE IS FINISHED
  #	validates :email,
  #          :presence => true,
  #          :uniqueness => true
  #          :format => { :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i }


    #validates_length_of :speaker_portal_password,:minimum=>6

	belongs_to :speaker_type, :optional => true
	belongs_to :event_file_photo, :foreign_key => 'photo_event_file_id', :class_name => "EventFile", :dependent => :destroy, :optional => true
	belongs_to :event_file_cv,    :foreign_key => 'cv_event_file_id',    :class_name => "EventFile", :dependent => :destroy, :optional => true
	belongs_to :event_file_fd,    :foreign_key => 'fd_event_file_id',    :class_name => "EventFile", :dependent => :destroy, :optional => true
	belongs_to :event
  belongs_to :user, :foreign_key => 'user_id', :optional => true

	has_many :sessions_speakers,       :dependent => :destroy
	has_many :sessions,                :through   => :sessions_speakers
	has_one :speaker_travel_detail,    :dependent => :destroy
	has_one :speaker_payment_detail,   :dependent => :destroy
	has_many :session_av_requirements, :dependent => :destroy
	has_many :speaker_files,           :dependent => :destroy # callback exists to destroy dependent event_file
  has_many :session_keywords

	before_save :to_lower

	before_create :generate_token

  after_commit :update_speaker_code_if_blank
  
  # must be 6 characters or more...
  def generate_and_save_simple_password
    o        = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten # the alphabete
    password = (0...6).map { o[rand(o.length)] }.join

    User.first_or_create_for_speaker self, password
    password
  end

  def self.array_of_speakers_with_ratings_per_session event_id
    find_by_sql ["SELECT first_name,
    last_name,
    speakers.id,
    feedbacks.session_id AS session_id,
    email,
    session_code,
    AVG(case when feedbacks.speaker_id IS NOT NULL then CAST(feedbacks.rating AS DECIMAL(10,2)) else null end) AS rating
    FROM speakers
    LEFT JOIN feedbacks ON feedbacks.speaker_id=speakers.id AND feedbacks.event_id=? AND feedbacks.created_at>='2015-04-19 00:00:00' AND feedbacks.rating>-1
    LEFT JOIN sessions ON feedbacks.session_id=sessions.id
    WHERE speakers.event_id=? AND rating IS NOT NULL
    GROUP BY feedbacks.session_id, feedbacks.speaker_id
    ORDER BY session_code ASC, last_name ASC",event_id,event_id]
  end

  def confirmed?
    !!self.confirmed_at
  end

  def generate_confirmation_token
    self.confirmation_token = loop do 
      confirmation_token = SecureRandom.urlsafe_base64(nil, false)
      break confirmation_token unless Speaker.exists?(confirmation_token: confirmation_token)
    end
  end

  def published?
    !unpublished
  end

  def update_speaker_code_if_blank
    self.update!(speaker_code:"ourcode" + self.id.to_s) if self.speaker_code.blank?
  end

  def full_name
		return "#{honor_prefix} #{first_name} #{last_name} #{honor_suffix}".strip
	end

  def to_lower
  	self.email = self.email.downcase unless self.email.nil?
  end

	def updatePhoto(params, options = {})
		new_filename = options.fetch(:new_filename, false)
    event_file_type_id = EventFileType.where(name:'attendee_photo').first.id

    def return_associated_event_file(event_file_type_id, new_filename)
			if self.event_file_photo then self.event_file_photo	else self.event_file_photo = EventFile.create!(event_id:event_id, event_file_type_id: event_file_type_id, path: "/event_data/#{event_id.to_s}/speaker_photos/#{new_filename}");	end
		end

    image_file         = params[:photo_file]
    file_extension     = return_jpg_or_png_file_extension_else_nil(image_file)
		return unless file_extension == '.jpg' || file_extension == '.png'
		new_filename       = "#{self.first_name}_#{self.last_name}_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_extension}" unless new_filename
		event_file         = return_associated_event_file(event_file_type_id, new_filename)

    # removed as this currently toggles 'online version' of photo file
    # update! photo_filename:filename
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, 'speaker_photos').to_path,
      new_filename:            new_filename,
      event_file_owner:        self,
      new_height:              150,
      new_width:               150,
      event_file_assoc_column: :photo_event_file_id,
      cloud_storage_type:      cloud_storage_type
    ).call
  end

  #added for AVMA 2017 speaker photo script
  # def updatePhoto_v2
  #   event_file_type_id  = EventFileType.where(name:'speaker_photo').first.id
  #   # file_extension     = File.extname image_file.original_filename
  #   # basename           = File.basename image_file.original_filename, file_extension
  #   filename            = "#{self.first_name}_#{self.last_name}_photo_#{Time.now.strftime('%Y%m%d%H%M%S')}.jpg"
  #   # filename           = "#{basename.downcase.gsub(' ', '_')}#{Time.now.strftime('%Y%m%d%H%M%S')}"
  #   image_file          = self.photo_filename
  #   photo_event_file_id = self.photo_event_file_id
    
  #   puts filename
  #   puts image_file
  #   puts "photo_file_id: #{photo_event_file_id}"

  #   event_file = photo_event_file_id ? EventFile.find(photo_event_file_id)
  #                                    : EventFile.create(event_id:event_id, event_file_type_id:event_file_type_id)

  #   # removed as this currently toggles 'online version' of photo file
  #   # update! photo_filename:filename
  #   UploadEventFileImage.new(
  #     event_file:               event_file,
  #     image:                    image_file,
  #     target_path:              Rails.root.join('public', 'event_data', event_id.to_s, 'speaker_photos').to_path,
  #     new_filename:             filename,
  #     event_file_owner:         self,
  #     event_file_assoc_column:  :photo_event_file_id
  #   ).call
  # end

  def online_url
		#event.cms_url + event_file_photo.path if photo_event_file_id && event.cms_url
    self.event_file_photo ? self.event_file_photo.return_public_url()['url'] : nil
	end

  # purely to fix different naming convention of other models for use with
  # upload_event_file_image service
  def online_url_column
    photo_filename
  end

  def online_url_column=(string)
    update! photo_filename: string
  end

  def online_photo?
    !photo_filename.nil? && !!photo_filename.match(/^http/)
  end

  def createPhotoPlaceholder(new_filename)

		if (self.event_file_photo==nil) then
			self.event_file_photo = EventFile.new()
		end

		@event_file_type                         = EventFileType.where(name:'speaker_photo').first
		self.event_file_photo.event_file_type_id = @event_file_type.id
		self.event_file_photo.event_id           = self.event_id
		self.event_file_photo.name               = self.photo_filename
		self.event_file_photo.path               = "/event_data/#{self.event_id.to_s}/speaker_photos/#{new_filename}"
		self.event_file_photo.save()
	end

  def updateCV(params)

		if (params[:cv_file]!=nil) then #update/add photo

			uploaded_io = params[:cv_file]

			#upload the speaker photo
			m = uploaded_io.original_filename.match(/.*(.doc|.docx|.ods|.pdf|.txt|.text|.rtf|.ppt|.pptx|.xls|.xlsx|.pez)$/i)
			if (m!=nil) then
				file_ext = m[1]
			else
				return
			end

			new_filename = "#{self.first_name}_#{self.last_name}_cv_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"
			target_path   					= Rails.root.join('public','event_data', self.event_id.to_s,'speaker_cvs')
			cloud_storage_type_id   = Event.find(self.event_id).cloud_storage_type_id
			cloud_storage_type      = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type 		= CloudStorageType.find(cloud_storage_type_id)
			end
      event_file_type_id 			= EventFileType.where(name:'speaker_cv').first.id
      if (self.event_file_cv==nil) then
				self.event_file_cv = EventFile.create(event_id: self.event_id, event_file_type_id: event_file_type_id)
			end
			UploadEventFile.new(
				event_file:              self.event_file_cv,
				file:                    uploaded_io,
				target_path:             target_path,
				new_filename:            new_filename,
				event_file_owner: 			 self,
				event_file_assoc_column: :cv_event_file_id,
				cloud_storage_type:      cloud_storage_type
      ).call
		end

	end


  def updateFD(params)

		if (params[:fd_file]!=nil) then #update/add photo

			uploaded_io = params[:fd_file]

			#upload the speaker photo
			m = uploaded_io.original_filename.match(/.*(.doc|.docx|.ods|.pdf|.txt|.text|.rtf|.ppt|.pptx|.xls|.xlsx|.pez)$/i)
			if (m!=nil) then
				file_ext = m[1]
			else
				return
			end

			new_filename = "#{self.first_name}_#{self.last_name}_fd_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			target_path   					= Rails.root.join('public','event_data', self.event_id.to_s,'speaker_fds')
			cloud_storage_type_id   = Event.find(self.event_id).cloud_storage_type_id
			cloud_storage_type      = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type 		= CloudStorageType.find(cloud_storage_type_id)
			end
      event_file_type_id 			= EventFileType.where(name:'speaker_fd').first.id
      if (self.event_file_fd==nil) then
				self.event_file_fd = EventFile.create(event_id: self.event_id, event_file_type_id: event_file_type_id)
			end
			UploadEventFile.new(
				event_file:              self.event_file_fd,
				file:                    uploaded_io,
				target_path:             target_path,
				new_filename:            new_filename,
				event_file_owner: 			 self,
				event_file_assoc_column: :fd_event_file_id,
				cloud_storage_type:      cloud_storage_type
      ).call
		end

	end

  def eventHasPortal(event_id)
    event = Event.find(event_id)
    event.domains.length > 0
	end

  def generate_token
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Speaker.exists?(token: random_token)
    end
  end

end
