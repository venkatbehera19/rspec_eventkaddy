class AddConfirmationTokenToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :confirmation_token, :string, unique: true, index: true
  end
end
