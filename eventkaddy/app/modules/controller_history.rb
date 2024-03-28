# this module is to be mixed into controllers, adding a method
# called track_history which takes symbols with the same method as
# controller actions you wish to make history entries of.

module ControllerHistory

  def track_history type_name, *actions
    action_history_type = ActionHistoryType.where(name:type_name).first ||
                            ActionHistoryType.where(name:"Other").first
    # before_action is rails 3 version of rails 5 before_action
    before_action only: actions do
      ActionHistory.create(
        event_id:               session[:event_id],
        action_history_type_id: action_history_type.id,
        user_id:                current_user.id,
        ip_address:             current_user.current_sign_in_ip,
        email:                  current_user.email,
        action:                 "#{ controller_name }##{ action_name }"
        # parameters:             params.inspect.force_encoding("ISO-8859-1")
      )
    end
  end
  
end
