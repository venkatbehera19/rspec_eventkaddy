class AddSessionCodesToNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :session_codes, :text
  end
end
