class UsersEvent < ApplicationRecord

	belongs_to :user
	belongs_to :event
	has_many   :user_event_roles, :dependent => :destroy
	has_many   :roles , through: :user_event_roles
end
