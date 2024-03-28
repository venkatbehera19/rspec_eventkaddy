class SessionFilesDatatable
  delegate :params, :h, :link_to, :number_to_currency,:session_file_path,:edit_session_file_path, to: :@view

  attr_accessor :event_id, :view, :current_user, :session_file_type_id

  def initialize(view, event_id, current_user, session_file_type_id)
    @view                 = view
    @event_id             = event_id
    @current_user         = current_user
    @session_file_type_id = session_file_type_id
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: SessionFile.where(event_id:event_id).count,
      iTotalDisplayRecords: session_files.total_entries,
      aaData: data
    }
  end


private

  def data
    session_files.map do |session_file|

      if session_file.session_file_versions.length > 0 && session_file.session_file_versions.order('updated_at DESC').first.event_file!=nil 
        @downlink = link_to(
          "Download",
          session_file.session_file_versions.order('created_at DESC').first.event_file.path,
          class:"btn"
        )
      else
        @downlink = "No File Available"
      end

      if session_file.session.speakers.length == 1 
        spk = session_file.session.speakers.first
        @name = link_to(
          "#{spk.honor_prefix} #{spk.first_name} #{spk.last_name} #{spk.honor_suffix}",
          "/speakers/#{spk.id}"
        )
        @email = "<a href='mailto:#{spk.email}'>#{spk.email}</a>"
      elsif session_file.session.speakers.length > 1 
        @name = "<a href='/sessions/#{session_file.session_id}/session_speakers'>Multiple Speakers</a>"
        @email = ""
      end
      table_actions = '<div class="table-actions">' + 
        '<div class="btn-group d-flex">' +
          "#{link_to('Edit', edit_session_file_path(session_file),class:"btn btn-outline-success")}" +
          "#{link_to('Delete', session_file_path(session_file), data: {:confirm => 'Are you sure?'}, :method => :delete ,class:"btn btn-outline-danger")}" +
        '</div>' +
        '<div class="dropdown">' +
          '<a data-toggle="dropdown" class="ellipse-style"> <i class="fa fa-ellipsis-v"></i> </a>' +
          '<div class="dropdown-menu">' +
            "#{link_to('Edit', edit_session_file_path(session_file),class:"btn text-success dropdown-item")}" +
            "#{link_to('Delete', session_file_path(session_file), data: {:confirm => 'Are you sure?'}, :method => :delete ,class:"btn text-danger dropdown-item")}" +
          '</div>' +
        '</div>' +
      '</div>'
      if current_user.role?(:track_owner) || current_user.role?(:client) || current_user.role?(:super_admin) 

        [
          session_file.session.session_code,
          session_file.session.title,
          @name,
          @email,
          session_file.session_file_versions.length,
          @downlink.html_safe,
          table_actions.html_safe
        ]
      else
        [
          session_file.session_code,
          session_file.session_title,
          @name,
          @email,
          session_file.session_file_versions.length,
          @downlink.html_safe
        ]
      end
    end #session_files.map
  end


  def session_files
    @session_files ||= fetch_session_files
  end

  def fetch_session_files
    if current_user.role?(:track_owner)

      session_files = current_user
        .trackowner
        .session_files
        .where(
          event_id:             event_id,
          session_file_type_id: session_file_type_id
        )
        .where("sessions.credit_hours > ?", 0)
        .order("#{sort_column} #{sort_direction}")
    else

      session_files = SessionFile
        .select('
          session_files.*,
          sessions.session_code,
          sessions.title AS session_title
        ')
        .joins('JOIN sessions ON sessions.id=session_files.session_id')
        .where(
          event_id:             event_id,
          session_file_type_id: session_file_type_id
        )
        .order("#{sort_column} #{sort_direction}")
    end
    session_files = session_files.page(page).per_page(per_page)

      #backbone data
      speakers = Speaker
        .select('first_name,last_name,honor_prefix,honor_suffix,email,sessions.id AS session_id, speakers.id AS speaker_id')
        .joins('JOIN sessions_speakers ON speakers.id=sessions_speakers.speaker_id JOIN sessions ON sessions_speakers.session_id=sessions.id')
        .where("speakers.event_id= ?", event_id)
        .order("#{sort_column} #{sort_direction}")

      speakers = speakers.page(page).per_page(per_page)

    if params[:sSearch].present?
      session_files = session_files
        .where(
          "sessions.title like :search or sessions.session_code like :search",
          search: "%#{params[:sSearch]}%"
        )
    end
    session_files
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[session_code title last_name email]
    #columns = %w[session_code title]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
