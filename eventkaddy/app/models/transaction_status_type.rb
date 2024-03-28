class TransactionStatusType < ApplicationRecord
	scope :pending, ->{ find_by(iid: 'pending') }
	scope :failed, ->{ find_by(iid: 'failed') }
	scope :success, ->{ find_by(iid: 'success') }

	def success?
		self.iid == 'success'
	end
end