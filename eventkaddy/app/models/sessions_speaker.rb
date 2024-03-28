class SessionsSpeaker < ApplicationRecord
	belongs_to :speaker_type
	belongs_to :session
	belongs_to :speaker
	
  def published?
    !unpublished
  end

end
