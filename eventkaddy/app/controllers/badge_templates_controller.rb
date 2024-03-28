class BadgeTemplatesController < ApplicationController
	#load_and_authorize_resource
	layout 'subevent_2013'

	def index
		@badges = BadgeTemplate.where(event_id: session[:event_id])
	end

	def new
	end

	def create
		@badge = BadgeTemplate.new(badge_template_param)
		@badge.event_id = session[:event_id]
		if @badge.save
			params['files'].present? && params['files'].each do |key, value|
																	upload_image value, "badge_template_#{key}"
																end
			render json: {status: :ok, redirect_to: '/badge_templates'}
		else
			render json: {status: :unprocessable_entity, message: @badge.errors.full_messages}
		end
	end

	def edit
		@badge = BadgeTemplate.find_by(id: params[:id])
		@event_files = EventFile.where(name: @badge.json.keys.map!{|a| "badge_template_#{a}"})
		@img_src_urls = {}
		@event_files.each do |event_file|
			@img_src_urls[event_file.name.gsub('badge_template_', '')] = event_file.return_public_url['url']
		end
	end

	def update
		@badge = BadgeTemplate.find_by(id: params[:id])
		if @badge.update(badge_template_param)
			render json: {status: :ok, redirect_to: '/badge_templates'}
		else
			render json: {status: :unprocessable_entity, message: @badge.errors.full_messages}
		end
	end

	def destroy
		badge = BadgeTemplate.find_by(id: params[:id])
		badge.destroy if badge
		message = badge ? 'Badge Template destroyed' : 'Badge Not Found'
		redirect_to '/badge_templates', notice: message
	end


	def fetch_preview_from_labelary
		if params['files'].present?
			params['files'].each do |key, value|
				upload_image value, "badge_template_#{key}"
			end
		end

 		badge_size_json = params['badge_template']['json'].select{|key, value| value['type'] == 'badge_size'}
		badge_width = 400
 		if badge_size_json
 			badge_length = badge_size_json.values[0]['height'].to_i
			badge_width = badge_size_json.values[0]['width'].to_i
 		end

		@event_files = EventFile.where(name: params['badge_template']['json'].keys.map!{|a| "badge_template_#{a}"})
		data = Attendee.find_by(event_id: session[:event_id]).as_json
		zpl_string  = "^XA"

		dataHash = params["badge_template"]["json"] || {}

		dataHash.each do |key, value|
			if value['textValue']
				to_be_printed = value["textValue"]
				to_be_printed = to_be_printed.gsub(/{{(.*?)}}/) do |match|
					data[$1]
				end

				if value["type"] == 'text'
					font_type        = value['fontType']
					orientation_type = value['orientiationType']
					font_size        = value['fontSize']
					x 							 = value['x']
					y 							 = value['y']
					textValue = ZplGeneratorService.new(
						font_type,
						orientation_type,
						font_size,
						to_be_printed,
						value['x'],
						value['y'],
						badge_width
					).call
					zpl_string.concat(textValue)

				elsif value['type'] == 'qr'
					qr_code = Zebra::Zpl::Qrcode.new(
					  data:             to_be_printed,
					  position:         [value["x"].to_f, value["y"].to_f],
					  scale_factor:     6,
					  correction_level: 'H'
					)
					zpl_string += qr_code.to_zpl
				elsif value['type'] == 'image'
					event_file = @event_files.find{|a| a.name == "badge_template_#{key}"}
					is_reverse = value["isReverse"] == 'true'
					image_code = Zebra::Zpl::Image.new(
										path: perform_inversion(event_file.return_public_url['url'], event_file.name, is_reverse),
										position: [value["x"].to_f, value["y"].to_f],
										width: value["width"].to_f * 2,
										height: value["height"].to_f * 2,
										black_threshold: 0.3
					) if event_file
					zpl_string += image_code.to_zpl
				end
			end
		end

		zpl_string.concat('^XZ')  # Reset print orientation to normal

		# target_path = Rails.root.join('public', 'event_data', session[:event_id].to_s, 'badge_template_demo')
		# FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
		# `curl --get http://api.labelary.com/v1/printers/8dpmm/labels/4x3/0/ --data-urlencode "#{zpl_string}" > #{target_path}/demo.png`

		request_to_labelary zpl_string, "#{badge_width/100}x#{badge_length/100}"

		render json: {zpl_string: zpl_string, imgSrc: "/event_data/#{session[:event_id]}/badge_template_demo/demo.png"}
	end

	private

	def badge_template_param
		params.require(:badge_template).permit(:name, json: [:id, :x, :y, :fontSize, :textValue, :type, :width, :height, :fontType, :orientiationType, :isReverse])
	end

	def upload_image image_file, filename
		event_id = session[:event_id].to_s
		event_file_type_id = EventFileType.find_or_create_by(name: 'badge_template_image').id
		event_file = EventFile.find_by_name(filename) || EventFile.new(event_id:event_id, event_file_type_id:event_file_type_id)
		if event_file.id.blank?
			target_path = Rails.root.join('public', 'event_data', event_id, 'badge_template_image').to_path
			cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
			unless cloud_storage_type_id.blank?
				cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
			end
			UploadEventFileImage.new(event_file: event_file, image: image_file, target_path: target_path,
				new_filename: filename, cloud_storage_type:cloud_storage_type
				).call
		end
		@event_files << event_file if @event_files
	end

	def request_to_labelary zpl_string, badge_size
		uri = URI "http://api.labelary.com/v1/printers/8dpmm/labels/#{badge_size}/0/"
		http = Net::HTTP.new uri.host, uri.port
		request = Net::HTTP::Post.new uri.request_uri
		request.body = zpl_string
		response = http.request request
		target_path = Rails.root.join('public', 'event_data', session[:event_id].to_s, 'badge_template_demo', 'demo.png')

		case response
		when Net::HTTPSuccess then
		    File.open target_path, 'wb' do |f|
		        f.write response.body
		    end
		else
		    puts "Error: #{response.body}"
		end
	end

	def perform_inversion(image_path, file_name, reverse)
		return image_path if !reverse
		begin
			original_image = Magick::Image.read(image_path).first
			inverted_image = original_image.rotate(180)

			dest = Rails.root.join('public','event_data',event_id.to_s, 'badge_template_image')
			FileUtils.mkdir_p(dest) unless File.directory?(dest)

			original_image_path = File.join('public','event_data',event_id.to_s, 'badge_template_image', file_name)
			original_image.write(original_image_path)

			inverted_image = original_image.rotate(180)
			inverted_image_path = File.join('public','event_data',event_id.to_s, 'badge_template_image', "#{file_name}_inverted.png")

			inverted_image.write(inverted_image_path)

			return inverted_image_path
		rescue => e
			puts "Error performing inversion: #{e.message}"
			return nil
		end

	end
end
