class SponsorLevelType < ApplicationRecord

	has_many :sponsor_specifications
	has_many :exhibitors
	has_many :event_sponsor_level_types
	has_one :medal_image, as: :blob, class_name: 'FileAsset'
	has_many :sponsor_level_type_products
	has_many :products, :through => :sponsor_level_type_products
	def has_associated_exhibitors?(event_id)
		exhibitors.where(event_id: event_id).size > 0
	end
end
