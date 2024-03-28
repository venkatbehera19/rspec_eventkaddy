class CreateScavengerHuntItems < ActiveRecord::Migration[4.2]
  def change
    create_table :scavenger_hunt_items do |t|
      t.integer :event_id
      t.integer :scavenger_hunt_id
      t.integer :event_file_id
      t.integer :exhibitor_id
      t.string :name
      t.string :description
      t.string :answer

      t.timestamps
    end
    add_index :scavenger_hunt_items, :event_id
    add_index :scavenger_hunt_items, :scavenger_hunt_id
  end
end
