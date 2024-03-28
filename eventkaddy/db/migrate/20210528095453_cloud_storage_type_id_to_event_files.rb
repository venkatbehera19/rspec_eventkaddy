class CloudStorageTypeIdToEventFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :event_files, :cloud_storage_type_id, :integer
  end
end
