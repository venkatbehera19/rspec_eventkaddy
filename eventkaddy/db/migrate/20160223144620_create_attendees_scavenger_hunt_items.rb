class CreateAttendeesScavengerHuntItems < ActiveRecord::Migration[4.2]
  def change
    create_table :attendees_scavenger_hunt_items do |t|
      t.integer :scavenger_hunt_item_id
      t.integer :attendee_id

      t.timestamps
    end
    add_index :attendees_scavenger_hunt_items, :scavenger_hunt_item_id
    add_index :attendees_scavenger_hunt_items, :attendee_id
  end
end
