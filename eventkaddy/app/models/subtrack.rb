class Subtrack < ApplicationRecord

	has_many :sessions_subtracks, :dependent => :destroy
	belongs_to :track
	
end
