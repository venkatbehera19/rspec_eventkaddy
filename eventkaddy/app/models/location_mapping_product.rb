class LocationMappingProduct < ApplicationRecord
	belongs_to :product
	belongs_to :location_mapping
end