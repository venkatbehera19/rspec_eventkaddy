class Transaction < ApplicationRecord
	belongs_to :attendee, :optional => true
	belongs_to :product, :optional => true
	belongs_to :mode_of_payment
	belongs_to :transaction_status_type
	belongs_to :cart, :optional => true
	belongs_to :registration_form_cart, :optional => true 

	def self.payment_available? setting
		setting.have_payment_page && setting.payment_gateway
	end
end