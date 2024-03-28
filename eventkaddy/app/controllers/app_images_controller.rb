class AppImagesController < ApplicationController

	layout 'subevent_2013'

	def index
    unless params[:app_image_type_id].blank?
      session[:app_image_type_id] = params[:app_image_type_id]
    end
    @app_image_type       = AppImageType.find(session[:app_image_type_id])
		@app_images           = AppImage.where(event_id:session[:event_id],parent_id:0,app_image_type_id:@app_image_type.id).order('position ASC')
	end

  def new
    @app_image            = AppImage.new
    @app_image_type       = AppImageType.find(session[:app_image_type_id])
    @app_images           = AppImage.where(event_id:session[:event_id],parent_id:0,app_image_type_id:@app_image_type.id).order('position ASC')
   end

  def edit
    @app_image            = AppImage.find(params[:id])
    @app_image_type       = AppImageType.find(session[:app_image_type_id])
    @app_images           = AppImage.where(event_id:session[:event_id],parent_id:0,app_image_type_id:@app_image_type.id).order('position ASC')
   end

  def select_type
    @app_image_types      = AppImageType.all
  end

	def create
		@app_image_type       = AppImageType.find(session[:app_image_type_id])
    @app_images           = AppImage.where(event_id:session[:event_id],parent_id:0,app_image_type_id:@app_image_type.id)
    type_name = @app_image_type.name
		link      = params[:app_image][:link]
    json      = params[:json]

		params[:event_files].each { |file| AppImage.create_app_images(session[:event_id], file, type_name, link, json, @app_images) }

    respond_to do |format|
      format.html { redirect_to app_images_path, notice: "Images created." }
    end
	end

	def update
		app_image = AppImage.find(params[:id])
    @app_image_type       = AppImageType.find(session[:app_image_type_id])
    @app_images           = AppImage.where(event_id:session[:event_id],parent_id:0,app_image_type_id:@app_image_type.id)
		link      = params[:app_image][:link]
    json      = params[:json]

		if params[:event_files]
		  app_image.update_app_images(params[:event_files].first, link, json, @app_images)
		else
      unless json.blank?
        app_image.update_position_only(json, @app_images)
      end
      unless link.blank?
			 app_image.update_links(link)
      end
		end
    respond_to do |format|
      format.html { redirect_to app_images_path, notice: "Image updated." }
    end
	end

  def destroy
    app_image = AppImage.find(params[:id])
    app_image_type = app_image.app_image_type
  	app_image.remove_original_and_copies
    respond_to do |format|
        format.html { redirect_to app_images_path, :notice => "Image successfully deleted."}
    end
  end

#POST
	#send list of app_image templates of a specified type
	#from cms to app
	def list_templates
 		if access_allowed?

      set_access_control_headers
			headers['Content-Type'] = "text/javscript; charset=utf8"

			proxy_key = params['api_proxy_key']
			event_id = params['event_id']

			@result = {}
			@result["status"] = false
			@result["error_messages"] = []

			if (proxy_key == API_PROXY_KEY) then

				#fetch app_images
				app_images = AppImage.select('app_images.id AS app_image_id, app_images.event_file_id AS event_file_id,
					app_image_types.name AS type, app_images.link AS image_link').joins('
					JOIN app_image_types ON (app_images.app_image_type_id=app_image_types.id)
					').where(event_id:event_id,is_template:true)

				if (app_images.length >=1) then

					@result["status"]=true
					app_image_set = []

					app_images.each do |app_image|

						app_img_obj = {}
						app_img_obj["app_image_id"] = app_image.app_image_id
						app_img_obj["event_file_id"] = app_image.event_file_id
						app_img_obj["image_link"] = app_image.image_link
						app_img_obj["type"] = app_image.type

						app_image_set << app_img_obj
					end

					@result["app_image_templates"] = app_image_set
				else
					@result["error_messages"] << "Error: No app_image templates exist for event id: #{event_id}"
				end
			else
				@result["error_messages"] << "Error: Incorrect proxy key."
			end

			render :json => @result.to_json
		else
			head :forbidden
		end
	end


#POST
	#send url for a specific app_image, given the
	#device type and image type requested
	def fetch_sized_image_url
 		if access_allowed?

      set_access_control_headers
			headers['Content-Type'] = "text/javscript; charset=utf8"

			proxy_key = params['api_proxy_key']
			event_id = params['event_id']
			device_type = params['device_type']
			image_type = params['image_type']
			parent_id = params['template_app_image_id']

			@result = {}
			@result["status"] = false
			@result["error_messages"] = []

			if (proxy_key == API_PROXY_KEY) then

				#fetch app_image for given device_type and image_type
				app_image_types = AppImageType.where(name:image_type)

				if (app_image_types!=nil && app_image_types.length==1) then

					app_image_type_id = app_image_types.first.id
					device_types = DeviceType.where(name:device_type)

					if (device_types!=nil && device_types.length==1) then

						device_type_id = device_types.first.id

						app_images = AppImage.select('event_files.path AS file_url').joins('
						JOIN app_image_types ON (app_images.app_image_type_id=app_image_types.id)
						JOIN device_types ON (app_images.device_type_id=device_types.id)
						JOIN event_files ON (app_images.event_file_id=event_files.id)
						').where(event_id:event_id,device_type_id:device_type_id,
						app_image_type_id:app_image_type_id,is_template:false,parent_id:parent_id)

						if (app_images!=nil && app_images.length == 1) then

							@result["status"]=true
							@result["sized_image_url"] = app_images.first.file_url
						elsif (app_images==nil)

							@result["status"]=false
							@result["error_messages"] << "Error: > no app image found on cms for device type #{device_type} and image type #{image_type}"
						else (app_images.length > 1)

							@result["status"]=false
							@result["error_messages"] << "Error: more than 1 app image found on cms for device type #{device_type} and image type #{image_type}"
						end

					else
						@result["status"] = false
						@result["error_messages"] << "Error: device type #{device_type} lookup failed"
					end

				else
					@result["status"] = false
					@result["error_messages"] << "Error: image type #{image_type} lookup failed"
				end





			else
				@result["error_messages"] << "Error: Incorrect proxy key."
			end

			render :json => @result.to_json
		else
			head :forbidden
		end
	end




	def options
	  if access_allowed?
	    set_access_control_headers
	    head :ok
	  else
	    head :forbidden
	  end
	end

	private

	def set_access_control_headers
	  headers['Access-Control-Allow-Origin'] = '*' # request.env['HTTP_ORIGIN']
	  headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
	  headers['Access-Control-Max-Age'] = '1000'
	  headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type'
	end

	def access_allowed?
	  return true
	  #allowed_sites = [request.env['HTTP_ORIGIN']] #you might query the DB or something, this is just an example
	  #return allowed_sites.include?(request.env['HTTP_ORIGIN'])
	end

  def app_image_params
    params.require(:app_image).permit(:event_id, :parent_id, :is_template, :event_file_id, :app_image_type_id, :device_type_id, :app_image_size_id, :name, :link, :position)
  end

end