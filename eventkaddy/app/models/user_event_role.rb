class UserEventRole < ApplicationRecord
  belongs_to :users_event
  belongs_to :role
end