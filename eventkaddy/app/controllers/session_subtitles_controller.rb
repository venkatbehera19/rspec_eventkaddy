class SessionSubtitlesController < ApplicationController
	layout 'subevent_2013'
	before_action :authorized?

	def index
		@session = Session.find_by(id: params[:id])
		redirect_to root_url if @session.nil?
		@subtitles = []
		if @session.subtitle_file_location
			@subtitles = JSON.parse(@session.subtitle_file_location)
		end
	end

	def new
		@session = Session.find_by(id: params[:id])
	end

	def create
		@session = Session.find_by(id: params[:id])
		label = params[:label]
		srclang = params[:srclang]
		@subtitle = params[:subtitle]

		event = Event.find(session[:event_id])
		@target_path = Rails.root.join('public','event_data', session[:event_id].to_s,'subtitles')
		@file_name = @subtitle.original_filename
		cloud_storage_type_id = event.cloud_storage_type_id
		cloud_storage_type = nil

		unless cloud_storage_type_id.blank?
			cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
		end

		#EventFileType.new(name: 'session_subtitle')
		event_file_type_id 			= EventFileType.find_by(name:'session_subtitle').id
		event_file							= EventFile.where(event_id: session[:event_id], event_file_type_id: event_file_type_id, path: "/event_data/269/subtitles/#{@file_name}").first_or_initialize

		write_temp_file

		UploadEventFile.new({
			event_file: event_file,
			file: @file,
			target_path: @target_path,
			new_filename: @file_name,
			cloud_storage_type: cloud_storage_type,
			content_type: MIME::Types.type_for(@file.path).first.content_type,
			public_ack: true
		}).call

		subtitle_file_location = @session.subtitle_file_location || []
		subtitle_file_location = JSON.parse(subtitle_file_location) if subtitle_file_location.present?
		subtitle_info = {"label": label, "srclang": srclang, "src": event_file.path, "default": "default"}
		subtitle_file_location.push(subtitle_info)
		@session.subtitle_file_location = subtitle_file_location.to_json
		@session.save

		delete_temp_file

		redirect_to "/sessions/#{@session.id}/subtitles"

	end

	def edit
		@session = Session.find_by(id: params[:id])
		if @session
			subtitle_file_location = @session.subtitle_file_location
			subtitle_file_location_json = JSON.parse subtitle_file_location rescue nil
		end

		if @session && subtitle_file_location_json
			@sel_subtitle = subtitle_file_location_json.select{ |subtitle| subtitle['src'] == params['src'] }
			event_file_type_id = EventFileType.find_by(name:'session_subtitle').id
			event_file = EventFile.find_by(event_id: session[:event_id], event_file_type_id: event_file_type_id, path: @sel_subtitle[0]['src'])
			if event_file
				@subtitle_content = event_file.file_content
			end
		else
			redirect_to root_url
		end
	end

	def update
		@session = Session.find_by(id: params[:id])
		if @session
			subtitle_file_location = @session.subtitle_file_location
			subtitle_file_location_json = JSON.parse subtitle_file_location rescue nil
		end


		if @session && subtitle_file_location_json
			@sel_subtitle = subtitle_file_location_json.select{ |subtitle| subtitle['src'] == params['src'] }
			label = params[:label]
			srclang = params[:srclang]
			@subtitle = params[:subtitle]

			event = Event.find(session[:event_id])
			@target_path = Rails.root.join('public','event_data', session[:event_id].to_s,'subtitles')
			@file_name = @sel_subtitle[0]['src'].split('/')[-1]
			cloud_storage_type_id = event.cloud_storage_type_id
			cloud_storage_type = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
			end

			event_file_type_id 			= EventFileType.find_by(name:'session_subtitle').id
			event_file							= EventFile.where(event_id: session[:event_id], event_file_type_id: event_file_type_id, path: "/event_data/269/subtitles/#{@file_name}").first

			write_temp_file('edit', @subtitle)
 
			UploadEventFile.new({
				event_file: event_file,
				file: @file,
				target_path: @target_path,
				new_filename: @file_name,
				cloud_storage_type: cloud_storage_type,
				content_type: MIME::Types.type_for(@file.path).first.content_type,
				public_ack: true
			}).call

			subtitle_info = {"label": label, "srclang": srclang, "src": event_file.path, "default": "default"}
			subtitle_file_location_json.delete(@sel_subtitle[0])
			subtitle_file_location_json.push(subtitle_info)
			@session.subtitle_file_location = subtitle_file_location_json.to_json
			@session.save

			delete_temp_file

			redirect_to "/sessions/#{@session.id}/subtitles"
		else
			redirect_to root_url
		end
	end

	def destroy
		session = Session.find_by(id: params[:id])
		if session
			subtitles = session.subtitle_file_location
			subtitles_json = JSON.parse(subtitles)
			to_remove = subtitles_json.select{|subtitle| subtitle['src'] == params['src']}
			subtitles_json.delete(to_remove[0])
			session.subtitle_file_location = subtitles_json.to_json
			session.save
			event_file_type_id = EventFileType.find_by(name:'session_subtitle').id
			event_file = EventFile.find_by(event_id: session[:event_id], event_file_type_id: event_file_type_id, path: params['src'])
			event_file.destroy if event_file
			redirect_to "/sessions/#{session.id}/subtitles"
		else
			redirect_to root_url
		end
	end

	private

	def authorized?
		unless current_user && (current_user.role?(:super_admin) || current_user.role?(:client))
			render :text => "You must be logged in as a client to access this page."
		else
			true
		end
	end

	def write_temp_file(type='new', file_params=nil)
		FileUtils.mkdir_p(@target_path) unless File.directory?(@target_path)

		if type == 'new'
			File.open("#{@target_path}/#{@file_name}", 'wb', 0777) { |f| f.write(@subtitle.read) }
		elsif type == 'edit'
			File.open("#{@target_path}/#{@file_name}", 'wb', 0777) { |f| f.write(file_params)}
		end

		@file = File.open("#{@target_path}/#{@file_name}")
	end
	
	def delete_temp_file
		File.delete(@file.path) if File.exists? @file.path
	end


end
