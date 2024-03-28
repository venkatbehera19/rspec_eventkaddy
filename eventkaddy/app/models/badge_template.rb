class BadgeTemplate < ApplicationRecord
	belongs_to :event
	serialize :json, JSON
	validates :name, presence: true
end
