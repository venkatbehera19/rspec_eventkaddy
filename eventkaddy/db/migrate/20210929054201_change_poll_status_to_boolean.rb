class ChangePollStatusToBoolean < ActiveRecord::Migration[6.1]
  def change
    change_column :poll_sessions, :poll_status, :boolean, default: false
  end
end
