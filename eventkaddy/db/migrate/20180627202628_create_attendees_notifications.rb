class CreateAttendeesNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :attendees_notifications do |t|
      t.integer :event_id
      t.text :attendee_codes
      t.integer :notification_id
      t.string :status

      t.timestamps
    end
  end
end
