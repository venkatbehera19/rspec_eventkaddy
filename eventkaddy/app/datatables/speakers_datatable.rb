class SpeakersDatatable
  delegate :params, :h, :link_to, :number_to_currency,:speaker_path,:edit_speaker_path, to: :@view

  def initialize(view,event_id,current_user)
    @view         = view
    @event_id     = event_id
    @current_user = current_user
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Speaker.where(event_id:@event_id).count,
      iTotalDisplayRecords: speakers.total_entries,
      aaData: data
    }
  end


private

  def data
   
    speakers.map do |speaker|
      dropdown_menu =
      "<a data-toggle='dropdown' style='cursor: pointer; font-size: 1.4rem; cursor: pointer;'> <i class='fa fa-ellipsis-v'></i> </a>" +
      "<div class='dropdown-menu'>" + 
        "#{link_to('Options', speaker_path(speaker),class:"btn text-info dropdown-item")}" +
        "#{link_to('Edit', edit_speaker_path(speaker),class:"btn text-success dropdown-item")}" +
        "#{link_to('Delete', speaker_path(speaker), :confirm => 'Are you sure?', :method => :delete ,class:"btn text-danger dropdown-item")}" +
      "</div>"
      table_actions = 
      "<div class='table-actions'>" +
        "<div class='btn-group d-flex'>" +
          "#{link_to('Options', speaker_path(speaker),class:"btn btn-outline-info")}" +
          "#{link_to('Edit', edit_speaker_path(speaker),class:"btn btn-outline-success")}" +
          "#{link_to('Delete', speaker_path(speaker), :confirm => 'Are you sure?', :method => :delete ,class:"btn btn-outline-danger")}" +
        "</div>" +
        "<div class='dropdown'>" +
          dropdown_menu
        "</div>"+ 
      "</div>"

      speaker_photo = speaker.event_file_photo ? "<img src='#{ReturnAWSUrl.new(@event_id, speaker.event_file_photo.path).call['url']}' alt='speaker pic' class='table-dp' />" : 
      "<img src='/defaults/profile_default.png' alt='speaker pic' class='table-dp' />"

      [
        speaker_photo.html_safe,
        speaker.honor_prefix,
        speaker.first_name,
        speaker.last_name,
        speaker.honor_suffix,
        speaker.email,
        speaker.company,
        table_actions.html_safe
      ]
    end
  end


  def speakers
    @speakers ||= fetch_speakers
  end

  def fetch_speakers

    if @current_user.role?(:track_owner)
      speakers = @current_user.trackowner.speakers.select('DISTINCT speakers.*').where("speakers.event_id= ?",@event_id).order("#{sort_column} #{sort_direction}")
    else
    #sessions = Session.order("#{sort_column} #{sort_direction}") #demo select all from example
    speakers = Speaker.select('DISTINCT speakers.*').where("speakers.event_id= ?",@event_id).order("#{sort_column} #{sort_direction}")
    end
    speakers = speakers.page(page).per_page(per_page)
    if params[:sSearch].present?
      speakers = speakers.where("speaker_code like :search or last_name like :search or first_name like :search or email like :search", search: "%#{params[:sSearch]}%")
    end
    speakers
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[speaker_code honor_prefix first_name last_name email]
    #columns = %w[session_code title]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end