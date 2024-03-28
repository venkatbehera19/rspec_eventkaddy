class CreateAttendeesReadNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :attendees_read_notifications do |t|
      t.integer :attendee_id
      t.integer :notification_id

      t.timestamps
    end
  end
end
