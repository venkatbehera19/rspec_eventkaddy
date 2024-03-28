class CartItem < ApplicationRecord
	belongs_to :cart
	belongs_to :item, polymorphic: true

	has_many   :discount_allocations, dependent: :nullify
end
