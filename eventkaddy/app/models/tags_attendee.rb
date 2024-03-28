class TagsAttendee < ApplicationRecord

  belongs_to :attendee
  belongs_to :tag

end