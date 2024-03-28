class ChangeReport < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :event
  belongs_to :event_file
end
