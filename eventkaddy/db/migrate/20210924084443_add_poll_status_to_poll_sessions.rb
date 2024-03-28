class AddPollStatusToPollSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :poll_sessions, :poll_status, :integer, null: false, default: 0
  end
end
