class SessionsDatatable
  delegate :params, :h, :link_to, :number_to_currency,:event_session_path,:edit_event_session_path, to: :@view

  def initialize(view,event_id,current_user)
    @view         = view
    @event_id     = event_id
    @current_user = current_user
    @settings     = Setting.return_cms_settings event_id
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Session.where(event_id:@event_id).count,
      iTotalDisplayRecords: sessions.total_entries,
      aaData: data
    }
  end

  private

  def show_sold_out?
    !@settings.method("hide_session_form_sold_out").call
  end

  def show_is_poster?
    !@settings.method("hide_session_form_is_poster").call
  end

  def data
    sessions.map do |session|

      session_file_versions = SessionFileVersion.joins('
      LEFT JOIN session_files ON session_file_versions.session_file_id=session_files.id
      LEFT JOIN session_file_types ON session_file_types.id=session_files.session_file_type_id
      ').where('session_files.session_id=? AND session_file_types.name=?',session.id,'conference note')

      if (session.location_mapping!=nil) then
        location_mapping_name = session.location_mapping.name
      else
        location_mapping_name = nil
      end

      if (session.date!=nil && session.start_at!=nil && session.end_at!=nil) then
        if(@current_user.twelve_hour_format)
          session_date = "#{session.date} | #{session.start_at.strftime("%I:%M %p")} - #{session.end_at.strftime("%I:%M %p")}"
        else
          session_date = "#{session.date} | #{session.start_at.strftime('%H:%M')} - #{session.end_at.strftime('%H:%M')}"
        end
      else
        session_date = nil
      end
      # puts "Before error............................"
      dropdown_menu =
        "<a data-toggle='dropdown' style='cursor: pointer; font-size: 1.4rem; cursor: pointer;'> <i class='fa fa-ellipsis-v'></i> </a>" +
        "<div class='dropdown-menu'>" + 
          "#{link_to('Show', event_session_path(session),class:"btn text-info dropdown-item")}" +
          "#{link_to('Edit', edit_event_session_path(session),class:"btn text-warning dropdown-item")}" +
          "#{link_to('Delete', event_session_path(session), :confirm => 'Are you sure?', :method => :delete ,class:"btn text-danger dropdown-item")}" +
        "</div>"
      # puts dropdown_menu
      table_actions = 
        "<div class='table-actions'>" +
          "<div class='btn-group d-flex'>" +
            "#{link_to('Show', event_session_path(session),class:"btn btn-outline-info")}" + 
            "#{link_to('Edit', edit_event_session_path(session),class:"btn btn-outline-warning")}" +
            "#{link_to('Delete', event_session_path(session), :confirm => 'Are you sure?', :method => :delete ,class:"btn btn-outline-danger")}" +
          "</div>" +
          "<div class='dropdown'>" +
            dropdown_menu
          "</div>"+ 
        "</div>"
      row = [
        session.session_code,
        session.title,
        location_mapping_name,
        session_date,
        session_file_versions.length,
      ]

      if show_sold_out?
        row << ( session.sold_out ? "Yes" : "No")
      end

      if show_is_poster?
        row << ( session.is_poster ? "Yes" : "No")
      end

      row << table_actions.html_safe

      row
    end
  end


  def sessions
    @sessions ||= fetch_sessions
  end

  def fetch_sessions
    #sessions = Session.order("#{sort_column} #{sort_direction}") #demo select all from example
    if @current_user.role?(:track_owner)
      sessions = @current_user.trackowner.sessions.
        select("DISTINCT sessions.*,
               location_mappings.name AS location_mapping_name,
               CONCAT_WS(' ', DATE_FORMAT(sessions.date, '%Y-%m-%d'),' | ', DATE_FORMAT(sessions.start_at, '%H:%i'),' - ',DATE_FORMAT(sessions.end_at, '%H:%i')) AS session_date, tags.bloodline").
        joins('LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id').
        joins('LEFT OUTER JOIN tags_sessions ON tags_sessions.session_id=sessions.id').
        joins('LEFT OUTER JOIN tags ON tags.id=tags_sessions.tag_id').
        where("sessions.event_id= ?",@event_id).
        group("sessions.id").
        order("#{sort_column} #{sort_direction}")
    else
      # for bloodline, we don't need to group concat it seems. mysql is smart
      # enough to do the work for us on the WHERE query, and just give us the
      # result we want in the search
      sessions = Session.
        select("DISTINCT sessions.*,
               location_mappings.name AS location_mapping_name,
               CONCAT_WS(' ', DATE_FORMAT(sessions.date, '%Y-%m-%d'),' | ', DATE_FORMAT(sessions.start_at, '%H:%i'),' - ',DATE_FORMAT(sessions.end_at, '%H:%i')) AS session_date, tags.bloodline").
        joins('LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id').
        joins('LEFT OUTER JOIN tags_sessions ON tags_sessions.session_id=sessions.id').
        joins('LEFT OUTER JOIN tags ON tags.id=tags_sessions.tag_id').
        where("sessions.event_id= ?",@event_id).
        group("sessions.id").
        order("#{sort_column} #{sort_direction}")
    end
    sessions = sessions.page(page).per_page(per_page)
    if params[:sSearch].present?
      #unfortunately need to include the full concat query as session_date doesn't work
      sessions = sessions.where("session_code like :search or title like :search or bloodline like :search or location_mappings.name like :search or  CONCAT_WS(' ', DATE_FORMAT(sessions.date, '%Y-%m-%d'),' | ', DATE_FORMAT(sessions.start_at, '%H:%i'),' - ',DATE_FORMAT(sessions.end_at, '%H:%i')) like :search", search: "%#{params[:sSearch]}%")
    end
    sessions
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[session_code title location_mapping_name session_date]
    #columns = %w[session_code title]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
