class DeviceAppImageSizesController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource
  
  def index
    unless params[:app_image_type_id].blank?
      session[:app_image_type_id] = params[:app_image_type_id]
    end
    @app_image_settings  = DeviceAppImageSize.joins(:device_type).where(app_image_type_id:session[:app_image_type_id]).where("device_types.leaf=?", 1).order("device_types.name")
    puts "test: #{session[:app_image_type_id]}"
    @app_image_type = AppImageType.find(session[:app_image_type_id])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @app_image_settings }
    end
  end

  def new
    @app_image_setting = DeviceAppImageSize.new
    @app_image_type = AppImageType.find(session[:app_image_type_id])
  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @app_image_setting}
    end
  end

  def edit
    @app_image_setting = DeviceAppImageSize.find(params[:id])
    @app_image_type = AppImageType.find(session[:app_image_type_id])
  end

  def create
    @app_image_setting = DeviceAppImageSize.where(app_image_type_id:params[:device_app_image_size][:app_image_type_id], device_type_id:params[:device_app_image_size][:device_type_id]).first_or_create
    @app_image_setting.update!(app_image_size_id:params[:device_app_image_size][:app_image_size_id])

    respond_to do |format|
        format.html { redirect_to device_app_image_sizes_path }
    end
  end

  def update
    @app_image_setting = DeviceAppImageSize.find(params[:id])

    respond_to do |format|
      if @app_image_setting.update!(device_app_image_size_params)
        format.html { redirect_to device_app_image_sizes_path, :notice => 'Setting was successfully updated.'}
        format.xml  { head :ok }
      end
    end
  end

  def destroy
    @app_image_setting = DeviceAppImageSize.find(params[:id])
    @app_image_setting.destroy

    respond_to do |format|
      format.html { redirect_to device_app_image_sizes_path }
      format.xml  { head :ok }
    end
  end
  
  private

  def device_app_image_size_params
    params.require(:device_app_image_size).permit(:device_type_id, :app_image_type_id, :app_image_size_id)
  end

end