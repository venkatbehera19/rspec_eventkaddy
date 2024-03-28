class ExhibitorAttendee < ApplicationRecord
  # attr_accessible :attendee_id, :company_name, :exhibitor_id, :flag

  belongs_to :attendee
  belongs_to :exhibitor
end
