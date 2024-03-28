class AddIndexToPollSessions < ActiveRecord::Migration[6.1]
  def change
    add_index :poll_sessions, :session_id
  end
end
