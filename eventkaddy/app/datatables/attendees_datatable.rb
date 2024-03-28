class AttendeesDatatable
  delegate :params, :h, :link_to, :number_to_currency,:attendee_path,:edit_attendee_path, to: :@view

  def initialize(view,event_id)
    @view = view
    @event_id = event_id
    @settings = Setting.return_cms_settings event_id
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Attendee.where(event_id:@event_id).count,
      iTotalDisplayRecords: attendees.total_entries,
      aaData: data
    }
  end

 
private

  def data
    attendees.map do |attendee|  

      dropdown_menu =
      "<a data-toggle='dropdown' class='ellipse-style'> <i class='fa fa-ellipsis-v'></i> </a>" +
      "<div class='dropdown-menu'>" + 
        "#{link_to('Options', attendee_path(attendee),class:"btn text-info dropdown-item")}" +
        "#{link_to('Edit', edit_attendee_path(attendee),class:"btn text-success dropdown-item")}" +
        "#{link_to('Delete', attendee_path(attendee), :confirm => 'Are you sure?', :method => :delete ,class:"btn text-danger dropdown-item")}" +
      "</div>"
      table_actions = 
      "<div class='table-actions'>" + 
        "<div class='btn-group d-flex'>" +
          "#{link_to('Options', attendee_path(attendee),class:"btn btn-outline-info")}" +
          "#{link_to('Edit', edit_attendee_path(attendee),class:"btn btn-outline-success")}" +
          "#{link_to('Delete', attendee_path(attendee), data: {:confirm => 'Are you sure?'}, :method => :delete ,class:"btn btn-outline-danger")}" +
        "</div>" +
        "<div class='dropdown'>" +
          dropdown_menu +
        "</div>"
      "</div>"
      
      attendee_photo = attendee.event_file_photo ? "<img src='#{attendee.event_file_photo.path}' alt='speaker pic' class='table-dp' />" : 
      "<img src='/defaults/profile_default.png' alt='speaker pic' class='table-dp' />"

      attendee_email = "<div style='max-width: 9.8rem; word-wrap: break-word; white-space: normal;'>" +
        (attendee.email ? attendee.email : "") +
      "</div>"

      row = []
      row << attendee_photo.html_safe unless @settings.method("hide_attendee_table_attendee_photo").call
      row << attendee.first_name unless @settings.method("hide_attendee_table_attendee_first_name").call
      row << attendee.last_name unless @settings.method("hide_attendee_table_attendee_last_name").call
      row << attendee.business_unit unless @settings.method("hide_attendee_table_attendee_business_unit").call
      row << attendee.title unless @settings.method("hide_attendee_table_attendee_title").call
      row << attendee.company unless @settings.method("hide_attendee_table_attendee_company").call
      row << attendee_email.html_safe unless @settings.method("hide_attendee_table_attendee_email").call
      row << attendee.account_code unless @settings.method("hide_attendee_table_attendee_registration_id").call
      row << table_actions.html_safe

      row

      # [
      #   attendee_photo.html_safe,
      #   attendee.first_name,
      #   attendee.last_name,
      #   attendee.business_unit,
      #   attendee.title,
      #   attendee.company,
      #   attendee.email,
      #   attendee.account_code,
      #   table_actions.html_safe
      # ]
    end
  end


  def attendees
    @attendees ||= fetch_attendees
  end

  def fetch_attendees
    #sessions = Session.order("#{sort_column} #{sort_direction}") #demo select all from example
    # NOTE: This interpolated order is okay because it is not derived from a user; it is a little
    # tricky to write this with sanitization, so just be careful if you ever took it from a user
    attendees = Attendee.select('DISTINCT attendees.*').where("attendees.event_id= ?",@event_id).order("#{sort_column} #{sort_direction}")
    attendees = attendees.page(page).per_page(per_page)
    if params[:sSearch].present?
      attendees = attendees.where("first_name like :search or last_name like :search or business_unit like :search or title like :search or email like :search or account_code like :search", search: "%#{params[:sSearch]}%")
    end
    attendees
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[honor_prefix first_name last_name business_unit title email account_code]
    #columns = %w[session_code title]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
