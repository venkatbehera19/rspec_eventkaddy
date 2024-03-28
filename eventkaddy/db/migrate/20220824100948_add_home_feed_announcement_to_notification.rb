class AddHomeFeedAnnouncementToNotification < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications, :on_home_feed_announcement, :boolean, :default => false
  end
end
