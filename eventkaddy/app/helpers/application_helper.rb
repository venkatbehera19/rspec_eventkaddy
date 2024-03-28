module ApplicationHelper

	def javascript(*files)
  		content_for(:head) { javascript_include_tag(*files) }
	end

  def admin_bubble(string)
    if current_user.role? :super_admin
      s = "<p class='alert alert-warning'><a href='#' class='close' data-dismiss='alert' aria-label='close'>&times;</a><b>Visible to admins only:</b><br><br>" + string + '</p>'
      s.html_safe
    end
  end

  def event_setting
    EventSetting.where(event_id:session[:event_id]).first_or_create
  end

  def tweleve_hour_format(time)
    time.strftime("%I:%M %p")
  end

  def admin_only
    if current_user.role? :super_admin
      yield
    end
  end

  def twenty_four_hour_format(time)
    time.strftime("%H:%M ")
  end

  def primary_db
    Rails.configuration.database_configuration[Rails.env]["database"]
  end

  def reporting_db
    reporting_path = Rails.root.join('config','reporting_database.yml')
    raise "reporting database configuration not found." unless File.exist? reporting_path
    return Mysql2::Client.new( YAML::load(File.open(reporting_path))[Rails.env] )
  end

end