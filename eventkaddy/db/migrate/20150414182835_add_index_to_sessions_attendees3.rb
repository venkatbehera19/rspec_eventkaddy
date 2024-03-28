class AddIndexToSessionsAttendees3 < ActiveRecord::Migration[4.2]
  def change
  	def change
  		add_index :sessions_attendees, :session_id
  	end
  end
end
