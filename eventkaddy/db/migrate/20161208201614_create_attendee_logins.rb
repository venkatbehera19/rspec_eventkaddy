class CreateAttendeeLogins < ActiveRecord::Migration[4.2]
  def change
    create_table :attendee_logins do |t|
      t.integer :event_id
      t.integer :attendee_id

      t.timestamps
    end
    add_index :attendee_logins, :attendee_id
  end
end
