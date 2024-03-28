class Reminder < ApplicationRecord
	belongs_to :entity, polymorphic: true
end