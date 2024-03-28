class AddAttendeeSettingsToAttendees < ActiveRecord::Migration[6.1]
  def change
    add_column :attendees, :attendee_settings, :json
  end
end
