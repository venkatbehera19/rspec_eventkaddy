class AttendeeProduct < ApplicationRecord
	belongs_to :attendee
	belongs_to :product
	has_many   :transactions
end