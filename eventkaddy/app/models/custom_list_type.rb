class CustomListType < ApplicationRecord
  # attr_accessible :id, :name, :user_made

  has_many :custom_lists

end
