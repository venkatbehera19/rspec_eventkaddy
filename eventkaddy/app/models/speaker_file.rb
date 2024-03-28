class SpeakerFile < ApplicationRecord
	include ActiveModel::ForbiddenAttributesProtection

  attr_accessor :document, :updating, :event_name

  belongs_to :event_file, :dependent => :destroy
  belongs_to :speaker
  belongs_to :event
  belongs_to :speaker_file_type
  validate :file_type
	# validate :file_size

	# def file_size
	# 	if (!(document.nil?) && document.size > 400000) then
	# 		errors.add(:event_file, "cannot be more than 400 kilobytes.")
	# 	elsif (document.nil? && !(@updating)) then
	# 		errors.add(:event_file, "must be selected to upload.")
	# 	end
	# end

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

		if (params[:event_file]!=nil)# && document.size < 400000) then #update/add speaker file

			uploaded_io = params[:event_file]

			#upload session file
			m = uploaded_io.original_filename.match(/.*(.doc|.docx|.ods|.pdf|.txt|.text|.rtf|.ppt|.pptx|.xls|.xlsx|.mov|.mp4|.mp3|.m4v|.pez)$/i)
			if (m!=nil) then
				file_ext = m[1]
			else
				return
			end

			new_filename = "#{self.speaker_id}_#{self.speaker_file_type.name.gsub!(/\s/,'_')}_#{self.speaker.email}_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

			#create directory structure if necessary
			dirname = File.dirname(Rails.root.join('download','event_data', self.event_id.to_s,'speaker_files',new_filename))
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end

			File.open(Rails.root.join('download','event_data', self.event_id.to_s,'speaker_files',new_filename), 'wb') 			do |file|
				file.write(uploaded_io.read)
			end

			if (self.event_file==nil) then
				self.event_file = EventFile.new()
			end

			@event_file_type = EventFileType.where(name:'speaker_pdf').first
			self.event_file.event_file_type_id=@event_file_type.id

			self.event_file.event_id=self.event_id
			self.event_file.name=new_filename
			self.event_file.path="/download/event_data/#{self.event_id.to_s}/speaker_files/#{new_filename}"
			self.event_file.save()

		end

	end#updateFile

	# def deleteFile(params)

	# 	if (self.event_file!=nil) then
	# 		File.delete(Rails.root.join('public', 'event_data', self.event_id.to_s, 'speaker_files', self.event_file.name))
	# 		self.event_file.delete
	# 	end

	# end

	def bundleFiles
	bundle_filename = "#{self.event_name}_speaker_files.zip"
	dir             = Rails.root.join('public','event_data', self.event_id.to_s,'speaker_photos')
	downloaddir     = Rails.root.join('download','event_data', self.event_id.to_s,'speaker_files')

	  #create directory structure if necessary
	  unless File.directory?(downloaddir)
	  	FileUtils.mkdir_p(downloaddir)
	  end

	  unless File.directory?(dir)
	  	FileUtils.mkdir_p(dir)
	  end

      FileUtils.cd(downloaddir) do
	      FileUtils.rm bundle_filename,:force => true


      Zip::ZipFile.open(bundle_filename, Zip::ZipFile::CREATE) { |zipfile|
        Dir.foreach(downloaddir) do |item|
          next if item == '.' or item == '..'
          item_path = "#{downloaddir}/#{item}"
          next if item_path.include? ".zip"
          zipfile.add("speaker_files/"+item,item_path) if File.file?item_path
        end
        FileUtils.cd(dir) do
        	photodir = Rails.root.join('public','event_data', self.event_id.to_s,'speaker_photos')
			unless File.directory?(photodir)
				FileUtils.mkdir_p(photodir)
			end
        	Dir.foreach(photodir) do |item|
	          next if item == '.' or item == '..'
	          item_path = "#{photodir}/#{item}"
	          zipfile.add("speaker_photos/"+item,item_path) if File.file?item_path
	        end
    	end
        FileUtils.cd('..') do
        	pdfdir = Rails.root.join('public','event_data', self.event_id.to_s,'speaker_pdfs')
			unless File.directory?(pdfdir)
				FileUtils.mkdir_p(pdfdir)
			end
        	Dir.foreach(pdfdir) do |item|
	          next if item == '.' or item == '..'
	          item_path = "#{pdfdir}/#{item}"
	          zipfile.add("speaker_pdfs/"+item,item_path) if File.file?item_path
	        end
    	end
      }


      	File.chmod(0644,bundle_filename)
	  end

    end

 	# def bundleAllFiles
  #     bundle_filename = "#{self.first.event.name.gsub!(/\s/,'_')}_speaker_files.zip"
  #     dir = Rails.root.join('public','event_data', self.event_id.to_s,'speaker_files')

  #     FileUtils.cd(dir) do
	 #      FileUtils.rm "#{self.speaker_id}_files.zip",:force => true


  #     Zip::ZipFile.open(bundle_filename, Zip::ZipFile::CREATE) { |zipfile|
  #       Dir.foreach(dir) do |item|
  #         next if item == '.' or item == '..'
  #         item_path = "#{dir}/#{item}"
  #         zipfile.add( item,item_path) if File.file?item_path
  #       end
  #     }


  #     	File.chmod(0644,bundle_filename)
	 #  end

  #   end

end
