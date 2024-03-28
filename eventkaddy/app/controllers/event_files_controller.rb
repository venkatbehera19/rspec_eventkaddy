class EventFilesController < ApplicationController

  def show_banner
    @banner=EventFile.find(params[:id])
    respond_to do |format|
      format.html {render :layout => 'subevent_2013'}
      format.xml  { render :xml => @event_file }
    end

  end

  def new_banner
    @event_file=EventFile.new
    @event_file_types=EventFileType.where(name:["tablet_banner_ad","phone_banner_ad"])

    respond_to do |format|
      format.html {render :layout => 'subevent_2013'}
      format.xml  { render :xml => @event_file }
    end

  end

  def create_banner

    @event_file=EventFile.new(event_file_params)
    @event_file_type_id=params[:event_file][:event_file_type_id]
    @event_id=session[:event_id]
    @event_file.addBanner(params,@event_id,@event_file_type_id)

    respond_to do |format|
      if @event_file.save
        format.html { redirect_to("/event_settings/edit_banners", :notice => 'Banner was successfully created.') }
        format.xml  { render :xml => @event_file, :status => :created, :location => @event_file }
      else
        format.html { redirect_to("/event_files/new_banner/", :alert => "Banner could not be created.") }
        format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
      end
    end

  end

  def edit_banner
    @event_file=EventFile.find(params[:id])
    @event_file_types=EventFileType.where(name:["tablet_banner_ad","phone_banner_ad"])

    respond_to do |format|
      format.html {render :layout => 'subevent_2013'}
      format.xml  { render :xml => @event_file }
    end
  end

  def update_banner
    @event_file=EventFile.find(params[:id])
    @event_file_type_id=params[:event_file][:event_file_type_id]
    @event_id=session[:event_id]
    @event_file.addBanner(params,@event_id,@event_file_type_id)

    respond_to do |format|
      if @event_file.update!(event_file_params)
        format.html { redirect_to("/event_settings/edit_banners", :notice => 'Banner was successfully created.') }
        format.xml  { render :xml => @event_file, :status => :created, :location => @event_file }
      else
        format.html { redirect_to("/event_files/edit_banner/", :alert => "Banner could not be updated.") }
        format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /event_files/1
  # DELETE /event_files/1.xml
  def delete_banner
    @event_file = EventFile.find(params[:id])
    @event_file.destroy

    respond_to do |format|
      format.html { redirect_to("/event_settings/edit_banners") }
      format.xml  { head :ok }
    end
  end

  # GET /event_files
  # GET /event_files.xml
  def index
    @event_files = EventFile.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @event_files }
    end
  end

  # GET /event_files/1
  # GET /event_files/1.xml
  def show
    @event_file = EventFile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event_file }
    end
  end

  # GET /event_files/new
  # GET /event_files/new.xml
  def new
    @event_file = EventFile.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event_file }
    end
  end

  # GET /event_files/1/edit
  def edit
    @event_file = EventFile.find(params[:id])
  end

  # POST /event_files
  # POST /event_files.xml
  def create
    @event_file = EventFile.new(event_file_params)

    respond_to do |format|
      if @event_file.save
        format.html { redirect_to(@event_file, :notice => 'Event file was successfully created.') }
        format.xml  { render :xml => @event_file, :status => :created, :location => @event_file }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /event_files/1
  # PUT /event_files/1.xml
  def update
    @event_file = EventFile.find(params[:id])

    respond_to do |format|
      if @event_file.update!(event_file_params)
        format.html { redirect_to(@event_file, :notice => 'Event file was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /event_files/1
  # DELETE /event_files/1.xml
  def destroy
    @event_file = EventFile.find(params[:id])
    event_file_type = EventFileType.find @event_file.event_file_type_id
    if event_file_type.name == 'email_template_image'
      # Soft Delete
      @event_file.mark_deleted
    else
      @event_file.destroy
    end
    if params[:registration_banner_event_file_id]
      @event_setting = EventSetting.where(event_id: session[:event_id]).first
      @event_setting.update(registration_banner_event_file_id: nil)
      redirect_to "/settings/registration_portal_settings", :notice => "Portal Image removed successfully."
    elsif params[:registration_header_event_file_id]
      # @event_setting = EventSetting.where(event_id: session[:event_id]).first
      @registration_portal_settings = Setting.return_registration_portal_settings(session[:event_id])
      @registration_portal_settings.reg_header_bg_img = nil
      @registration_portal_settings.save
      redirect_to "/settings/registration_portal_settings", :notice => "Portal Image removed successfully."
      # binding.pry
    elsif params[:registration_content_event_file_id]
      # @event_setting = EventSetting.where(event_id: session[:event_id]).first
      @registration_portal_settings = Setting.return_registration_portal_settings(session[:event_id])
      @registration_portal_settings.reg_header_content = nil
      @registration_portal_settings.save
      redirect_to "/settings/registration_portal_settings", :notice => "Portal Image removed successfully."
      # binding.pry
    else
      respond_to do |format|
        format.js {render inline: "location.reload();" } #reloads the the page after delete
        format.xml  { head :ok }
      end
    end
  end

  private

  def event_file_params
    params.require(:event_file).permit(:event_id, :name, :size, :mime_type, :path, :event_file_type_id)
  end

end