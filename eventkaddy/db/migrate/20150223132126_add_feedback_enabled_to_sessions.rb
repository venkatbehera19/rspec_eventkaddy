class AddFeedbackEnabledToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :feedback_enabled, :boolean
  end
end
