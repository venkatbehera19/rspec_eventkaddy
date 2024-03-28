class Comment < ApplicationRecord
  # attr_accessible :content, :session_id, :title

  belongs_to :session
  belongs_to :attendee
  
end
