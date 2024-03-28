class AddConfirmedAtToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :confirmed_at, :datetime
  end
end
