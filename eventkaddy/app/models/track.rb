class Track < ApplicationRecord
	include ActiveModel::ForbiddenAttributesProtection
	has_many :subtracks, :dependent => :nullify
	
end
