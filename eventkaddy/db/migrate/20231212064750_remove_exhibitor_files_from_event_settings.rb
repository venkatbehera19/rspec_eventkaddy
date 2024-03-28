class RemoveExhibitorFilesFromEventSettings < ActiveRecord::Migration[6.1]
  def change
    remove_column :event_settings, :exhibitor_files, :boolean
  end
end
