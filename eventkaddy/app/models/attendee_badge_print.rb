class AttendeeBadgePrint < ApplicationRecord
	belongs_to :attendee
	belongs_to :badge_template
end