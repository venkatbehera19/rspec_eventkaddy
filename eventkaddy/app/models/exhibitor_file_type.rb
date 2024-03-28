class ExhibitorFileType < ApplicationRecord
  # attr_accessible :id, :name
  has_many :exhibitor_files
end
