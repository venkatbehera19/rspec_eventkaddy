class TagsExhibitor < ApplicationRecord
  
  belongs_to :exhibitor
  belongs_to :tag
  
end
