class AddUniqueIndexToPollSessions < ActiveRecord::Migration[6.1]
  def change
    add_index :poll_sessions, [:poll_id, :session_id], unique: true
  end
end
