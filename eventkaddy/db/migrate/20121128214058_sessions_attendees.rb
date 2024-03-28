class SessionsAttendees < ActiveRecord::Migration[4.2]
  def self.up
    create_table :sessions_attendees do |t|
      t.integer :attendee_id
      t.string :session_id
			t.string :flag
	  
      t.timestamps
    end
  end

  def self.down
    drop_table :sessions_attendees
  end
end
