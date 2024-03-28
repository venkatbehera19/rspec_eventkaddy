class AddRegistrationStatusToAttendee < ActiveRecord::Migration[6.1]
  def change
    add_column :attendees, :registration_status, :boolean
  end
end
