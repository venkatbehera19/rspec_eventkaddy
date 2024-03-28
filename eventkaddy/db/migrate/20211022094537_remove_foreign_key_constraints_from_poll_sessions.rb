class RemoveForeignKeyConstraintsFromPollSessions < ActiveRecord::Migration[6.1]
  def change
    remove_index :poll_sessions, name: "index_poll_sessions_on_poll_id"
    remove_index :poll_sessions, name: "index_poll_sessions_on_poll_id_and_session_id"
    remove_index :poll_sessions, name: "index_poll_sessions_on_session_id"
  end
end
