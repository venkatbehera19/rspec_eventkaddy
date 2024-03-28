class UserEventRolesController < ApplicationController
  before_action :get_user
  load_and_authorize_resource

  def update
    users_event = UsersEvent.find params[:user_event_id]
    users_event.user_event_roles.delete_all 
    if params[:data].present?
      params[:data].each do |role|
        UserEventRole.find_or_create_by(role_id: role[:id], users_event_id: users_event.id)
        UsersRole.find_or_create_by(user_id: users_event.user_id, role_id: role[:id])
      end
    end
    update_role users_event.user_id
  end

  private
  def get_user
    @current_user = current_user
  end

  def update_role user_id 
    user = User.find user_id
    user.roles.delete_all
    users_events = UsersEvent.where(user_id: user_id)
    users_events.each do |users_event|
      users_event.user_event_roles.each do |event_role|
        UsersRole.find_or_create_by(user_id: user.id, role_id: event_role.role_id)
      end
    end
  end
end