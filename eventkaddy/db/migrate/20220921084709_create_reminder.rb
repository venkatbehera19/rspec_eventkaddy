class CreateReminder < ActiveRecord::Migration[6.1]
  def change
    create_table :reminders do |t|
      t.string :notification_type
      t.integer :snooze_duration
      t.datetime :snooze_created_at
      t.boolean :is_active
      t.integer :entity_id
      t.string :entity_type
      t.references :attendee

      t.timestamps
    end
  end
end
