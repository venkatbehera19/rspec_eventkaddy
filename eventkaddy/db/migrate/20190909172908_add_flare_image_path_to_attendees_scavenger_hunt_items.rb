class AddFlareImagePathToAttendeesScavengerHuntItems < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees_scavenger_hunt_items, :flare_image_path, :string, after: :attendee_id
  end
end
