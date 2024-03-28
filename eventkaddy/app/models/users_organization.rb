class UsersOrganization < ApplicationRecord

	belongs_to :user
	belongs_to :organization, :foreign_key => 'org_id'
	
end
