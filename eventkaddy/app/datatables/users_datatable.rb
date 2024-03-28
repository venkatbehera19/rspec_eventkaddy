class UsersDatatable
  delegate :params, :h, :link_to,:user_path,:edit_user_path, to: :@view

  def initialize(view,current_ability, current_user)
    @view            = view
    @current_ability = current_ability
    @current_user    = current_user
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: User.accessible_by(@current_ability, :index).count,
      iTotalDisplayRecords: users.total_entries,
      aaData: data
    }
  end


private

  def data
    users.map do |user|
      events = []
      user.users_events.each { |user_event| events << { event: user_event.event.name, roles: user_event.roles.pluck(:name) } } unless user.roles_string.include? 'SuperAdmin'
      event_result = convert_event(events)
      events = event_result.join('<br>')
      if(user.deactivated)
        col2 =  link_to('Reactivate', "/users/reactivate/#{user.id}", data: { confirm: 'Are you sure you want to re-activate this user account?' }, :method => :get ,class:"btn btn-outline-info text-info dropdown-item")
        col2_btn =  link_to('Reactivate', "/users/reactivate/#{user.id}", data: { confirm: 'Are you sure you want to re-activate this user account?' }, :method => :get ,class:"btn btn-outline-info")
      else
        col2 =  link_to("Deactivate", "/users/deactivate/#{user.id}", data: { confirm: 'Are you sure you want to deactivate this user account?' }, :method => :get, class: "btn btn-outline-warning text-warning dropdown-item")
        col2_btn =  link_to("Deactivate", "/users/deactivate/#{user.id}", data: { confirm: 'Are you sure you want to deactivate this user account?' }, :method => :get, class: "btn btn-outline-warning")
      end
      dropdown_menu = "<div class='dropdown'><a data-toggle='dropdown' class='ellipse-style'><i class='fa fa-ellipsis-v'></i></a>" +
        "<div class='dropdown-menu'>" +
        "#{link_to('Edit', edit_user_path(user),class:"btn btn-outline-success text-success dropdown-item")}" +
        "#{col2}" +
        "#{link_to('Delete', user_path(user), :confirm => 'Are you sure?', :method => :delete ,class:"btn btn-outline-danger text-danger dropdown-item")}" +
        "#{@current_user.role?('SuperAdmin') ? link_to('Impersonate', "/users/#{user.id}/impersonate", method: :post, class: "btn btn-outline-secondary text-secondary dropdown-item") : ""}" +
        "</div>" +
      "</div>"

      table_actions = "<div class='table-actions'>" + 
        dropdown_menu +
        "<div class='btn-group d-flex'>" +
          "#{link_to('Show', "/users/#{user.id}/show_user_event_role",class:"btn btn-outline-info")}" +
          "#{link_to('Edit', edit_user_path(user),class:"btn btn-outline-success")}" +
          col2_btn +
          "#{link_to('Delete', user_path(user), :confirm => 'Are you sure?', :method => :delete ,class:"btn btn-outline-danger")}" +
          "#{@current_user.role?('SuperAdmin') ? link_to('Impersonate', "/users/#{user.id}/impersonate", method: :post, class: "btn btn-outline-secondary") : ""}" +
        "</div>" +
      "</div>"
      [
        user.email,
        user.roles_string,
        events,
        table_actions.html_safe
      ]
    end
  end

  def convert_event events
    e = []
    events.each do |event|
      str = ""
      str += event[:event]
      event[:roles].each do |role|
        str += "(#{role})"
      end
      e << str
    end
    e
  end

  def users
    @users ||= fetch_users
  end

  def fetch_users
    users = User.accessible_by(@current_ability, :index).
      select('users.id, email, GROUP_CONCAT(NULLIF(roles.name, " ") separator ", ") AS roles_string, deactivated').
      joins('JOIN users_roles ON users_roles.user_id=users.id').
      joins('JOIN roles ON roles.id=users_roles.role_id').
      group("users.id").order("#{sort_column} #{sort_direction}")

      # GROUP_CONCAT(NULLIF(events.name, " ") separator ", ") AS events_string
      # joins('JOIN users_events ON users_events.user_id=users.id').
      # joins('JOIN events ON events.id=users_events.event_id').

    users = users.page(page).per_page(per_page)
    if params[:sSearch].present?
      users = users.where("email like :search or roles.name like :search", search: "%#{params[:sSearch]}%")
    end
    users
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[email roles_string event]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end