class AddActivateHistoryToPollSession < ActiveRecord::Migration[6.1]
  def change
    add_column :poll_sessions, :activate_history, :integer, default: 0
  end
end
