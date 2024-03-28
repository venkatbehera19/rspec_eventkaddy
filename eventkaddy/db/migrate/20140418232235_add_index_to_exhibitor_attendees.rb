class AddIndexToExhibitorAttendees < ActiveRecord::Migration[4.2]
  def change
  	add_index :exhibitor_attendees, :attendee_id
  end
end
