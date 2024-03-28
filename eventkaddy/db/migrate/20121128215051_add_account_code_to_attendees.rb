class AddAccountCodeToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :account_code, :string
  end
end
