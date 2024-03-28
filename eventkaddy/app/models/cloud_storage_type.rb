class CloudStorageType < ApplicationRecord
  # attr_accessible :name, :provider, :region, :bucket, :link_expiration_duration
  
  has_many :events
  #needed for vmworld
  has_many :sessions
end
