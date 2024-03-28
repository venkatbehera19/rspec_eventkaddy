class AddHiddenNotificationTypeIdToNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :hidden_notification_type_id, :integer
  end
end
