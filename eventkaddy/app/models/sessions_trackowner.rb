class SessionsTrackowner < ApplicationRecord

	belongs_to :session
	belongs_to :trackowner

end
