class AddQaEnabledToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :qa_enabled, :boolean
  end
end
