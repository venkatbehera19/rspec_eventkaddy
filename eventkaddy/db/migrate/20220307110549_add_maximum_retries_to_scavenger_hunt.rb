class AddMaximumRetriesToScavengerHunt < ActiveRecord::Migration[6.1]
  def change
    add_column :scavenger_hunts,:maximum_attempts, :integer, default: 0
    add_column :scavenger_hunt_items,:maximum_attempts, :integer
    add_column :attendees_scavenger_hunt_items,:remaining_attempts, :integer, default: nil
    add_column :attendees_scavenger_hunt_items,:answered_correctly, :boolean, default: false
  end
end
