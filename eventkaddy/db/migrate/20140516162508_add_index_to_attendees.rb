class AddIndexToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_index :attendees, :account_code
  end
end
