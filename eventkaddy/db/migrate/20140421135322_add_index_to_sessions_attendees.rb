class AddIndexToSessionsAttendees < ActiveRecord::Migration[4.2]
  def change
  	add_index :sessions_attendees, :attendee_id
  end
end
