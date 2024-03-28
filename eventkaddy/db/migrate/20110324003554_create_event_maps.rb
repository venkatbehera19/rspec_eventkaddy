class CreateEventMaps < ActiveRecord::Migration[4.2]
  def self.up
    create_table :event_maps do |t|
      t.integer :event_id
      t.integer :map_event_file_id
      t.string :name
      t.string :filename
      t.integer :width
      t.integer :height
      t.integer :map_type_id

      t.timestamps
    end
  end

  def self.down
    drop_table :event_maps
  end
end
