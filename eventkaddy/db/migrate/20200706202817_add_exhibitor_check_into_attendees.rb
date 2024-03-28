class AddExhibitorCheckIntoAttendees < ActiveRecord::Migration[4.2]
  def change
	add_column :attendees, :exhibitor_checkin, :text
  end

end
