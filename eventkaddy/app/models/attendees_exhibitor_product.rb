class AttendeesExhibitorProduct < ApplicationRecord
  # attr_accessible :event_id, :attendee_id, :exhibitor_product_id
  
  belongs_to :attendee
  belongs_to :exhibitor_product

end
