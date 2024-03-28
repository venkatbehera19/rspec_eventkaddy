class CreateScavengerHuntItemTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :scavenger_hunt_item_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
