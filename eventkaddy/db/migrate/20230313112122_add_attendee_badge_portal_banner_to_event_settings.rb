class AddAttendeeBadgePortalBannerToEventSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :event_settings, :attendee_badge_portal_banner_event_file_id, :integer
  end
end
