class AddIndexToSessions < ActiveRecord::Migration[4.2]
  def change
    add_index :sessions, :session_code
  end
end
