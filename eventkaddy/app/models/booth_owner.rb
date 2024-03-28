class BoothOwner < ApplicationRecord
  # attr_accessible :attendee_id, :exhibitor_id
  
  belongs_to :exhibitor
  belongs_to :attendee
end
