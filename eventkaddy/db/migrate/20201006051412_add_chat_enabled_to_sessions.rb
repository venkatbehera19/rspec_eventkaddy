class AddChatEnabledToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :chat_enabled, :boolean, :default => false
  end
end
