class SessionsSponsor < ApplicationRecord
  belongs_to :session
  belongs_to :exhibitor, :foreign_key => 'sponsor_id'

end
