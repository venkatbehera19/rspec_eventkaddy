class AddPushNotificationToNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications, :push_notification, :boolean
  end
end
