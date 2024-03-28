class ModeOfPayment < ApplicationRecord
	belongs_to :event
	attr_accessor :client_key, :client_secret_key
	serialize :key

	def client_key
		return '' if self.key.blank?

		crypt = ActiveSupport::MessageEncryptor.new(self.key)
		cred = crypt.decrypt_and_verify(self.credentials)
		client_key = JSON.parse(cred)["client_key"]
	end

	def client_secret_key
		return '' if self.key.blank?

		crypt = ActiveSupport::MessageEncryptor.new(self.key)
		cred = crypt.decrypt_and_verify(self.credentials)
		client_secret_key = JSON.parse(cred)["client_secret_key"]
	end

	def self.is_paypal?(id)
		mode = ModeOfPayment.find_by(id: id)

		return false if mode.blank?
		mode.name == "PayPal"
	end

	def can_make_payment?
		check = self.client_key.present? && self.client_secret_key.present?
		check && self.environment.present? if self.name == 'PayPal'
		check
	end
end