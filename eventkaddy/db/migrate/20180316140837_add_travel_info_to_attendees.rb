class AddTravelInfoToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :travel_info, :text
  end
end
