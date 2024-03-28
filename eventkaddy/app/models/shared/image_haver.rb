module ImageHaver
	include Magick

	def returnImageEventFileTypeId(event_file_type_name)
		EventFileType.where(name:event_file_type_name).first.id if EventFileType.where(name:event_file_type_name).first
	end

	def returnImageEventFileTypeName(event_file_type_id)
		event_file_types = EventFileType.where(id:event_file_type_id).length
		if event_file_types > 0 then EventFileType.find(event_file_type_id).name	else nil;	end
	end

	def return_jpg_or_png_file_extension_else_nil(image_file)
		if image_file!=nil
			if (image_file.original_filename.match(/jpeg|jpg/i))
				file_ext = '.jpg'
			elsif (image_file.original_filename.match(/png/i))
				file_ext = '.png'
			else
				nil
			end
		else
			nil
		end
	end

	def resizeImage(event_file, resize_width, resize_height, options = {})#maintain_aspect_ratio
		maintain_aspect_ratio = options.fetch(:maintain_aspect_ratio, true)

		aspect_ratio = '!' unless maintain_aspect_ratio
		path         = Rails.root.join('public').to_s + event_file.path
		if File.exist? path
			img          = Image.read(path).first
			img.change_geometry("#{resize_width}x#{resize_height}#{aspect_ratio}") { |cols, rows, img|	img.resize!(cols,rows) }
			img.write(path)
			event_file.mime_type = img.mime_type
			event_file.size      = img.filesize
		end
	end

	def updateImage(event_file, image_file, directory_path, new_filename)

		if image_file!=nil

			## delete previous image
			File.delete("#{directory_path}/#{event_file.name}") unless event_file.name.blank? || !File.exist?("#{directory_path}/#{event_file.name}")

			unless File.directory?(directory_path)
				FileUtils.mkdir_p(directory_path)
			end

			File.open("#{directory_path}/#{new_filename}", 'wb', 0777) do |file|
				file.write(image_file.read)
			end

			event_file.name               = new_filename
			event_file.path               = "#{directory_path.to_s.slice(directory_path.to_s.index("/event_data")..-1)}/#{new_filename}"
			magick_img                    = Magick::Image::read("#{directory_path}/#{new_filename}").first
			event_file.mime_type          = magick_img.mime_type
			event_file.size               = magick_img.filesize
			event_file.save()

		end

	end

end