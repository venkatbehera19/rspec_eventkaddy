class AddSessionCodeToSessionsAttendees < ActiveRecord::Migration[4.2]
  def change
      add_column :sessions_attendees, :session_code, :string
  end
end
