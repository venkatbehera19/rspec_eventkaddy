class AddUserIdToAttendee < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :user_id, :integer
  end
end
