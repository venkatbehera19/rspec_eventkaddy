class AddBannersToEventSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :event_settings, :exhibitor_banner_event_file_id, :integer
    add_column :event_settings, :speaker_banner_event_file_id, :integer
    add_column :event_settings, :registration_banner_event_file_id, :integer
  end
end
