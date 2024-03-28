class AttendeeGpsDataPointType < ApplicationRecord
  # attr_accessible :id, :name
  
  has_many :attendee_gps_data_points
end
