class SponsorSpecification < ApplicationRecord
	belongs_to :exhibitor
	belongs_to :sponsor_level_type
	
end
