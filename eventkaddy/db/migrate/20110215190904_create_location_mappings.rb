class CreateLocationMappings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :location_mappings do |t|
      t.integer :event_id
      t.integer :map_id
      t.string :name
      t.integer :mapping_type
      t.integer :x
      t.integer :y

      t.timestamps
    end
  end

  def self.down
    drop_table :location_mappings
  end
end
