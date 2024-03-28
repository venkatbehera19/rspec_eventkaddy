class AddCredentialsToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :username, :string, :null => false, :default => "", :unique => true
    add_column :attendees, :password, :string, :null => false, :default => ""
  end
end