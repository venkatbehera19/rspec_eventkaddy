class AddScavengerHuntItemTypeIdToScavengerHuntItems < ActiveRecord::Migration[4.2]
  def change
    add_column :scavenger_hunt_items, :scavenger_hunt_item_type_id, :integer
  end
end
