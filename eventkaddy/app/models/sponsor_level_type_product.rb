class SponsorLevelTypeProduct < ApplicationRecord
	belongs_to :product
	belongs_to :sponsor_level_type
end