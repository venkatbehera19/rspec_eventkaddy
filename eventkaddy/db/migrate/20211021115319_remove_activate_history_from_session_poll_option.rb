class RemoveActivateHistoryFromSessionPollOption < ActiveRecord::Migration[6.1]
  def change
    remove_column :session_poll_options, :activate_history
  end
end
