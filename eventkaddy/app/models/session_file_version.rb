class SessionFileVersion < ApplicationRecord
  	include ActiveModel::ForbiddenAttributesProtection
	attr_accessor :document, :updating
	require 'rack/mime'

	belongs_to :session_file
	belongs_to :event_file, :dependent => :destroy
	belongs_to :user
	belongs_to :event

	validate :file_size
	validate :file_type

	# validates :event_file_id, presence: true

	before_destroy :removeJsonEntry

  # smell: convoluted conditions.
	def file_size
		if (!(document.nil?) && document.size > 150000000) then
			errors.add("File", "cannot be more than 150mb.")
		elsif (document.nil? && !(@updating)) then
			errors.add("File", "must be selected to upload.")
		end
	end

  # smell: convoluted
	def file_type
		if (!document.nil?) then
			m = document.original_filename.match(/.*(.doc|.docx|.ods|.pdf|.txt|.text|.rtf|.ppt|.pptx|.xls|.xlsx|.mov|.mp4|.mp3|.m4v|.pez)$/i)

			if m==nil then
				errors.add("File", "must be one of the following types: .doc|.docx|.ods|.pdf|.txt|.text|.rtf|.ppt|.pptx|.xls|.xlsx|.mov|.mp4|.mp3|.m4v|.pez")
			end
		elsif (document.nil? && !(@updating)) then
			errors.add("File", "must be selected to upload.")
		end
	end

	def updateFile(params)

		if document!=nil && document.size < 150000000 && document.size > 0


			uploaded_io = document

			m = uploaded_io.original_filename.match(/.*(.doc|.docx|.ods|.pdf|.txt|.text|.rtf|.ppt|.pptx|.xls|.xlsx|.mov|.mp4|.mp3|.m4v|.pez)$/i)
			if (m!=nil) then
				file_ext = m[1]
			else
				return
			end

			unless params[:no_user]
				new_filename = "#{session_file.session.session_code}_#{uploaded_io.original_filename.chomp(File.extname(uploaded_io.original_filename))}_#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_ext}"
			else #event.rb special upload
				new_filename = uploaded_io.original_filename
			end

			new_filename.gsub!(/\s/,'_')
			new_filename.gsub!(/[^0-9A-Za-z.\-]/, '_')
			target_path   					= Rails.root.join('public','event_data', event_id.to_s,'session_files')
			cloud_storage_type_id   = Event.find(event_id).cloud_storage_type_id
			cloud_storage_type      = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type 		= CloudStorageType.find(cloud_storage_type_id)
			end
			event_file_type_id 			= EventFileType.where(name:'session_file').first.id
			event_file							= EventFile.create(event_id: event_id, event_file_type_id: event_file_type_id)
			UploadEventFile.new(
				event_file:              event_file,
				file:                    uploaded_io,
				target_path:             target_path,
				new_filename:            new_filename,
				event_file_owner: 			 self,
				event_file_assoc_column: :event_file_id,
				cloud_storage_type:      cloud_storage_type
			).call
      # this actually shouldn't even happen here, probably
      session_file.session.update_session_file_urls_json
		end
	end

  # might have to keep this old way of doing things, although it isn't ideal.
	def removeJsonEntry(sfu = SessionFileUrlsEntity)

		def this_file_is_the_latest_version(session_file_versions)
			event_file.path === session_file_versions.first.event_file.path
		end

		session_file_urls = sfu.new json: session_file.session.session_file_urls
		## should not remove by sf_id, as we want to remove this specific version
		## bugfix for bad bns configuration. Safe to remove after BNS 2016 is over.
		path = event_id == 20 || event_id == 77 || event_id == 104 ? "https://cms.eventkaddy.net#{event_file.path}" : event_file.path
		session_file_urls.remove_by [{url:path}] if event_file
		session_file_versions = session_file.session_file_versions.order('created_at DESC')

		if session_file_versions.length > 1 && this_file_is_the_latest_version(session_file_versions) && session_file_versions.second.event_file
			session_file_urls.add [{"title" => session_file.title,
				"url"   => session_file_versions.second.event_file.path,
				"type"  => sfu.extension(session_file_versions.second.event_file.mime_type),
				"sf_id" => session_file.id}]
		end
		## bugfix for bad bns configuration. Safe to remove after BNS 2016 is over.
		session_file_urls.force_urls_to_use_full_path if event_id == 20 || event_id == 77 || event_id == 104
		session_file.session.update! session_file_urls:session_file_urls.json
	end

  def siblings
    SessionFileVersion.where(session_file_id: session_file_id).where("id != ?", id)
  end

  def set_to_final_version
    # It is actually important that the model being set to final not be
    # included in the siblings, or mysql will make the second commit fail
    # quite a gotcha!
    siblings.update_all final_version: 0
    update! final_version: 1
  end

end
