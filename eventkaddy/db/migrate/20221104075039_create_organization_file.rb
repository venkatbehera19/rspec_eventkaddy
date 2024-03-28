class CreateOrganizationFile < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_files do |t|
      t.string  :name
      t.integer :size
      t.string  :mime_type
      t.string  :path
      t.boolean :deleted
      t.integer :event_file_type_id
      t.integer :cloud_storage_type_id

      t.references :organization
      t.timestamps
    end
  end
end