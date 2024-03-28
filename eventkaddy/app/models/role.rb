class Role < ApplicationRecord
	has_many :users_roles
	# has_many :users, :through => :users_roles

	has_and_belongs_to_many :users, :join_table => :users_roles
	has_many :user_event_roles
	has_many :user_events , through: :user_event_roles
end
