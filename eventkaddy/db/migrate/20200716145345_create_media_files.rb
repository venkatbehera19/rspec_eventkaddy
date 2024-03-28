class CreateMediaFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :media_files do |t|
      t.integer :event_id
      t.string  :name
      t.string  :path 
      t.boolean :published
      t.integer :event_file_id
      t.integer :cloud_storage_type_id
      t.integer :exhibitor_id
      t.integer :session_id
      t.timestamps
    end
  end
end
