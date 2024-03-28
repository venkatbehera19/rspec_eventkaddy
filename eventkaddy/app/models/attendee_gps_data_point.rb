class AttendeeGpsDataPoint < ApplicationRecord
    # attr_accessible :attendee_gps_data_point_type_id, :attendee_id, :event_id, :latitude, :longitude, :elevation, :description

  belongs_to :attendee_gps_data_point_type
end
