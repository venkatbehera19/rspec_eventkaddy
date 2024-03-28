class ExhibitorFile < ApplicationRecord

  # attr_accessible :description, :event_file_id, :event_id, :exhibitor_id, :title, :exhibitor_file_type_id
	attr_accessor :document, :updating

  belongs_to :event_file, :dependent => :destroy, :optional => true
  belongs_to :exhibitor
  belongs_to :event
  belongs_to :exhibitor_file_type

	# validate :file_size
	# validate :file_type

	before_destroy :remove_json_entry

	def file_size
		if !document.nil? && document.size > 750000000
			errors.add("File", "cannot be more than 750mb.")
		elsif document.nil? && !updating
			errors.add("File", "must be selected to upload.")
		end
	end

	def file_type
		if !document.nil?
			m = document.original_filename.match(/.*(.doc|.docx|.ods|.pdf|.txt|.text|.pez|.png|.jpg|.gif|.heic|.eps|.ai|.dwg|.mp4|.mov|.xlsx|.xlsb|.xltx|.ppt|.pptx|.pptm|.csv)$/i)

			if m == nil
				errors.add("File", "must be one of the following types: .doc|.docx|.ods|.pdf|.txt|.text|.pez|.png|.jpg|.gif|.heic|.eps|.ai|.dwg|.mp4|.mov|.xlsx|.xlsb|.xltx|.ppt|.pptx|.pptm|.csv")
			end
		elsif document.nil? && !@updating
			errors.add("File", "must be selected to upload.")
		end
	end


	def updateFile params

		def get_file_extension uploaded_io
			m = uploaded_io.original_filename.match(/.*(.doc|.docx|.ods|.pdf|.txt|.text|.pez|.png|.jpg|.gif|.heic|.eps|.ai|.dwg|.mp4|.mov|.xlsx|.xlsb|.xltx|.ppt|.pptx|.pptm|.csv)$/i)
			if m
				m[1]
			end
		end

		def standardize_filename_and_sanitize uploaded_io, file_ext
			code = !exhibitor.exhibitor_code.blank? ? exhibitor.exhibitor_code : exhibitor.id
			type = exhibitor_file_type.name

			new_filename = "#{code}_#{type}_#{uploaded_io.original_filename.chomp(file_ext)}_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"
			new_filename.gsub!(/\s/,'_')
			new_filename.gsub!(/[^0-9A-Za-z.\-]/, '_')
		end

		def write_exhibitor_file uploaded_io, new_filename
			dirname = File.dirname(Rails.root.join('public', 'event_data', event_id.to_s,'exhibitor_files', new_filename))
      FileUtils.mkdir_p dirname unless File.directory? dirname
			File.open(Rails.root.join('public', 'event_data', event_id.to_s, 'exhibitor_files', new_filename), 'wb') do |file|
				file.write uploaded_io.read
			end
		end

		def create_or_upload_event_file uploaded_io, new_filename
			event_file                    ||= EventFile.new
			event_file_type_id              = EventFileType.where(name:'exhibitor_file').first.id
			event_file.event_file_type_id   = event_file_type_id
			event_file.event_id             = event_id
			event_file.mime_type            = uploaded_io.content_type
			event_file.size                 = uploaded_io.size
			event_file.name                 = new_filename
			event_file.cloud_storage_type_id = 1
			event_file.path                 = "/event_data/#{event_id.to_s}/exhibitor_files/#{new_filename}"
			event_file.cloud_storage_type   = CloudStorageType.find_by(bucket: "videokaddy")
			event_file.save
			update! event_file_id: event_file.id
		end

		def save_urls_as_json efu = ExhibitorFileUrlsEntity
      exhibitor_files_url = efu.new json: exhibitor.exhibitor_files_url
      exhibitor_files_url.remove_by [{ef_id:id}]
      exhibitor_files_url.add [{
        "title" => title,
        "url" => event_file.path,
        "type" => efu.extension(event_file.mime_type),
        "ef_id" => id,
        "efile_id" => event_file_id
#        "ef_id" => event_file.id
      }]
      exhibitor.update! exhibitor_files_url: exhibitor_files_url.json
		end

		if document!=nil && document.size < 750000000 && document.size > 0
			uploaded_io  = document
			file_ext     = get_file_extension(uploaded_io)
			new_filename = standardize_filename_and_sanitize(uploaded_io, file_ext)

			write_exhibitor_file uploaded_io, new_filename
			create_or_upload_event_file uploaded_io, new_filename
			UploadEventFile.new({event_file: self.event_file, file: uploaded_io.tempfile,
				target_path: Rails.root.join('public', 'event_data', event_id.to_s,'exhibitor_files').to_path,
				new_filename: new_filename,
				cloud_storage_type: self.event_file.cloud_storage_type,
				skip_event_file_update: true
			}).call
			save_urls_as_json
		end
	end

  def update_json_entry params, efu = ExhibitorFileUrlsEntity
    exhibitor_files_url = efu.new json: exhibitor.exhibitor_files_url
    exhibitor_files_url.remove_by [{ef_id: id}]
    exhibitor_files_url.add [{
      "title" => title,
      "url" => event_file.path,
      "type" => efu.extension(event_file.mime_type),
      "ef_id" => id
    }]
    exhibitor.update! exhibitor_files_url: exhibitor_files_url.json
  end

	def remove_json_entry efu = ExhibitorFileUrlsEntity
    exhibitor_files_url = efu.new json: exhibitor.exhibitor_files_url
    exhibitor_files_url.remove_by [{ef_id:id}]
    exhibitor.update! exhibitor_files_url: exhibitor_files_url.json
	end
end
