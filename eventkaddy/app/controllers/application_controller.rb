class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ExceptionHandler
  impersonates :user
  before_action :make_action_mailer_use_request_host_and_protocol
  before_action :configure_permitted_parameters, if: :devise_controller?
  # This filter is a workaround for CanCan error in rails 4 upgrade
  before_action do
    resource = controller_name.singularize.to_sym
    method = "#{resource}_params"
    params[resource] &&= send(method) if respond_to?(method, true)
  end
	helper_method :is_i

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end
  
  def event_id
    session[:event_id]
  end

  def primary_db
    Rails.configuration.database_configuration[Rails.env]["database"]
  end

  def reporting_db
    reporting_path = Rails.root.join('config','reporting_database.yml')
    raise "reporting database configuration not found." unless File.exist? reporting_path
    return Mysql2::Client.new( YAML::load(File.open(reporting_path))[Rails.env] )
  end
  
  def where args
    if self.class.method_defined? :model
      model.where args
    else
      raise "Tried to use Controller#where in controller where model is not defined."
    end
  end

  def for_event
    where( event_id: event_id )
  end


  def is_i(value)
     !!(value =~ /\A[-+]?[0-9]+\z/)
  end

  def set_ga_key(type = '')
    if type == 'simple_registration'
      @ga_key = Setting.return_simple_registration_settings(params[:event_id]).ga_key
    elsif type == 'attendee_badge_print'
      @ga_key = Setting.return_attendee_badge_settings(params[:event_id]).ga_key
    else
      @ga_key = Setting.return_registration_portal_settings(params[:event_id]).ga_key
    end
  end
  
  def ensure_directory_exists(dirname)
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  end

  def event_belongs_to_user?(event_id)
    event_ids = current_user.events.pluck(:id)
    unless event_ids.include?(event_id.to_i)
      render :text => "<center><h2>Invalid event accessed.</h2></center>"
    end
  end

## DIY Client Portal stuff
##
  def setDiyLayoutVariables
    if current_user.role?(:diyclient) && session[:event_id]
    	puts "diy #{session[:event_id]}" #this is getting called twice for some reason in session/index, need to figure out
			@event               = Event.find(session[:event_id].to_i)
			@content_enabled     = diyContentEnabled(@event.id)#returns [isenabled?,first_feature_name]
			@menu_link           = "content"
			@mobile_web_settings = getDiyMobileWebSettings(@event.id)
    end
  end

  def diyContentEnabled(event_id)
    types = MobileWebSettingType.where("name like ?", "%feature_%").pluck(:id)

    if MobileWebSetting.where(event_id:event_id,enabled:true,type_id:types).length > 0
      types            = MobileWebSettingType.where("name like ?", "%feature_%").pluck(:id)
      enabled_settings = MobileWebSetting.where(event_id:event_id,enabled:true,type_id:types)
      if enabled_settings.length > 0
        return [true,enabled_settings.first.mobile_web_setting_type.name.sub(/^feature_/, ''),enabled_settings.first.id]
      end
    else
      return [false]
    end
  end

	def getDiyMobileWebSettings(event_id)#for layouts/diy_features tab generation
    types = MobileWebSettingType.where("name like ?", "%feature_%").pluck(:id)
    return MobileWebSetting.where(event_id:event_id,enabled:true,type_id:types)
  end
  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:username,:otp_attempt])
  end

  private

  def make_action_mailer_use_request_host_and_protocol
    ActionMailer::Base.default_url_options[:protocol] = request.protocol
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end

end
