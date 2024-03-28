module Menus

  def self.cms_menu_items event_id
    result   = []
    settings = Setting.return_cms_settings event_id

    # TODO: this html here should be extracted, as this code needs to be shared between
    # mobile and non-mobile, and the styles are slightly diverged
    menu_header = ->(label, menu_header_name) {
      {header: true, content:"<div><b>#{label}</b></div>".html_safe} unless settings.method("hide_menu_#{menu_header_name}").call
    } 

    menu_link = ->(label, url, menu_item_name, show=false) {
      show_or_hide = show ? 'show' : 'hide'
      unless show
        {link: true, content:"<div style='margin-left:5px;'><a href='#{url}'>#{label}</a></div>".html_safe} unless settings.method("#{show_or_hide}_menu_#{menu_item_name}").call
      else
        {link: true, content:"<div style='margin-left:5px;'><a href='#{url}'>#{label}</a></div>".html_safe} if settings.method("#{show_or_hide}_menu_#{menu_item_name}").call
      end
    }

    result << menu_header["Session", "registrations_header"] 
    result << menu_link["Sessions", "/sessions", "sessions"] 
    result << menu_link["Speakers", "/speakers", "speakers"] 
    result << menu_link["Rooms", "/location_mappings/rooms", "rooms"] 
    result << menu_link["Session Files", "/session_files/summary?type=conference note", "conference_notes"] 
    result << menu_link["Attendees", "/attendees", "attendees"] 
    result << menu_link["Education Managers", "/trackowners", "education_managers"] 
    result << menu_link["Feedback Summary", "/feedbacks/results.xlsx", "feedback_summary"] 

    result << menu_header["Exhibitor", "maps_rooms_header"] 
    result << menu_link["Exhibitors", "/exhibitors", "exhibitors"] 
    result << menu_link["Booths", "/location_mappings/booths", "booths"] 

    result << menu_header["Settings", "settings_header"]
    result << menu_link["General", "/event_settings/edit_general_portal_settings", "general_portal_settings"]
    result << menu_link["Event", "/event_settings/edit_restricted_event_settings", "event_settings"]
    result << menu_link["Speaker Portal", "/settings/speaker_portal", "speaker_portal_settings"]
    result << menu_link["Speaker PDFs", "/speaker_portals/index_pdf", "speaker_pdfs"] 
    result << menu_link["Exhibitor Portal", "settings/exhibitor_portal", "exhibitor_portal_settings"]
    result << menu_link["Mobile App", "/settings/cordova", "mobile_app_booleans"]
    result << menu_link["Q&A Page", "/settings/qna", "qna_page_settings"]
    result << menu_link["Guest View", "/settings/guest_view", "guest_view_settings"]
    result << menu_header["Video Portal", "video_portal_header"]
    result << menu_link["Video Portal Booleans", "/settings/video_portal", "video_portal_booleans"]
    result << menu_link["Video Portal Headings", "/settings/video_portal_headings", "video_portal_headings"]
    result << menu_link["Video Portal Contents", "/settings/video_portal_contents", "video_portal_contents"]
    result << menu_link["Video Portal Styles", "/settings/video_portal_styles", "video_portal_styles"]
    result << menu_link["Video Portal Images", "/settings/video_portal_images", "video_portal_images"]
    result << menu_link["Simple Registration", "/settings/simple_registration_settings", "simple_registration_settings"]
    result << menu_link["Regular Registration", "/settings/registration_portal_settings", "registration_portal_settings"]
    result << menu_link["Regular Registration", "/settings/exhibitor_registration_portal_settings", "exhibitor_registration_portal_settings"] 

    result << menu_header["Program Feed", "program_feed_header"]
    result << menu_link["Program Feed Booleans", "/settings/program_feed_booleans", "program_feed_booleans"]
    result << menu_link["Program Feed Headings", "/settings/program_feed_headings", "program_feed_headings"]
    result << menu_link["Program Feed Styles", "/settings/program_feed_styles", "program_feed_styles"]

    result << menu_header["Config", "reports_header"]
    # Replacement for Video Portal Settings Page, now combines all settings 
    # result << menu_link["Settings", "/settings", "settings"]
    #  menu_link["Video Portal Settings", "/settings", "video_portal_settings"] %1> 
    # Old portal settings page, should not be combined with new generic settings page which encompasses all settings users can toggle 
    result << menu_link["Portal Settings", "/event_settings/edit_event_settings", "portal_settings"] 
    result << menu_link["Mobile and App Settings", "/event_settings/edit_mobile_settings", "mobile_and_app_settings"] 
    result << menu_link["App Game", "/app_games", "app_game"] 
    result << menu_link["Surveys", "/surveys", "surveys"] 
    result << menu_link["Scavenger Hunts", "/scavenger_hunts", "scavenger_hunts"] 
    result << menu_link["Import/Export", "/events/configure/#{event_id}", "import_export"] 
    result << menu_link["Home Screen Icons (App)", "/home_buttons", "home_screen_icons_app"] 
    result << menu_link["Home Screen Icons (Mobile)", "/home_button_groups", "home_screen_icons_mobile"] 
    result << menu_link["Banners", "/app_images/select_type", "banners"] 
    result << menu_link["Event Maps", "/event_maps", "event_maps"] 
    result << menu_link["Notifications", "/notifications", "notifications"] 
    result << menu_link["Portal Messages", "/event_settings/show_messages", "portal_messages"]
    result << menu_link["App Message Threads", "/app_message_threads", "app_message_threads", true] 
    # remove nils created by menus that are hidden; not very elegant, but
    # based on the original implementation where erb would discard the nil for us
    result.compact
  end

  # based on some old code that was inline in the subevent layout, need
  # to be able to reuse an array on menu items for different purposes
  def self.events_menu_items user
    result = []
    last_start_year, last_start_month = false, false 
    (user.role?(:super_admin) ? events_for_admin(user) : events_for_user(user)).each do |e| 
      result << {
        id: e.id, 
        name: e.name,
        organization: e.organization ? e.organization.name : "",
        start_date: e.event_start_at,
        end_date: e.event_end_at,
        link: "/events/change_event/#{e.id}"
      }
      last_start_year = e.event_start_at.strftime("%Y") 
      last_start_month = e.event_start_at.strftime("%Y%B") 
    end
    result
  end
  def self.events_object user
    result = {}
    last_start_year, last_start_month = false, false 
    (user.role?(:super_admin) ? events_for_admin(user) : events_for_user(user)).each do |e| 
      # add year and month header
      if !last_start_year # more of a blank check for first iteration
        result[e.event_start_at.strftime("%Y") ]= {}
        result[e.event_start_at.strftime("%Y")][e.event_start_at.strftime("%B")] = []
      elsif e.event_start_at.strftime("%Y") != last_start_year # add year header
        result[e.event_start_at.strftime("%Y") ]= {}
      end

      # add month header
      if last_start_month && e.event_start_at.strftime("%Y%B") != last_start_month 
        result[e.event_start_at.strftime("%Y")][e.event_start_at.strftime("%B")] = []
      end 

      result[e.event_start_at.strftime("%Y")][e.event_start_at.strftime("%B")] << {
        event: true, content: e.name, link: "/events/change_event/#{e.id}"
      }
      last_start_year = e.event_start_at.strftime("%Y") 
      last_start_month = e.event_start_at.strftime("%Y%B") 
    end
    result
  end

  private

  def self.events_for_admin user
    raise "Must be admin." unless user.role? :super_admin
    Event.includes(:organization).
      #select("events.id, name, event_start_at, event_end_at").
      where('id NOT IN (SELECT event_id FROM hidden_events WHERE user_id=?)', user.id).
      order("event_start_at DESC")
  end

  def self.events_for_user user
    Event.includes(:organization).
      #select('events.id, name, event_start_at, event_end_at').
      joins('LEFT OUTER JOIN users_events ON users_events.event_id=events.id').
      where("users_events.user_id = ?",user.id).
      order('event_start_at DESC')
  end
end

