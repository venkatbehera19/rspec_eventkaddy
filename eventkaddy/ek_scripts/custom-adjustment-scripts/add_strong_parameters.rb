###########################################
# Custom Adjustment Script
# to add exhibitor portal users based
# on exhibitor email
###########################################

require_relative '../settings.rb' #config

require 'active_record'

require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)

Dir.foreach(Rails.root.join('app', 'controllers')) do |filename|
  if filename == '.' or filename == '..'
  else
    excluded_controllers = ["application_controller.rb", "custom_adjustments_controller.rb", "api_controllers", "event_specific_controllers", "feature_controllers", "sessions_trackowners_controller.rb", "partner_portals_controller.rb", "video_visits_controller.rb", "exhibitor_portals_controller.rb", "speaker_portals_controller.rb", "moderator_portals_controller.rb", "trackowner_portals_controller.rb", "managers_controller.rb", "reports_controller.rb", "home_controller.rb", "chats_controller.rb", "guest_views_controller.rb", "chat_requests_controller.rb"]
    unless excluded_controllers.include? filename
      model_name = filename.gsub("s_controller.rb", "")
      puts model_name
      if model_name == "home_button_entrie"
        model_name = "home_button_entry"
      end
      model = model_name.camelize.constantize
      attributes = []
      model.column_names.each do |a|
        unless a == "created_at" || a == "updated_at" || a == "id"
          attributes << ":#{a}"
        end
      end
      attributes = attributes.join(", ")
      puts model_name
      puts model
      puts attributes

      open(Rails.root.join('app', 'controllers', filename), 'a') { |f|
        f << "\n"
        f << "  private\n"
        f << "\n"
        f << "  def #{model_name}_params\n"
        f << "    params.require(:#{model_name}).permit(#{attributes})\n" 
        f << "  end\n"
        f << "\n"
        f << "end"
      }
    end
  end
end