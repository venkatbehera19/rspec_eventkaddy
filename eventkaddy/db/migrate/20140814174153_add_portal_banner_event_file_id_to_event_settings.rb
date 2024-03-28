class AddPortalBannerEventFileIdToEventSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :event_settings, :portal_banner_event_file_id, :integer, after: :portal_logo_event_file_id
  end
end
