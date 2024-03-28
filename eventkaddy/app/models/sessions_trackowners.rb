class SessionsTrackowners < ApplicationRecord

	belongs_to :session
	belongs_to :track_owner

end
