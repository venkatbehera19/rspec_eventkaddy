class AddIndexToSessionsAttendees2 < ActiveRecord::Migration[4.2]
  def change
    add_index :sessions_attendees, :session_code
  end
end
