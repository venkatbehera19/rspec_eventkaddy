class AttendeeType < ApplicationRecord
  # attr_accessible :id, :name
  
  has_many :attendees
end
