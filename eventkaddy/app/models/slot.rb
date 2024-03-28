class Slot < ApplicationRecord
  attr_accessor :slot_day, :slot_duration
  enum options_for_durations: { "15 mins": 15, "30 mins": 30,"60 mins": 60, }
  belongs_to :event, :foreign_key => 'event_id'
  belongs_to :exhibitor_staff, :foreign_key => 'exhibitor_staff_id'
  belongs_to :attendee, :foreign_key => 'attendee_id', :optional => true
end
