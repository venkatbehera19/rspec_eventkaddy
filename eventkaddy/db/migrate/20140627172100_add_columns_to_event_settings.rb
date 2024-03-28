class AddColumnsToEventSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :event_settings, :speaker_files, :boolean
    add_column :event_settings, :av_requests, :boolean
  end
end
