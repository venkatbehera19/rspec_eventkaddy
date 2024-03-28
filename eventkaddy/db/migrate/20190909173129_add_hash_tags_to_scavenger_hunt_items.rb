class AddHashTagsToScavengerHuntItems < ActiveRecord::Migration[4.2]
  def change
    add_column :scavenger_hunt_items, :hash_tags, :string, after: :answer
  end
end
