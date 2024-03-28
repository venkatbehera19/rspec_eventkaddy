class Sponsor < ApplicationRecord

  has_many :session_sponsors, :dependent => :destroy
  has_many :sessions, :through => :session_sponsors

end
