class AddExhibitorRegistrationBannerEventFileIdToEventSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :event_settings, :exhibitor_registration_banner_event_file_id, :integer
  end
end
