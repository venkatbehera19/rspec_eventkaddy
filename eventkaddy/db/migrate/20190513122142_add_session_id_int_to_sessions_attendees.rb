class AddSessionIdIntToSessionsAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions_attendees, :session_id_int, :integer, :after => :session_id, index: true
    # this won't work unless I delete session_ids which have alphabetical
    # cahracters in them; not impossible but also not really the job of a
    # migration
    # SessionsAttendee.update_all("session_id_int=session_id")
  end
end
