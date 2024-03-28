class SessionAvRequirement < ApplicationRecord

  belongs_to :session
  belongs_to :av_list_item # like types. Not user created
  belongs_to :event
  belongs_to :speaker
  
end
