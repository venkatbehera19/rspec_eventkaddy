class RegistrationFormCartItem < ApplicationRecord
  belongs_to :registration_form_cart
  belongs_to :item, polymorphic: true
end