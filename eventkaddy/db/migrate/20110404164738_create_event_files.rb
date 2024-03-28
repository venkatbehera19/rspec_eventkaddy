class CreateEventFiles < ActiveRecord::Migration[4.2]
  def self.up
    create_table :event_files do |t|
      t.integer :event_id
      t.string :name
      t.integer :size
      t.string :mime_type
      t.string :path
      t.integer :event_file_type_id

      t.timestamps
    end
  end

  def self.down
    drop_table :event_files
  end
end
