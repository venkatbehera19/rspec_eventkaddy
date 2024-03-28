class ScavengerHunt < ApplicationRecord
  has_many :scavenger_hunt_items

  def self.detailed_scavenger_hunt_info id
    scavenger_hunt = find id
    {
      id:               id,
      title:            scavenger_hunt.title,
      maximum_attempts: scavenger_hunt.maximum_attempts,
      description:      scavenger_hunt.description,
      edit_url:         "/scavenger_hunts/#{id}/edit",
      new_item_url:     "/scavenger_hunt_items/new?scanvenger_hunt_id=#{id}",
      items:            scavenger_hunt.scavenger_hunt_items
    }
  end
end
