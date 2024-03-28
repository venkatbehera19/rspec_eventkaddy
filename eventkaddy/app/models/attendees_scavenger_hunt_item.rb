class AttendeesScavengerHuntItem < ApplicationRecord
  # attr_accessible :attendee_id, :scavenger_hunt_item_id
  
  belongs_to :attendee
  belongs_to :scavenger_hunt_item
end
