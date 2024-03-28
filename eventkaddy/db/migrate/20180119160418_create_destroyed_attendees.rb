class CreateDestroyedAttendees < ActiveRecord::Migration[4.2]
  def change
    create_table :destroyed_attendees do |t|
      t.integer :event_id
      t.integer :attendee_id
      t.integer :account_code

      t.timestamps
    end
  end
end
