class OrderItem < ApplicationRecord
	belongs_to :order
	belongs_to :item, polymorphic: true
	belongs_to :coupon, optional: true
	has_many   :discount_allocations, dependent: :nullify

	def check_coupon_already_applied(coupon)
		self.coupon_id == coupon.id
	end

	def already_apply_by_user_or_registration_form(coupon)
		if self.order.user_id?
			code_usages = CouponCodeUsage.where(
				coupon_id: coupon.id,
				user_id: self.order.user_id
			)
			if code_usages.present?
				return true
			end
		elsif self.order.registration_form_id?
			code_usages = CouponCodeUsage.where(
				coupon_id: coupon.id,
				registration_form_id: self.order.registration_form_id
			)
			if code_usages.present?
				return true
			end
		end
		return false
	end
end
