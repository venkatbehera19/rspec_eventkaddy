require 'securerandom'
class Coupon < ApplicationRecord

	before_create :set_remaining_usage
	
	has_many    :order_items
	has_many    :coupon_code_usages
	has_many    :users, through: :coupon_code_usages
	has_many    :registration_forms, through: :coupon_code_usages
	belongs_to  :product
	belongs_to  :exhibitor, optional: true
	
	# validations
	validates :coupon_name, 		presence: true
	validates :amount,      		presence: true
	validates :start_date,  		presence: true
	validates :end_date,    		presence: true
	validates :max_usage,   		presence: true
	validates :event_id,        presence: true
	validates :discount_type,   inclusion: { in: ['percentage', 'fixed_amount'] }
	validate  :coupon_must_be_unique 

	def is_percentage?
		self.discount_type == "percentage"
	end

	def is_useable?
		if remaining_usage > 0
			return true
		end
		return false
	end

	def check_expiration?
		current_utc_time = Time.now.utc
		if current_utc_time >= start_date && current_utc_time <= end_date
			return false
		end
		return true
	end

	def decrement_remaining_usage
		return unless remaining_usage.positive?
		decrement!(:remaining_usage)
	end

	private

	def coupon_must_be_unique
		if Coupon.where(coupon_code: coupon_code).where.not(id: id).exists?
      errors.add(:coupon_code, "can not be duplicated.")
    end
	end

	def set_remaining_usage
		self.remaining_usage = self.max_usage
	end

end
