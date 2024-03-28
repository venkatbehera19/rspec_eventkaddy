class DomainType < ApplicationRecord
  # attr_accessible :name
  has_many :domains
end
