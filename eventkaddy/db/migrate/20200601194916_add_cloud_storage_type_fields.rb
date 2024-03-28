class AddCloudStorageTypeFields < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :cloud_storage_type_id, :integer
    add_column :events, :cloud_storage_type_id, :integer
  end
end
