class TagsSession < ApplicationRecord

  belongs_to :session
  belongs_to :tag
  
end
