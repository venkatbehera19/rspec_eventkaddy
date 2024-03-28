class LocationMapping < ApplicationRecord

	belongs_to :location_mapping_type, :foreign_key => "mapping_type"
	belongs_to :booth_size_type, optional: true
	belongs_to :event_map, :foreign_key => "map_id", :optional => true
	has_many :sessions, :dependent => :nullify
	has_many :exhibitors, :dependent => :nullify
	has_many :room_layouts
	has_many :attendee_scans
	has_many :location_mapping_products
	has_many :products, :through => :location_mapping_products

	def location_mapping_type_name
    return '' if self.mapping_type.blank?
		return LocationMappingType.find(self.mapping_type).type_name
	end

	def with_product
		"#{ self.name } with #{ self.products.first.name } at $#{self.products.first.price}"
	end

	def is_available?
		self.locked_by.nil? && self.locked_at.nil? && self.product_id.nil?
	end

end
