class ExhibitorPortalGlobalConfigsController < ApplicationController
  layout 'subevent_2013'

  def index
    @event                          = Event.find session[:event_id]
    @exhibitor_portal_global_configs= ExhibitorPortalGlobalConfig.where(event_id:session[:event_id])
    @exhibitor_portal_global_config = ExhibitorPortalGlobalConfig.new
    @exhibitor                      = Exhibitor.where(is_demo: true, event_id: session[:event_id]).first_or_create
    @exhibitor_staff                = ExhibitorStaff.where(exhibitor_id: @exhibitor.id, event_id:session[:event_id], is_exhibitor:true).first_or_create
    exhibitor_portal_settings       = Setting.return_exhibitor_portal_settings(session[:event_id])
    @default                        = exhibitor_portal_settings.default_portal_config.blank? ? -1 : exhibitor_portal_settings.default_portal_config.to_i
  end

  def new
    @exhibitor_portal_global_config = ExhibitorPortalGlobalConfig.new
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @exhibitor_portal_global_config = ExhibitorPortalGlobalConfig.new(config_params)
    type = SettingType.where(name:'exhibitor_enhanced_portal_configs').first
    setting = Setting.create(event_id:session[:event_id], setting_type_id: type.id)
    @exhibitor_portal_global_config.setting_id = setting.id
    respond_to do |format|
      if @exhibitor_portal_global_config.save
        format.html { redirect_to('/exhibitor_portal_global_configs', :notice => 'Config was successfully created.') }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @exhibitor_portal_global_config.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @exhibitor_portal_global_config = ExhibitorPortalGlobalConfig.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @exhibitor_portal_global_config = ExhibitorPortalGlobalConfig.find(params[:id])
    @exhibitor_portal_global_config.assign_attributes(update_params)
    if @exhibitor_portal_global_config.save
      redirect_to('/exhibitor_portal_global_configs', :notice => 'Config was successfully updated.') 
    else
      redirect_to('/exhibitor_portal_global_configs', :notice => 'Something went wrong.')
    end
  end 

  def destroy
    @exhibitor_portal_global_config = ExhibitorPortalGlobalConfig.find(params[:id])
    if @exhibitor_portal_global_config && @exhibitor_portal_global_config.setting_id
      setting = Setting.find  @exhibitor_portal_global_config.setting_id
      setting.destroy
    end
    @exhibitor_portal_global_config.destroy
    redirect_to('/exhibitor_portal_global_configs', :notice => 'Config was successfully deleted.') 
  end

  private
  def config_params
    params.require(:exhibitor_portal_global_config).permit(:name, :default).merge(event_id: session[:event_id], setting_id: nil)
  end

  def update_params
    params.require(:exhibitor_portal_global_config).permit(:name, :default)
  end

end
