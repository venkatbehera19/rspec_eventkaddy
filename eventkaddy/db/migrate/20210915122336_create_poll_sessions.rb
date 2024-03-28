class CreatePollSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :poll_sessions do |t|
      t.integer :event_id
      t.integer :poll_id
      t.integer :session_id

      t.timestamps
    end
    add_index :poll_sessions, :poll_id
    add_index :poll_sessions, :session_id
  end
end
