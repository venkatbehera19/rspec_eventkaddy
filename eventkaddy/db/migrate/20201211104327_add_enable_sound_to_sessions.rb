class AddEnableSoundToSessions < ActiveRecord::Migration[4.2]
  # This is for controlling sounds on moderation portal only.
  def change
    add_column :sessions, :enable_notification_sound, :boolean, :default => true
  end
end
