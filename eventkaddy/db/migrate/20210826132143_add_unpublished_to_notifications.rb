class AddUnpublishedToNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications, :unpublished, :boolean unless column_exists?(:notifications, :unpublished)
  end
end
