class CreateFileAssets < ActiveRecord::Migration[6.1]
  def change
    create_table :file_assets do |t|
      t.string :name
      t.integer :size
      t.string :mime_type
      t.string :path
      t.references :cloud_storage_type, null: false
      t.references :blob, polymorphic: true, null: false

      t.timestamps
    end
  end
end
