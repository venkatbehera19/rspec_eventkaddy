class Organization < ApplicationRecord

	has_many :events, :foreign_key => 'org_id', :dependent => :restrict_with_error
	has_many :users_organizations, :foreign_key => 'org_id', :dependent => :restrict_with_error
	has_many :users, :through => :users_organizations
	has_many :members

	def self.options_for_select_orgs user_orgs
		order('updated_at DESC')
                      .all
                      .map    { |org| [org.name, org.id] }
                      .reject { |org| user_orgs.include? org }
	end

	def self.organization_options 
		data = []
		order('updated_at DESC')
			.all
			.each do |organization|
				organization_data = {}
				organization_data["name"] = organization.name
				organization_data["id"]   = organization.id
				data << organization_data
			end
		data.to_json
	end

end
