class HiddenEvent < ApplicationRecord
  # attr_accessible :event_id, :user_id

  belongs_to :event
end
