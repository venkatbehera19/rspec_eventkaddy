class MobileWebSettingsController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource
  
  def index
    @mobile_web_settings
    respond_to do |format|
      format.html
      format.xml  { render :xml => @events }
    end
  end

  # private

  # def mobile_web_setting_params
  #   params.require(:mobile_web_setting).permit(:event_id, :type_id, :enabled, :content, :device_type_id, :position)
  # end

end