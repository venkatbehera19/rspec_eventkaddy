class CouponCodeUsage < ApplicationRecord
  belongs_to :coupon
  belongs_to :user             , optional: true
  belongs_to :registration_form, optional: true

  validate :either_user_or_registration_form_present

  def either_user_or_registration_form_present
    unless user.present? || registration_form.present?
      errors.add(:base, "Either attendee or registration_form must be present")
    end
  end
  
end
