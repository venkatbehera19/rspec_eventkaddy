class AddDeviceToAttendeeLogins < ActiveRecord::Migration[4.2]
  def change
    add_column :attendee_logins, :device, :string, :after => :attendee_id
  end
end
