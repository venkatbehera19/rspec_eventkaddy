class AddExhibitorFilesToEventSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :event_settings, :exhibitor_files, :boolean
  end
end
