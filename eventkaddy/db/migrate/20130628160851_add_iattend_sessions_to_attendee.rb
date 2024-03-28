class AddIattendSessionsToAttendee < ActiveRecord::Migration[4.2]
  def change
  	add_column :attendees, :iattend_sessions, :text
  end
end
