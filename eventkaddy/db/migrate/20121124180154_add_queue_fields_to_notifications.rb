class AddQueueFieldsToNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :active_time, :datetime
    add_column :notifications, :status, :string
  end
end
