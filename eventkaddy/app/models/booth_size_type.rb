class BoothSizeType < ApplicationRecord
  # attr_accessible :id, :name
  
  has_many :location_mappings

end
