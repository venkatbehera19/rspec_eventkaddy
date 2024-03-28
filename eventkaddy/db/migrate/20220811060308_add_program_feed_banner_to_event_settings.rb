class AddProgramFeedBannerToEventSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :event_settings, :program_feed_banner_event_file_id, :integer
  end
end
